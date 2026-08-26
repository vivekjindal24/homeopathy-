import os
import sys
import tempfile

import pytest

_tmpdir = tempfile.mkdtemp()
os.environ["DATABASE_URL"] = f"sqlite:///{_tmpdir}/test_hcms.db"
os.environ["ADMIN_PASSWORD"] = "test-admin-pass-123"
os.environ["DOCTOR_PASSWORD"] = "test-doctor-pass-123"
os.environ["RECEPTIONIST_PASSWORD"] = "test-reception-pass-123"
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fastapi.testclient import TestClient  # noqa: E402
from main import app  # noqa: E402

BASE = "/api/v1"


@pytest.fixture(scope="session")
def client():
    with TestClient(app) as c:
        yield c


def _login(client, email, password):
    r = client.post(f"{BASE}/auth/login", json={"email": email, "password": password})
    assert r.status_code == 200, r.text
    return r.json()


@pytest.fixture(scope="session")
def rec(client):
    return _login(client, "receptionist@vermahomeopathy.com", os.environ["RECEPTIONIST_PASSWORD"])


@pytest.fixture(scope="session")
def doctor(client):
    return _login(client, "doctor@vermahomeopathy.com", os.environ["DOCTOR_PASSWORD"])


@pytest.fixture(scope="session")
def admin(client):
    return _login(client, "admin@vermahomeopathy.com", os.environ["ADMIN_PASSWORD"])


def H(tok):
    return {"Authorization": f"Bearer {tok['access_token']}"}


# --- Auth ---
def test_login_wrong_password(client):
    r = client.post(f"{BASE}/auth/login",
                    json={"email": "admin@vermahomeopathy.com", "password": "nope"})
    assert r.status_code == 401


def test_refresh_rotation(client, admin):
    r = client.post(f"{BASE}/auth/refresh", json={"refresh_token": admin["refresh_token"]})
    assert r.status_code == 200
    # Old refresh token must be single-use: reuse is rejected and family revoked
    r2 = client.post(f"{BASE}/auth/refresh", json={"refresh_token": admin["refresh_token"]})
    assert r2.status_code == 401
    # And the token issued by the first refresh is also dead (family revoked)
    new_tok = r.json()["refresh_token"]
    r3 = client.post(f"{BASE}/auth/refresh", json={"refresh_token": new_tok})
    assert r3.status_code == 401


def test_rbac_receptionist_cannot_admin(client, rec):
    r = client.get(f"{BASE}/admin/users", headers=H(rec))
    assert r.status_code == 403


def test_unauthenticated_rejected(client):
    assert client.get(f"{BASE}/patients").status_code == 401
    assert client.get(f"{BASE}/audit-logs").status_code == 401


# --- Patients ---
def test_patient_validation(client, rec):
    bad = {"full_name": "X", "dob": "1990-01-01", "gender": "M",
           "mobile": "12345", "address": "a", "occupation": "b"}
    assert client.post(f"{BASE}/patients", json=bad, headers=H(rec)).status_code == 422
    bad["mobile"] = "9876543210"
    bad["dob"] = "not-a-date"
    assert client.post(f"{BASE}/patients", json=bad, headers=H(rec)).status_code == 422


def test_patient_create_and_mobile_idempotency(client, rec):
    body = {"full_name": "Rohan Verma", "dob": "1994-05-12", "gender": "M",
            "mobile": "9876543210", "address": "Scheme 54", "occupation": "Engineer"}
    r1 = client.post(f"{BASE}/patients", json=body, headers=H(rec))
    assert r1.status_code == 200, r1.text
    p1 = r1.json()
    assert p1["unique_patient_id"].startswith("VHC-")
    r2 = client.post(f"{BASE}/patients", json=body, headers=H(rec))
    assert r2.json()["patient_id"] == p1["patient_id"]  # matched by mobile, not duplicated


# --- Appointments & status machine ---
@pytest.fixture(scope="session")
def appt_setup(client, rec):
    clinics = client.get(f"{BASE}/clinics", headers=H(rec)).json()
    me = client.get(f"{BASE}/users/me", headers=H(rec)).json()
    patients = []
    for i, name in enumerate(["Sita Gupta", "Ram Das"]):
        p = client.post(f"{BASE}/patients", headers=H(rec), json={
            "full_name": f"{name} {i}", "dob": "1991-08-20", "gender": "F" if i == 0 else "M",
            "mobile": f"98765432{10 + i}", "address": "Indore", "occupation": "Teacher",
        }).json()
        patients.append(p)
    a1 = client.post(f"{BASE}/appointments", headers=H(rec), json={
        "patient_id": patients[0]["patient_id"], "doctor_id": me["user_id"],
        "clinic_id": clinics[0]["clinic_id"], "appt_date": "2030-01-15",
        "appt_time": "10:30", "visit_type": "New"}).json()
    a2 = client.post(f"{BASE}/appointments", headers=H(rec), json={
        "patient_id": patients[1]["patient_id"], "doctor_id": me["user_id"],
        "clinic_id": clinics[0]["clinic_id"], "appt_date": "2030-01-15",
        "appt_time": "11:00", "visit_type": "Follow-Up"}).json()
    return a1, a2


def test_status_transition_chain(client, rec, appt_setup):
    a1, _ = appt_setup
    for st in ["Confirmed", "Arrived", "In Consultation"]:
        r = client.put(f"{BASE}/appointments/{a1['appt_id']}/status",
                       json={"status": st}, headers=H(rec))
        assert r.status_code == 200, r.text
        assert r.json()["status"] == st
    # Invalid jump: In Consultation -> Confirmed must be blocked
    r = client.put(f"{BASE}/appointments/{a1['appt_id']}/status",
                   json={"status": "Confirmed"}, headers=H(rec))
    assert r.status_code == 400


def test_single_active_consultation_rule(client, rec, appt_setup):
    a1, a2 = appt_setup
    # Move a2 through the valid chain up to Arrived
    for st in ["Confirmed", "Arrived"]:
        r = client.put(f"{BASE}/appointments/{a2['appt_id']}/status",
                       json={"status": st}, headers=H(rec))
        assert r.status_code == 200, r.text
    # a1 already In Consultation from previous test -> starting a2 must be blocked
    r = client.put(f"{BASE}/appointments/{a2['appt_id']}/status",
                   json={"status": "In Consultation"}, headers=H(rec))
    assert r.status_code == 400
    assert "blocked" in r.json()["detail"].lower()


def test_cancel_requires_reason(client, rec, appt_setup):
    _, a2 = appt_setup
    r = client.put(f"{BASE}/appointments/{a2['appt_id']}/status",
                   json={"status": "Cancelled"}, headers=H(rec))
    assert r.status_code == 400
    r = client.put(f"{BASE}/appointments/{a2['appt_id']}/status",
                   json={"status": "Cancelled", "reason": "Patient called off"}, headers=H(rec))
    assert r.status_code == 200
    assert r.json()["cancel_reason"] == "Patient called off"


def test_token_numbers_assigned(rec, appt_setup):
    a1, _ = appt_setup
    assert a1["token_number"] >= 1


# --- Waiver ---
def test_7day_waiver_false_for_new_patient(client, rec, appt_setup):
    a1, _ = appt_setup
    r = client.get(f"{BASE}/patients/{a1['patient_id']}/7day-waiver",
                   params={"appt_date": "2030-01-20"}, headers=H(rec))
    assert r.status_code == 200
    assert r.json()["eligible"] is False


# --- Invoice / Payment business rules (BR-10, BR-11) ---
@pytest.fixture(scope="session")
def invoice_setup(client, rec, appt_setup):
    a1, _ = appt_setup
    inv = client.post(f"{BASE}/invoices", headers=H(rec), json={
        "patient_id": a1["patient_id"], "appt_id": a1["appt_id"],
        "consultation_fee": 500, "medicine_charges": 250.50,
        "misc_charges": 49.50, "discount": 100}).json()
    return a1, inv


def test_invoice_total_formula(client, rec, invoice_setup):
    _, inv = invoice_setup
    assert float(inv["total_amount"]) == 700.0
    assert inv["status"] == "Draft"


def test_payment_blocked_on_draft(client, rec, invoice_setup):
    _, inv = invoice_setup
    r = client.post(f"{BASE}/invoices/{inv['invoice_id']}/payments",
                    json={"amount": 100, "payment_mode": "UPI"}, headers=H(rec))
    assert r.status_code == 400


def test_issue_then_partial_then_full(client, rec, invoice_setup):
    a1, inv = invoice_setup
    iid = inv["invoice_id"]
    r = client.put(f"{BASE}/invoices/{iid}/issue", headers=H(rec))
    assert r.status_code == 200 and r.json()["status"] == "Issued"

    r = client.post(f"{BASE}/invoices/{iid}/payments",
                    json={"amount": 300, "payment_mode": "Cash"}, headers=H(rec))
    assert r.status_code == 200
    inv_now = client.get(f"{BASE}/invoices/{iid}", headers=H(rec)).json()
    assert inv_now["status"] == "Partially Paid"
    assert float(inv_now["due_amount"]) == 400.0

    r = client.post(f"{BASE}/invoices/{iid}/payments",
                    json={"amount": 500, "payment_mode": "UPI"}, headers=H(rec))
    assert r.status_code == 400  # overpay rejected
    r = client.post(f"{BASE}/invoices/{iid}/payments",
                    json={"amount": 400, "payment_mode": "UPI"}, headers=H(rec))
    assert r.status_code == 200
    inv_final = client.get(f"{BASE}/invoices/{iid}", headers=H(rec)).json()
    assert inv_final["status"] == "Paid"
    assert float(inv_final["due_amount"]) == 0.0


def test_double_issue_rejected(client, rec, invoice_setup):
    _, inv = invoice_setup
    r = client.put(f"{BASE}/invoices/{inv['invoice_id']}/issue", headers=H(rec))
    assert r.status_code == 400


# --- Prescriptions ---
def test_prescription_completes_appointment(client, doctor, appt_setup):
    a1, _ = appt_setup
    r = client.post(f"{BASE}/prescriptions", headers=H(doctor), json={
        "appt_id": a1["appt_id"], "patient_id": a1["patient_id"],
        "chief_complaint": "Cough", "diagnosis": "Bronchitis",
        "medicines": [{"name": "Bryonia", "potency": "30C", "dosage": "5 pills",
                       "frequency": "TDS", "duration": "7 days"}],
        "is_fee_waived": True})
    assert r.status_code == 200, r.text
    rec_appt = client.get(f"{BASE}/appointments", params={"appt_date": "2030-01-15"},
                          headers=H(doctor)).json()
    target = next(a for a in rec_appt if a["appt_id"] == a1["appt_id"])
    assert target["status"] == "Completed"


def test_receptionist_cannot_prescribe(client, rec, appt_setup):
    a1, _ = appt_setup
    r = client.post(f"{BASE}/prescriptions", headers=H(rec), json={
        "appt_id": a1["appt_id"], "patient_id": a1["patient_id"],
        "chief_complaint": "x", "diagnosis": "y",
        "medicines": [{"name": "n", "potency": "p", "dosage": "d",
                       "frequency": "f", "duration": "w"}]})
    assert r.status_code == 403


# --- Patient Portal ---
def test_portal_public_booking(client):
    clinics = client.get(f"{BASE}/portal/clinics").json()
    assert len(clinics) == 2
    r = client.post(f"{BASE}/portal/book", json={
        "full_name": "Portal User", "mobile": "9988776655", "dob": "1988-03-03",
        "gender": "F", "clinic_id": clinics[0]["clinic_id"],
        "appt_date": "2030-02-01", "appt_time": "10:00", "visit_type": "New"})
    assert r.status_code == 200, r.text
    assert r.json()["token_number"] >= 1
    # Slot outside clinic hours rejected
    r2 = client.post(f"{BASE}/portal/book", json={
        "full_name": "Portal User", "mobile": "9988776655", "dob": "1988-03-03",
        "gender": "F", "clinic_id": clinics[0]["clinic_id"],
        "appt_date": "2030-02-01", "appt_time": "23:00", "visit_type": "New"})
    assert r2.status_code == 400


def test_portal_otp_flow(client):
    r = client.post(f"{BASE}/portal/otp/request", json={"mobile": "9988776655"})
    assert r.status_code == 200
    code = r.json().get("dev_otp")
    assert code
    rv = client.post(f"{BASE}/portal/otp/verify", json={"mobile": "9988776655", "code": code})
    assert rv.status_code == 200, rv.text
    tok = rv.json()

    mine = client.get(f"{BASE}/portal/me/appointments", headers=H(tok))
    assert mine.status_code == 200
    assert len(mine.json()) == 1

    appt_id = mine.json()[0]["appt_id"]
    rc = client.put(f"{BASE}/portal/appointments/{appt_id}/cancel",
                    json={"reason": "Plans changed"}, headers=H(tok))
    assert rc.status_code == 200 and rc.json()["status"] == "Cancelled"

    # OTP reuse must fail
    rv2 = client.post(f"{BASE}/portal/otp/verify", json={"mobile": "9988776655", "code": code})
    assert rv2.status_code == 401


def test_portal_isolation(client):
    # Another patient cannot see/cancel someone else's appointment
    r = client.post(f"{BASE}/portal/otp/request", json={"mobile": "9876543210"})
    code = r.json().get("dev_otp")
    tok = client.post(f"{BASE}/portal/otp/verify",
                      json={"mobile": "9876543210", "code": code}).json()
    assert "access_token" in tok, tok
    mine_ids = {a["appt_id"] for a in client.get(
        f"{BASE}/portal/me/appointments", headers=H(tok)).json()}
    all_appts = client.get(f"{BASE}/appointments",
                           params={"appt_date": "2030-02-01"},
                           headers={"Authorization": f"Bearer {tok['access_token']}"})
    if all_appts.status_code == 200:
        for a in all_appts.json():
            if a["appt_id"] not in mine_ids:
                r = client.put(f"{BASE}/portal/appointments/{a['appt_id']}/cancel",
                               json={}, headers=H(tok))
                assert r.status_code == 404


# --- Admin ---
def test_admin_user_management(client, admin, rec):
    users = client.get(f"{BASE}/admin/users", headers=H(admin)).json()
    assert len(users) >= 3
    target = next(u for u in users if u["role"] == "Receptionist")

    r = client.patch(f"{BASE}/admin/users/{target['user_id']}",
                    json={"is_active": False}, headers=H(admin))
    assert r.status_code == 200 and r.json()["is_active"] is False

    # Deactivated user cannot log in
    r = client.post(f"{BASE}/auth/login",
                    json={"email": "receptionist@vermahomeopathy.com",
                          "password": os.environ["RECEPTIONIST_PASSWORD"]})
    assert r.status_code == 403

    client.patch(f"{BASE}/admin/users/{target['user_id']}",
                json={"is_active": True}, headers=H(admin))

    r = client.post(f"{BASE}/admin/users/{target['user_id']}/reset-password",
                   json={"new_password": "brand-new-pass-99"}, headers=H(admin))
    assert r.status_code == 200
    r = client.post(f"{BASE}/auth/login",
                    json={"email": "receptionist@vermahomeopathy.com", "password": "brand-new-pass-99"})
    assert r.status_code == 200


def test_audit_log_filters(client, admin):
    logs = client.get(f"{BASE}/audit-logs", params={"entity_type": "Invoice"}, headers=H(admin)).json()
    assert logs and all(l["entity_type"] == "Invoice" for l in logs)


def test_reports(client, admin):
    rev = client.get(f"{BASE}/admin/reports/revenue",
                    params={"from_date": "2026-01-01", "to_date": "2031-12-31"}, headers=H(admin)).json()
    total = sum(float(p["revenue"]) for p in rev)
    assert abs(total - 700.0) < 0.001  # from payment tests above
    summ = client.get(f"{BASE}/admin/reports/appointments",
                     params={"from_date": "2026-01-01", "to_date": "2031-12-31"}, headers=H(admin)).json()
    assert summ["total"] >= 2
    regs = client.get(f"{BASE}/admin/reports/registrations", headers=H(admin)).json()
    assert isinstance(regs, list)


def test_notifications_recorded(client, admin):
    notes = client.get(f"{BASE}/notifications", headers=H(admin)).json()
    events = {n["event"] for n in notes}
    assert "appointment_booked" in events
