# HCMS — PRD v4.0 vs Codebase Gap Analysis

**Date:** 2026-08-26 · **PRD:** HCMS_PRD_v4.0.md (22 Jun 2026) · **Code reviewed at commit:** `73c1404`

Legend: ✅ done · 🟡 partial / buggy · ❌ missing · ⛔ out of scope for now (see notes)

---

## Module-by-module status

| # | PRD Module | Status | Gap detail |
|---|-----------|--------|------------|
| 1 | Receptionist Dashboard (§5.1) | 🟡 | KPI cards exist & mostly neutral-styled ✅; clinic selector exists ✅; but Low-Stock KPI hardcoded (`crud.py:339`), fake "Synced 2s ago" footer, fabricated fallbacks on API failure |
| 2 | Patient Management (§5.2) | 🟡 | Registration/search work ✅; **no View Profile / Edit actions** (PRD §5.2.2 requires both); no Last Visit column; no visit history/prescription/invoice ledger view in profile (§5.2.3) |
| 3 | Appointment Management (§5.3) | 🟡 | Book/confirm/reschedule/cancel exist ✅; audit trail of reschedule ✅; **status machine broken** ('Waiting' not a PRD status, 'No Show' vs 'No-Show'); calendar view is fake; cancel has no reason capture |
| 4 | Queue Management (§5.4) | 🟡 | Board + Single Active Consultation rule work ✅; waiver badge ✅; **billing hooks from queue card are dead-end stubs** (§5.4.3); post-consultation billing handoff missing (§5.4.5) |
| 5 | Invoice Management (§5.5) | 🟡 | Draft→Issue→Pay flow works ✅; zero-fee invoice supported ✅; but money stored as Float (PRD §9 requires NUMERIC(10,2)); payment allowed on Draft invoices (must be Issued first); overpayment silently clamped; no line-item medicine charges (single field only); duplicate-invoice bug from prescription screen |
| 6 | Payment Management (§5.6) | 🟡 | Collection + partial payments work ✅; modes Cash/Card/UPI/Online ✅; gateway integration ❌ (TBD per PRD §15 — acceptable); payment mode displayed wrong in UI (all shown as UPI) |
| 7 | Doctor Interface (§5.8) | 🔴 | **Prescription screen unreachable** (`/prescription` route doesn't exist); auto-completes appointment ✅; fee waiver checkbox ✅ but hardcodes ₹500/₹150 fees into auto-created invoices; iPad-native packaging not done (web only); case-taking tab is mock content |
| 8 | Patient Portal (§5.9) | ❌ | **Entirely missing**: no public booking, no patient login, no self-reschedule/cancel, no patient invoice view, no confirmation notifications |
| 9 | Super-Admin Console (§5.10) | ❌ | Backend has register/audit-list endpoints only. Missing: user list/edit/deactivate/delete, password reset, clinic config editing, system settings, reports/analytics, CSV/PDF export. No frontend console at all |
| 10 | Notification System (§5.11) | ❌ | No notification model/service/log. UI shows a hardcoded mock notifications list. Provider TBD (Twilio/MSG91) per §15 — build event log + outbox now, wire provider later |
| 11 | Audit Logging (NFR-7) | 🟡 | Backend logging works for most mutations ✅ and is SuperAdmin-gated ✅; frontend audit tab shows **mock data** instead of the real unused `getAuditLogs()` API; no entity/date filters (§5.10.5) |
| 12 | Multi-Clinic Support (§5.12) | 🟡 | Two clinics seeded, selector present ✅; clinic CRUD create-only (no edit/config by admin §5.10.2); user↔clinic assignment not enforced anywhere |

## Business rules compliance

| Rule | Status |
|------|--------|
| BR-1 No placeholder buttons | ❌ ~15 dead buttons across dashboards |
| BR-2 Single active consultation | ✅ enforced server-side |
| BR-3 7-day fee waiver | ✅ backend logic ok; frontend surfaces it |
| BR-4 Zero consultation fee | ✅ |
| BR-5 Cancel requires confirmation step | 🟡 confirm dialog exists, no reason capture |
| BR-6 Reschedule audit trail | ✅ |
| BR-7 No GST on patient invoices | ✅ |
| BR-8 Patients shared across clinics | ✅ |
| BR-9 Schedule configurable only by Super Admin | ❌ no admin UI/endpoints for schedule config |
| BR-10 Invoice total formula | ✅ |
| BR-11 Due amount formula | ✅ |
| BR-12 Block In Consultation when occupied | ✅ |

## Security & NFR compliance

| Requirement | Status |
|-------------|--------|
| NFR-1 Performance (≤2s CRUD, 50 users) | 🟡 N+1 queries in appointments/invoices/patients endpoints |
| NFR-4 TLS | ❌ frontend uses http://localhost, no TLS enforcement |
| NFR-5 bcrypt ≥12 | ✅ rounds=12 · JWT ≤15min | ✅ · **refresh-token rotation ❌** |
| NFR-6 RBAC separation | 🟡 RoleChecker exists; roles are free-text strings (no enums); any role string accepted at registration |
| NFR-7 Immutable audit log | ✅ (append-only in code) |
| NFR-8 WCAG 2.1 AA | ❌ not addressed |
| NFR-9 OpenAPI under /api/v1 | ✅ |
| NFR-10 Backups | ⛔ infra concern |
| NFR-13 Record retention ≥3y | ❌ no retention policy |
| §10 OWASP: rate limiting on auth | ❌ none |
| §10 input validation | 🟡 Pydantic validates types; statuses/modes/roles/dates are unvalidated free strings |
| §12.3 No hardcoded credentials | ❌ seed passwords + pre-filled login form + default JWT secret |
| §12.5 Alembic migrations | ❌ uses `create_all` only |

## Data-model deviations from PRD §9

| PRD says | Code does |
|----------|-----------|
| `dob` DATE | String(20) |
| Money NUMERIC(10,2) | Float everywhere |
| ENUMs for gender/status/visit_type/payment_mode/action/role | Free strings |
| TIMESTAMPTZ UTC | naive datetime.utcnow (ok for SQLite dev, wrong for PG prod) |
| Doctor entity with specialization | Doctor is just a User row (acceptable simplification) |

## Build order decided from this gap analysis

1. **Backend foundation** — security, enums, money, business rules, N+1 fixes
2. **Backend new APIs** — patient portal (public booking + OTP auth + own records), super-admin (users/reports/audit filters/clinic config), notification log
3. **Frontend correctness** — router+guards, shared status constants, real error handling, unmock dashboards, wire/hide dead buttons, fix prescription navigation
4. **Frontend new modules** — super-admin console, patient portal
5. **Verification** — pytest suite, flutter analyze, commit & push
