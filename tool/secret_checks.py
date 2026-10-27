"""Shared client-secret checks. Never log matched credential values."""

import base64
import binascii
import json
import re


FORBIDDEN_ROLE = "service" + "_role"
JWT = re.compile(
    rb"(?<![A-Za-z0-9_-])eyJ[A-Za-z0-9_-]{0,1024}={0,2}\."
    rb"([A-Za-z0-9_-]{1,16384}={0,2})\.[A-Za-z0-9_-]+"
)
PATTERNS = {
    "privileged Supabase key": re.compile(
        (FORBIDDEN_ROLE + r"|sb_secret_[A-Za-z0-9_-]{12,}").encode(), re.I
    ),
    "Kashier credential": re.compile(
        rb"kashier[\s_-]{0,3}(?:api|secret|payment|merchant)?[\s_-]{0,3}"
        rb"(?:key|secret|token)[\s'\"]{0,3}[:=][\s'\"]{0,3}[A-Za-z0-9_+/.=-]{12,}",
        re.I,
    ),
    "Resend credential": re.compile(
        rb"(?:^|[^A-Za-z0-9])re_[A-Za-z0-9]{24,}(?:[^A-Za-z0-9]|$)"
    ),
    "SMS credential": re.compile(
        rb"(?:sms|twilio|messagebird)[\s_-]{0,3}(?:api|auth|account|secret)?"
        rb"[\s_-]{0,3}(?:sid|key|secret|token)[\s'\"]{0,3}[:=][\s'\"]{0,3}"
        rb"[A-Za-z0-9_+/.=-]{12,}",
        re.I,
    ),
}


def jwt_payload(token):
    """Decode claims for inspection only; this does not authenticate a JWT."""
    try:
        part = token.split(".")[1]
        value = json.loads(base64.urlsafe_b64decode(part + "=" * (-len(part) % 4)))
        return value if isinstance(value, dict) else None
    except (IndexError, ValueError, UnicodeDecodeError, binascii.Error):
        return None


def secret_labels(data):
    labels = set()
    # Dart/native libraries may store strings as ASCII or UTF-16 with NUL bytes.
    for candidate in (data, data.replace(b"\0", b"")):
        for label, pattern in PATTERNS.items():
            if pattern.search(candidate):
                labels.add(label)
        for match in JWT.finditer(candidate):
            claims = jwt_payload(match.group().decode("ascii"))
            if claims and claims.get("role") == FORBIDDEN_ROLE:
                labels.add("privileged Supabase JWT")
    return labels
