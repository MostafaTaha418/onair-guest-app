"""Validate CI configuration before creating a distributable mobile build."""

import json
import re
import sys
from pathlib import Path
from urllib.parse import urlsplit

from secret_checks import jwt_payload, secret_labels

REQUIRED_KEYS = {
    "FLAVOR", "SUPABASE_URL", "SUPABASE_ANON_KEY", "NODE_API_BASE_URL", "LINK_DOMAIN"
}


def validate(values):
    if not isinstance(values, dict) or set(values) != REQUIRED_KEYS:
        raise ValueError("Environment must contain exactly the five documented keys.")
    if any(not isinstance(v, str) or not v.strip() or v != v.strip() for v in values.values()):
        raise ValueError("Environment values must be nonempty trimmed strings.")
    if values["FLAVOR"] != "staging":
        raise ValueError("FLAVOR must be staging.")
    for name in ("SUPABASE_URL", "NODE_API_BASE_URL"):
        url = urlsplit(values[name])
        if (url.scheme != "https" or not url.hostname or url.username or url.password
                or url.query or url.fragment or any(c.isspace() for c in values[name])):
            raise ValueError(f"{name} must be an HTTPS endpoint without credentials, query or fragment.")
    domain = values["LINK_DOMAIN"]
    if not re.fullmatch(r"(?=.{1,253}$)(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,63}", domain):
        raise ValueError("LINK_DOMAIN must be a bare DNS hostname.")
    for value in values.values():
        if secret_labels(value.encode()):
            raise ValueError("A forbidden server credential was supplied in client configuration.")
    key = values["SUPABASE_ANON_KEY"]
    claims = jwt_payload(key)
    if not re.fullmatch(r"sb_publishable_[A-Za-z0-9_-]{12,}", key) and not (
        claims and claims.get("role") == "anon"
    ):
        raise ValueError("SUPABASE_ANON_KEY must be a publishable key or legacy anon JWT.")


def main():
    try:
        if len(sys.argv) != 2:
            raise ValueError("Usage: validate_staging_env.py <environment-json>")
        validate(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8-sig")))
    except (OSError, ValueError):
        print("Staging configuration rejected: check the documented keys, URLs and public key.", file=sys.stderr)
        return 1
    print("Staging environment validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
