# Specification Quality Checklist: Guest Sign-in with Google / Apple + Mandatory Phone Confirmed on WhatsApp (S005)

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-11-13 (re-validated after the WhatsApp update)
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic (no implementation details)
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification

## Notes

- Pass 1 (2026-11-13, email-code version): all items passed.
- Pass 2 (2026-11-13, WhatsApp update): all items pass. Eight stories (Google, Apple, «أكّد رقمك»,
  WhatsApp code, resend ladder + block, email registration + phone change, one account, account
  screen) and 47 functional requirements.
- Named services are kept where they are the product decision itself, not a design choice: Meta's
  official WhatsApp Business service (owner's explicit requirement), Google/Apple sign-in, and the
  native sign-in sheet instead of an embedded web page (security rule). Mechanisms such as app
  attestation, keychain and device identifiers appear only in Assumptions.
- Ladder, limit and block values come straight from the owner (30 s → 5 min → 1 h → 24 h, then 1 h /
  24 h alternating; 10 sends; 7-day block). Code validity (10 min) and attempts (5) reuse the
  platform's current OTP settings.
- Remaining defaults are recorded in Assumptions and Guest Plan §19 (items 10, 11, 13, 14, 15);
  `/speckit-clarify` can revisit them.
- Constitution amended to v2.1.0 (2026-11-13) per D-002; the earlier "social login" blocker is
  resolved.
