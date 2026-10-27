import base64
import json
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

TOOL = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOL))

from scan_build_for_secrets import scan_artifact
from secret_checks import secret_labels
from validate_staging_env import validate


def token(role, prefix="", escaped=False):
    def encoded(value):
        return base64.urlsafe_b64encode(value.encode()).decode().rstrip("=")
    payload = json.dumps({"pad": prefix, "role": role})
    if escaped:
        payload = payload.replace("_", "\\u005f")
    return encoded('{"alg":"HS256"}') + "." + encoded(payload) + "." + encoded("test-signature")


def valid_env():
    return {
        "FLAVOR": "staging",
        "SUPABASE_URL": "https://test-project.supabase.co",
        "SUPABASE_ANON_KEY": "sb_" + "publishable_" + "p" * 32,
        "NODE_API_BASE_URL": "https://api.on-air.website",
        "LINK_DOMAIN": "on-air.website",
    }


class SecretChecksTest(unittest.TestCase):
    def test_decodes_role_with_all_base64_alignments_and_json_escapes(self):
        for count in range(6):
            for escaped in (False, True):
                with self.subTest(count=count, escaped=escaped):
                    value = token("service" + "_role", "x" * count, escaped)
                    self.assertIn("privileged Supabase JWT", secret_labels(value.encode()))

    def test_known_short_payload_is_detected(self):
        value = "eyJhbGciOiJIUzI1NiJ9." + base64.urlsafe_b64encode(
            json.dumps({"role": "service" + "_role"}, separators=(",", ":")).encode()
        ).decode().rstrip("=") + ".test-signature"
        self.assertTrue(secret_labels(value.encode()))

    def test_provider_symbols_and_json_assignments(self):
        for name in ("KASHIER_API_KEY", "twilio_auth_token", "sms_key"):
            for symbol in "+/.=":
                value = json.dumps({name: symbol * 24}).encode()
                with self.subTest(name=name, symbol=symbol):
                    self.assertTrue(secret_labels(value))

    def test_backend_keys_utf16_and_safe_public_keys(self):
        private = "sb_" + "secret_" + "a" * 32
        self.assertTrue(secret_labels(private.encode()))
        self.assertTrue(secret_labels(private.encode("utf-16le")))
        self.assertFalse(secret_labels(token("anon").encode()))
        self.assertFalse(secret_labels(valid_env()["SUPABASE_ANON_KEY"].encode()))

    def test_archive_boundary_and_no_extraction(self):
        with tempfile.TemporaryDirectory() as directory:
            artifact = Path(directory) / "fixture.apk"
            value = token("service" + "_role").encode()
            with zipfile.ZipFile(artifact, "w") as archive:
                archive.writestr("../must-not-extract", b"\0" * (1024 * 1024 - 10) + value)
            self.assertTrue(scan_artifact(artifact))
            self.assertFalse((Path(directory).parent / "must-not-extract").exists())

    def test_cli_does_not_print_credentials_and_fails_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            artifact = Path(directory) / "fixture.apk"
            value = token("service" + "_role")
            with zipfile.ZipFile(artifact, "w") as archive:
                archive.writestr("lib/app.so", value)
            result = subprocess.run([sys.executable, str(TOOL / "scan_build_for_secrets.py"), str(artifact)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 1)
            self.assertNotIn(value, result.stdout + result.stderr)
            artifact.write_bytes(b"not a ZIP")
            result = subprocess.run([sys.executable, str(TOOL / "scan_build_for_secrets.py"), str(artifact)], capture_output=True)
            self.assertEqual(result.returncode, 2)


class EnvironmentTest(unittest.TestCase):
    def test_accepts_publishable_and_legacy_anon(self):
        validate(valid_env())
        values = valid_env()
        values["SUPABASE_ANON_KEY"] = token("anon")
        validate(values)

    def test_rejects_missing_keys_and_unknown_values(self):
        for key in valid_env():
            values = valid_env()
            del values[key]
            with self.subTest(key=key), self.assertRaises(ValueError):
                validate(values)
        for invalid in ({}, [], None, {**valid_env(), "SERVER_KEY": "unexpected"}):
            with self.assertRaises(ValueError):
                validate(invalid)

    def test_rejects_wrong_flavor_urls_keys_and_domains(self):
        cases = [
            ("FLAVOR", "production"), ("FLAVOR", ""),
            ("NODE_API_BASE_URL", "http://api.on-air.website"),
            ("SUPABASE_URL", "https://user:password@test.supabase.co"),
            ("SUPABASE_URL", "https://test.supabase.co?secret=hidden"),
            ("LINK_DOMAIN", "https://on-air.website"),
            ("LINK_DOMAIN", "on-air.website/path"),
            ("SUPABASE_ANON_KEY", token("service" + "_role")),
            ("SUPABASE_ANON_KEY", "sb_" + "secret_" + "a" * 32),
            ("SUPABASE_ANON_KEY", "invalid"),
        ]
        for key, value in cases:
            with self.subTest(key=key), self.assertRaises(ValueError):
                validate({**valid_env(), key: value})

    def test_cli_redacts_even_invalid_json(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "env.json"
            secret = "sb_" + "secret_" + "a" * 32
            path.write_text('{"broken": "' + secret, encoding="utf-8")
            result = subprocess.run([sys.executable, str(TOOL / "validate_staging_env.py"), str(path)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 1)
            self.assertNotIn(secret, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
