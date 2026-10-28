"""Scan APK/IPA ZIP entries without extracting paths or printing credentials."""

import sys
import zipfile
from pathlib import Path

from secret_checks import secret_labels


def scan_artifact(path):
    findings = []
    with zipfile.ZipFile(path) as archive:
        for entry in archive.infolist():
            if entry.is_dir():
                continue
            labels = set()
            with archive.open(entry) as stream:
                overlap = b""
                while chunk := stream.read(1024 * 1024):
                    data = overlap + chunk
                    labels.update(secret_labels(data))
                    overlap = data[-65536:]
            findings.extend((entry.filename, label) for label in sorted(labels))
    return findings


def main():
    if len(sys.argv) != 2:
        print("Usage: scan_build_for_secrets.py <apk-or-ipa>", file=sys.stderr)
        return 2
    path = Path(sys.argv[1])
    if path.suffix.lower() not in {".apk", ".ipa"} or not path.is_file():
        print("Expected an existing APK or IPA.", file=sys.stderr)
        return 2
    try:
        findings = scan_artifact(path)
    except (OSError, ValueError, zipfile.BadZipFile, RuntimeError):
        print("Unable to read build archive; scan failed closed.", file=sys.stderr)
        return 2
    for name, label in findings:
        print(f"Forbidden {label} in {name!r}", file=sys.stderr)
    print("Build secret scan failed." if findings else "Build secret scan passed.")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
