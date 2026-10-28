import base64
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BINARY = os.environ.get("GITLEAKS_BINARY") or shutil.which("gitleaks")
if not BINARY and (ROOT / ".tools/gitleaks.exe").is_file():
    BINARY = str(ROOT / ".tools/gitleaks.exe")


@unittest.skipUnless(BINARY, "GITLEAKS_BINARY is set by the secret-scan CI job")
class GitleaksTest(unittest.TestCase):
    def test_real_cli_detects_every_alignment_and_provider_symbol(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            for count in range(6):
                payload = json.dumps({"pad": "a" * count, "role": "service" + "_role"}, separators=(",", ":"))
                encoded = base64.urlsafe_b64encode(payload.encode()).decode().rstrip("=")
                (path / f"jwt-{count}.txt").write_text("eyJhbGciOiJIUzI1NiJ9." + encoded + ".signature")
            (path / "backend.txt").write_text("sb_" + "secret_" + "a" * 32)
            for name in ("kashier_api_key", "twilio_auth_token"):
                (path / f"{name}.txt").write_text(name + "=" + "+/.=" * 8)
            report = path / "report.json"
            result = subprocess.run([BINARY, "detect", "--no-git", "--source", directory, "--config", str(ROOT / ".gitleaks.toml"), "--report-format", "json", "--report-path", str(report), "--redact"], capture_output=True)
            self.assertEqual(result.returncode, 1, "gitleaks must find synthetic credentials")
            findings = json.loads(report.read_text())
            files = {Path(item["File"]).name for item in findings}
            self.assertTrue({f"jwt-{n}.txt" for n in range(6)}.issubset(files))
            self.assertTrue({"backend.txt", "kashier_api_key.txt", "twilio_auth_token.txt"}.issubset(files))


if __name__ == "__main__":
    unittest.main()
