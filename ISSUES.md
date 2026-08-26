# HCMS Codebase — Issues Report

**Date:** 2026-08-26
**Scope:** Full review of `backend/` (FastAPI + SQLAlchemy), `frontend/` (Flutter Web), and repo hygiene.
**Commit reviewed:** `73c1404` (pushed to `origin/main`)

---

## 🔴 Critical — breaks functionality or security

### 1. Broken `/prescription` route
- **Files:** `frontend/lib/screens/doctor/doctor_dashboard.dart:790, 937`, `frontend/lib/main.dart:88-92`
- Doctor dashboard calls `Navigator.pushNamed(context, '/prescription', arguments: appt)`, but only `/`, `/receptionist`, `/doctor` routes are registered. Throws *"Could not find a generator for route"* at runtime.
- Even if registered, `PrescriptionScreen` requires a constructor argument (`required this.appointment`) that named-route navigation never supplies. Needs `onGenerateRoute` or direct `MaterialPageRoute`.
- **Impact:** Doctor portal consultation flow is unusable.

### 2. Hardcoded demo credentials in UI + seed data
- **Files:** `frontend/lib/screens/role_selection_screen.dart:17-20`, `backend/main.py:57-79`
- Login form is pre-filled with real emails/passwords (`doctor123`, `frontdesk123`); same accounts seeded in backend with weak passwords (`admin123`).
- **Impact:** Anyone with the app or repo has full system access.

### 3. Weak JWT secret + wide-open CORS
- **Files:** `backend/auth.py:13`, `backend/main.py:21-27`
- `JWT_SECRET` falls back to a hardcoded string → anyone can forge admin tokens.
- CORS `allow_origins=["*"]` combined with `allow_credentials=True` (insecure/invalid combo).

### 4. All API errors silently swallowed in frontend
- **File:** `frontend/lib/services/api_service.dart` (~14 methods with `catch (_) {}`)
- Network failures, 401s, and validation errors all return `[]`/`null` → UI shows "No patients found" instead of an error.
- Only `login()` and `updateAppointmentStatus()` propagate errors.

### 5. Status-string mismatches (frontend ↔ backend)
Backend canonical statuses (`backend/models.py:65`, `models.py:105`):
- Appointment: `Scheduled, Confirmed, Arrived, In Consultation, Completed, No-Show, Cancelled`
- Invoice: `Draft, Issued, Partially Paid, Paid`

Mismatches:
| Frontend uses | Backend expects | Effect |
|---|---|---|
| `'Waiting'` (`appointments_management.dart:45`) | not a documented status; KPI query (`crud.py:311`) counts it | Inconsistent state machine |
| `'No Show'` (space) — dashboards:516,994,1133 | `'No-Show'` (hyphen) | No-Show counts/columns always empty |
| `'Partial'`, `'Overdue'` filters — receptionist_dashboard:1216, doctor_dashboard:957 | `'Partially Paid'` | Filter chips always show empty |
| `'Follow Up'` filters — receptionist_dashboard:601, doctor_dashboard:759 | `'Follow-Up'` (hyphen) | Follow-up counts always 0 |

### 6. Fake doctor ID fallback
- **Files:** `appointments_management.dart:248, 653`, `patient_management.dart:258`
- Sends `"doctor-uuid-placeholder"` as a foreign key when `_apiService.userId` is null.

---

## 🟠 High — correctness / money bugs

### 7. Floating point used for money
- **File:** `backend/models.py:98-104`
- All invoice/payment amounts use `Float`. Rounding errors guaranteed over time. Use `Numeric(10,2)` / `Decimal`.

### 8. Duplicate invoices from prescription screen
- **File:** `prescription_screen.dart:93-100`
- Auto-creates draft invoice on every save with hardcoded fees (₹500 consult + ₹150 medicine), no idempotency check. Result of `createInvoice` ignored (failures invisible).

### 9. Race condition + wrong-patient fallback on "Start Consultation"
- **File:** `doctor_dashboard.dart:131, 723`
- `_fetchData()` sets active consult via `firstWhere(..., orElse: () => appts.first)` — picks an arbitrary patient when none is "In Consultation". "Start" button triggers full reload then immediately overrides local state.

### 10. Fabricated KPI fallback values
- **File:** `doctor_dashboard.dart:338-340`
- On API failure the dashboard displays fake revenue (`?? 18450.0`), fake patient counts (`?? 46`), fake dues (`?? 24860.0`) as if real.

### 11. Patient ID generation race condition
- **File:** `backend/crud.py:77`
- `unique_patient_id = f"VHC-{year}-{1000 + count + 1}"` based on row count → collisions under concurrency; column is `unique=True` so insert fails with 500.

### 12. Payment rules not enforced
- **File:** `receptionist_dashboard.dart:1317`, `crud.py:260-293`
- "Pay" button shown for Draft invoices (not yet issued). Overpayment clamped silently rather than rejected.

### 13. Walk-in token fabricated client-side
- **File:** `appointments_management.dart:667`
- Token derived from wall-clock time (`T-HHMMSS`); any backend-assigned token ignored.

### 14. Calendar view is fake
- **File:** `appointments_management.dart:478-576`
- Hardcodes today = Thursday and dumps all appointments under Thursday regardless of actual date.

---

## 🟡 Medium — robustness / state management

### 15. `setState` after `await` without `mounted` checks (everywhere)
- Both dashboards, queue management, billing, payments, prescription screen. Causes "setState() called after dispose()" crashes when user navigates mid-request.

### 16. No route guards / client-trusted role routing
- Anyone can push `/doctor` or `/receptionist` without logging in. Role routing trusts client value (`role_selection_screen.dart:46-50`: any non-Receptionist role goes to Doctor portal).

### 17. No token persistence, no 401 handling
- JWT held only in memory (`api_service.dart:12-14`); expired tokens silently return empty lists forever; no refresh mechanism.

### 18. TextEditingController leaks
- Controllers created inside dialog-opening methods never disposed (`appointments_management.dart:95-96, 167-168`, `patient_management.dart:36-44`, `billing_invoice.dart:190-191`).

### 19. Serial awaits instead of parallel fetches
- `doctor_dashboard.dart:122-125`, `receptionist_dashboard.dart:123-126` — KPIs → appointments → patients → invoices awaited sequentially (4× latency). Use `Future.wait`.

### 20. Frontend N+1 waiver checks
- `queue_management.dart:40-44` — one HTTP GET per waiting patient; cache never invalidated between days/status changes.

### 21. Filter state resets on rebuild
- Status filter chips are locals inside `StatefulBuilder`s (`doctor_dashboard.dart:958`, `receptionist_dashboard.dart:809, 1216-1217`) — parent setState (e.g., typing in search) resets them.

### 22. Unguarded `.substring(0, 8)` on IDs
- `doctor_dashboard.dart:1018`, `receptionist_dashboard.dart:1307`, `billing_invoice.dart:199, 362`, `payments_management.dart:165` — RangeError on short/null IDs.

### 23. Deprecated Flutter APIs
- `ColorScheme.background:` param in `main.dart:24` (removed in recent SDKs).
- `withOpacity` throughout (deprecated since Flutter 3.27 → use `withValues(alpha:)`).

### 24. Backend N+1 queries & deprecated startup hook
- `main.py:156-157, 187-191` — patient fetched per appointment/invoice in a loop.
- `main.py:30` — `@app.on_event("startup")` deprecated (use lifespan).
- `auth.py:7` — imports `bcrypt` directly but requirements list `passlib`.

---

## ⚪ Low — hygiene / dead code / polish

### 25. Mock data presented as real
- Inventory screen fully mock; near-expiry detection is literally `expiry.contains('2025')` (`inventory_management.dart:144,149,269`); stock-inward mutates only local state.
- Reports screen hardcoded figures; fake "PDF exported" snackbar (`reports_management.dart:47-54`).
- Notification badge hardcoded to 3 (`receptionist_dashboard.dart:262`); every payment displayed as UPI (`mode = 'UPI'` at line 680).
- "Synced · 2s ago" footer lie in both dashboards.
- Avg wait time fabricated as `waiting.length * 8 min` (line 996).
- Audit tab shows mock logs while real `getAuditLogs()` API exists unused.
- Low-stock/near-expiry KPIs hardcoded ("7"/"3"); `low_stock_alert: 3` hardcoded in `crud.py:339`.

### 26. ~15 do-nothing buttons
Export EOD, View Profile, New Invoice, Record Payment, Compare, Distraction-free/Handwritten/Save draft, quick remedy chips, Queue→Billing handoff, patient row taps, etc.

### 27. Heavy code duplication
- Color palette duplicated verbatim in both dashboards (already diverging).
- `_statusPill`/`_smallBtn`/`_primaryBtn`/`_settingsRow` duplicated across both dashboards with drift.
- Bar-chart logic hand-rolled 3× while reusable `BarChartWidget` in `charts.dart` is unused.
- Booking-dialog logic triplicated (appointments, patients, walk-in flow).
- Patient search/filter duplicated.

### 28. Missing input validation
- Free-text date/time fields everywhere (reschedule, booking, follow-up) — malformed values go straight to the backend.
- Mobile number/email unvalidated (`patient_management.dart:106,137`).
- Bare `int.parse` on stock quantity (`inventory_management.dart:120`).
- No enum validation server-side for role/status/payment_mode/visit_type (plain strings in Pydantic schemas).

### 29. Repo hygiene
- No root README; no automated tests (`test_api.py` is a manual script requiring a live server, despite pytest in requirements).
- SQLite file (`hcms.db`) nearly committed (now gitignored).
- No migrations strategy (uses `create_all`; fine for demo, not for schema changes in prod).
- Unused imports/constants; `_sectionWrap` identity function (`receptionist_dashboard.dart:1937`); unused `import 'billing_invoice.dart'` in queue_management.

### 30. Misc frontend risks
- Dropdown `value:` may reference an ID missing after refetch → assertion crash (`appointments_management.dart:199`).
- Payments ledger sorts by stringified timestamps mixed with `'—'` placeholder → wrong ordering (`payments_management.dart:50-57`).
- Billing stats access raw JSON keys directly — missing key → TypeError (`billing_invoice.dart:288-290`).
- Full-screen reload after every status change (spinner flash, scroll/filter reset).
- Layout overflow risks: fixed 4-column queue Row, `crossAxisCount: 6` grid on narrow windows.
- Medicine rows in prescription form keyed by index — text desync on remove/reorder (`prescription_screen.dart:57-62, 244`).
- Dialog barrier dismissibility captured before loading starts (`role_selection_screen.dart:28`).

---

## Suggested fix priority

| # | Fix | Why first |
|---|-----|-----------|
| 1 | Prescription navigation (#1) | Doctor portal unusable |
| 2 | Remove hardcoded credentials, enforce `JWT_SECRET`, restrict CORS (#2, #3) | Security |
| 3 | Stop swallowing API errors (#4) | Every failure currently invisible |
| 4 | Unify status strings into shared constants (#5) | Silent data-correctness bugs |
| 5 | Decimal money types (#7) + invoice dedupe/idempotency (#8) | Financial integrity |
