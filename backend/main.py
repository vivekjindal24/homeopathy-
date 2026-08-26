import os
import secrets
from contextlib import asynccontextmanager
from datetime import datetime, timedelta, date
from decimal import Decimal
from typing import Optional

from fastapi import FastAPI, Depends, HTTPException, status, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from database import engine, Base, get_db
from alembic.config import Config
from alembic import command
import models, schemas, crud, auth


@asynccontextmanager
async def lifespan(app: FastAPI):
    import sys
    try:
        print("[startup] Running alembic migrations...", flush=True)
        alembic_cfg = Config("alembic.ini")
        command.upgrade(alembic_cfg, "head")
        print("[startup] Migrations complete.", flush=True)
    except Exception as e:
        print(f"[startup] Alembic error: {e}", file=sys.stderr, flush=True)
        raise
    try:
        print("[startup] Seeding data...", flush=True)
        seed_data()
        print("[startup] Seed complete.", flush=True)
    except Exception as e:
        print(f"[startup] Seed error: {e}", file=sys.stderr, flush=True)
    yield


app = FastAPI(
    title="Verma Homeopathy Clinic OS API",
    version="2.0.0",
    docs_url="/api/v1/docs",
    openapi_url="/api/v1/openapi.json",
    lifespan=lifespan,
)

# CORS (PRD §12.3): origins configured via env; wildcard only without credentials.
_origins_env = os.getenv("ALLOWED_ORIGINS", "")
if _origins_env:
    _origins = [o.strip() for o in _origins_env.split(",") if o.strip()]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )


def seed_data():
    db = next(get_db())
    try:
        if db.query(models.Clinic).count() > 0:
            return
        clinic_a = models.Clinic(
            name="Vijay Nagar Branch (Clinic A)",
            address="102, Orbit Mall, Vijay Nagar, Indore, MP",
            timing_start="09:00", timing_end="13:00",
        )
        clinic_b = models.Clinic(
            name="Palasia Branch (Clinic B)",
            address="5, Saket Nagar Main Rd, Palasia, Indore, MP",
            timing_start="17:00", timing_end="21:00",
        )
        db.add(clinic_a)
        db.add(clinic_b)
        db.commit()
        db.refresh(clinic_a)
        db.refresh(clinic_b)

        # Passwords come from env (§12.3). If absent, a random one is generated and printed ONCE.
        creds = []
        for role, email, name, env_var in [
            ("SuperAdmin", "admin@vermahomeopathy.com", "Dr. Vishvesh Kumar Verma", "ADMIN_PASSWORD"),
            ("Doctor", "doctor@vermahomeopathy.com", "Dr. Vishvesh Kumar Verma (Doctor)", "DOCTOR_PASSWORD"),
            ("Receptionist", "receptionist@vermahomeopathy.com", "Vijay Front Desk", "RECEPTIONIST_PASSWORD"),
        ]:
            env_pwd = os.getenv(env_var)
            pwd = env_pwd or secrets.token_urlsafe(12)
            creds.append((email, pwd, bool(env_pwd)))
            db.add(models.User(
                full_name=name,
                email=email,
                password_hash=auth.get_password_hash(pwd),
                role=role,
                clinic_ids=[clinic_a.clinic_id, clinic_b.clinic_id],
            ))
        db.commit()
        print("=" * 60)
        print("FIRST-RUN SEEDED ACCOUNTS (set ADMIN_PASSWORD / DOCTOR_PASSWORD /")
        print("RECEPTIONIST_PASSWORD env vars to control these):")
        for email, pwd, from_env in creds:
            if not from_env:
                print(f"  {email}: {pwd}")
        print("=" * 60)

        # --- Seed Medicines ---
        seed_medicines = [
            ("Arnica Montana 200C", "SBL", "ARN-2026-001", 150, 120.00, "2028-06-15", 10),
            ("Belladonna 30C", "Dr. Reckeweg", "BEL-2026-002", 6, 85.00, "2026-09-20", 10),
            ("Nux Vomica 1M", "Boiron", "NVX-2025-003", 4, 200.00, "2026-03-30", 10),
            ("Sulphur 6C", "Schwabe", "SUL-2027-004", 200, 90.00, "2027-11-01", 20),
            ("Rhus Tox 30C", "SBL", "RTX-2025-005", 5, 75.00, "2026-02-10", 10),
            ("Pulsatilla 200C", "Dr. Reckeweg", "PUL-2027-006", 80, 140.00, "2027-04-18", 10),
            ("Bryonia Alba 30C", "Boiron", "BRY-2026-007", 3, 95.00, "2026-05-25", 8),
            ("Lycopodium 200C", "SBL", "LYC-2026-008", 120, 110.00, "2027-08-30", 15),
            ("Calcarea Carb 6C", "Schwabe", "CCC-2027-009", 50, 65.00, "2027-12-20", 10),
            ("Natrum Mur 30C", "Dr. Reckeweg", "NMU-2025-010", 9, 80.00, "2026-01-15", 10),
        ]
        for clinic in [clinic_a, clinic_b]:
            for name, mfr, batch, qty, price, exp, threshold in seed_medicines:
                db.add(models.Medicine(
                    name=name, manufacturer=mfr, batch_number=batch,
                    quantity=qty, unit_price=Decimal(str(price)),
                    expiry_date=exp, low_stock_threshold=threshold,
                    clinic_id=clinic.clinic_id,
                ))
        db.commit()
    finally:
        db.close()


def _issue_user_tokens(db: Session, user: models.User, family_id: Optional[str] = None) -> dict:
    access = auth.create_access_token(data={"sub": user.email})
    refresh = auth.create_refresh_token(db, "user", user.user_id, family_id=family_id)
    return {
        "access_token": access,
        "refresh_token": refresh,
        "token_type": "bearer",
        "role": user.role,
        "full_name": user.full_name,
        "user_id": user.user_id,
    }


# --- Auth Routes ---
@app.post("/api/v1/auth/login", response_model=schemas.Token)
def login(login_req: schemas.LoginRequest, db: Session = Depends(get_db)):
    auth.login_limiter.check(f"login:{login_req.email}")
    user = crud.get_user_by_email(db, login_req.email)
    if not user or not auth.verify_password(login_req.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account deactivated")
    auth.login_limiter.reset(f"login:{login_req.email}")
    return _issue_user_tokens(db, user)


@app.post("/api/v1/auth/refresh", response_model=schemas.Token)
def refresh_tokens(req: schemas.RefreshRequest, db: Session = Depends(get_db)):
    result = auth.rotate_refresh_token(db, req.refresh_token, expected_type="user")
    if not result:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")
    family_id, user_id = result
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="User not found or inactive")
    return _issue_user_tokens(db, user, family_id=family_id)


@app.post("/api/v1/auth/logout")
def logout(req: schemas.RefreshRequest, db: Session = Depends(get_db)):
    row = db.query(models.RefreshToken).filter(
        models.RefreshToken.token_hash == auth.hash_token(req.refresh_token)).first()
    if row:
        auth.revoke_all_refresh_tokens(db, row.principal_type, row.principal_id)
    return {"ok": True}


@app.get("/api/v1/health")
def health():
    return {"status": "ok"}


# --- Staff User Routes ---
@app.post("/api/v1/auth/register", response_model=schemas.UserResponse)
def register_user(user: schemas.UserCreate, db: Session = Depends(get_db),
                  current_user: models.User = Depends(auth.require_admin)):
    existing = crud.get_user_by_email(db, user.email)
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    return crud.create_user(db, user, current_user.user_id)


@app.get("/api/v1/users/me", response_model=schemas.UserResponse)
def get_me(current_user: models.User = Depends(auth.get_current_user)):
    return current_user


# --- Clinic Routes ---
@app.post("/api/v1/clinics", response_model=schemas.ClinicResponse)
def create_clinic(clinic: schemas.ClinicCreate, db: Session = Depends(get_db),
                  current_user: models.User = Depends(auth.require_admin)):
    return crud.create_clinic(db, clinic, current_user.user_id)


@app.patch("/api/v1/clinics/{clinic_id}", response_model=schemas.ClinicResponse)
def update_clinic(clinic_id: str, data: schemas.ClinicUpdate, db: Session = Depends(get_db),
                  current_user: models.User = Depends(auth.require_admin)):
    return crud.update_clinic(db, clinic_id, data, current_user.user_id)


@app.get("/api/v1/clinics", response_model=list[schemas.ClinicResponse])
def get_clinics(db: Session = Depends(get_db),
                current_user: models.User = Depends(auth.require_any_user)):
    return crud.get_clinics(db)


# Public clinics for the patient portal (booking needs timings; no sensitive data)
@app.get("/api/v1/portal/clinics", response_model=list[schemas.ClinicResponse])
def portal_clinics(db: Session = Depends(get_db)):
    return crud.get_clinics(db)


# --- Patient Routes ---
@app.post("/api/v1/patients", response_model=schemas.PatientResponse)
def create_patient(patient: schemas.PatientCreate, db: Session = Depends(get_db),
                   current_user: models.User = Depends(auth.require_receptionist)):
    return crud.create_patient(db, patient, current_user.user_id)


@app.get("/api/v1/patients", response_model=list[schemas.PatientResponse])
def get_patients(search: Optional[str] = None, db: Session = Depends(get_db),
                 current_user: models.User = Depends(auth.require_any_user)):
    return crud.get_patients(db, search)


@app.get("/api/v1/patients/{patient_id}", response_model=schemas.PatientResponse)
def get_patient(patient_id: str, db: Session = Depends(get_db),
                current_user: models.User = Depends(auth.require_any_user)):
    p = crud.get_patient(db, patient_id)
    if not p:
        raise HTTPException(status_code=404, detail="Patient not found")
    return p


@app.get("/api/v1/patients/{patient_id}/7day-waiver")
def check_waiver(patient_id: str, appt_date: str, db: Session = Depends(get_db),
                 current_user: models.User = Depends(auth.require_any_user)):
    eligible = crud.check_7day_waiver_eligibility(db, patient_id, appt_date)
    return {"eligible": eligible}


@app.get("/api/v1/patients/{patient_id}/prescriptions", response_model=list[schemas.PrescriptionResponse])
def get_patient_prescriptions(patient_id: str, db: Session = Depends(get_db),
                              current_user: models.User = Depends(auth.require_any_user)):
    return crud.get_prescriptions_by_patient(db, patient_id)


# --- Appointment Routes ---
@app.post("/api/v1/appointments", response_model=schemas.AppointmentResponse)
def create_appointment(appt: schemas.AppointmentCreate, db: Session = Depends(get_db),
                       current_user: models.User = Depends(auth.require_receptionist)):
    return crud.create_appointment(db, appt, current_user.user_id)


@app.get("/api/v1/appointments", response_model=list[schemas.AppointmentResponse])
def get_appointments(clinic_id: Optional[str] = None, appt_date: Optional[str] = None,
                     db: Session = Depends(get_db),
                     current_user: models.User = Depends(auth.require_any_user)):
    appts = crud.get_appointments(db, clinic_id, appt_date)
    for a in appts:
        _ = a.patient  # ensure loaded relationship is serialized
    return appts


@app.put("/api/v1/appointments/{appt_id}/status", response_model=schemas.AppointmentResponse)
def update_appt_status(appt_id: str, update: schemas.AppointmentStatusUpdate,
                       db: Session = Depends(get_db),
                       current_user: models.User = Depends(auth.require_any_user)):
    return crud.update_appointment_status(db, appt_id, update.status, current_user.user_id, update.reason)


@app.put("/api/v1/appointments/{appt_id}/reschedule", response_model=schemas.AppointmentResponse)
def reschedule_appt(appt_id: str, reschedule: schemas.AppointmentReschedule,
                    db: Session = Depends(get_db),
                    current_user: models.User = Depends(auth.require_receptionist)):
    return crud.reschedule_appointment(db, appt_id, reschedule, current_user.user_id)


# --- Prescription Routes ---
@app.post("/api/v1/prescriptions", response_model=schemas.PrescriptionResponse)
def create_prescription(rx: schemas.PrescriptionCreate, db: Session = Depends(get_db),
                        current_user: models.User = Depends(auth.require_doctor)):
    return crud.create_prescription(db, rx, current_user.user_id)


# --- Invoice & Payment Routes ---
@app.post("/api/v1/invoices", response_model=schemas.InvoiceResponse)
def create_invoice(invoice: schemas.InvoiceCreate, db: Session = Depends(get_db),
                   current_user: models.User = Depends(auth.require_receptionist)):
    inv = crud.create_invoice(db, invoice, current_user.user_id)
    _ = inv.patient
    return inv


@app.get("/api/v1/invoices", response_model=list[schemas.InvoiceResponse])
def get_invoices(patient_id: Optional[str] = None, db: Session = Depends(get_db),
                 current_user: models.User = Depends(auth.require_any_user)):
    return crud.get_invoices(db, patient_id)


@app.get("/api/v1/invoices/{invoice_id}", response_model=schemas.InvoiceResponse)
def get_invoice(invoice_id: str, db: Session = Depends(get_db),
                current_user: models.User = Depends(auth.require_any_user)):
    inv = crud.get_invoice(db, invoice_id)
    if not inv:
        raise HTTPException(status_code=404, detail="Invoice not found")
    return inv


@app.put("/api/v1/invoices/{invoice_id}/issue", response_model=schemas.InvoiceResponse)
def issue_invoice(invoice_id: str, db: Session = Depends(get_db),
                  current_user: models.User = Depends(auth.require_receptionist)):
    return crud.issue_invoice(db, invoice_id, current_user.user_id)


@app.post("/api/v1/invoices/{invoice_id}/payments", response_model=schemas.PaymentResponse)
def record_payment(invoice_id: str, payment: schemas.PaymentCreate, db: Session = Depends(get_db),
                   current_user: models.User = Depends(auth.require_receptionist)):
    return crud.create_payment(db, invoice_id, payment, current_user.user_id)


# --- Audit Log Routes ---
@app.get("/api/v1/audit-logs", response_model=list[schemas.AuditLogResponse])
def get_audit_logs(entity_type: Optional[str] = None, action: Optional[str] = None,
                   from_date: Optional[str] = None, to_date: Optional[str] = None,
                   db: Session = Depends(get_db),
                   current_user: models.User = Depends(auth.require_admin)):
    return crud.get_audit_logs(db, entity_type, action, from_date, to_date)


# --- Notifications ---
@app.get("/api/v1/notifications", response_model=list[schemas.NotificationResponse])
def list_notifications(db: Session = Depends(get_db),
                       current_user: models.User = Depends(auth.require_any_user)):
    return crud.get_notifications(db)


# --- Dashboard Routes ---
@app.get("/api/v1/dashboard/kpis", response_model=schemas.KpisResponse)
def get_kpis(clinic_id: str, date_str: str, db: Session = Depends(get_db),
             current_user: models.User = Depends(auth.require_any_user)):
    try:
        date.fromisoformat(date_str)
    except ValueError:
        raise HTTPException(status_code=400, detail="date_str must be YYYY-MM-DD")
    return crud.get_dashboard_kpis(db, clinic_id, date_str)


# --- Super Admin: Users / Reports (§5.10) ---
@app.get("/api/v1/admin/users", response_model=list[schemas.UserResponse])
def admin_list_users(db: Session = Depends(get_db),
                     current_user: models.User = Depends(auth.require_admin)):
    return crud.get_users(db)


@app.patch("/api/v1/admin/users/{user_id}", response_model=schemas.UserResponse)
def admin_update_user(user_id: str, data: schemas.UserUpdate, db: Session = Depends(get_db),
                      current_user: models.User = Depends(auth.require_admin)):
    return crud.update_user(db, user_id, data, current_user.user_id)


@app.post("/api/v1/admin/users/{user_id}/reset-password")
def admin_reset_password(user_id: str, body: schemas.PasswordReset, db: Session = Depends(get_db),
                         current_user: models.User = Depends(auth.require_admin)):
    crud.reset_password(db, user_id, body.new_password, current_user.user_id)
    return {"ok": True}


@app.delete("/api/v1/admin/users/{user_id}")
def admin_delete_user(user_id: str, db: Session = Depends(get_db),
                      current_user: models.User = Depends(auth.require_admin)):
    crud.delete_user(db, user_id, current_user.user_id)
    return {"ok": True}


@app.get("/api/v1/admin/reports/revenue", response_model=list[schemas.RevenuePoint])
def admin_report_revenue(from_date: str, to_date: str, clinic_id: Optional[str] = None,
                         db: Session = Depends(get_db),
                         current_user: models.User = Depends(auth.require_admin)):
    return crud.report_revenue(db, from_date, to_date, clinic_id)


@app.get("/api/v1/admin/reports/appointments", response_model=schemas.AppointmentSummary)
def admin_report_appointments(from_date: str, to_date: str, clinic_id: Optional[str] = None,
                              db: Session = Depends(get_db),
                              current_user: models.User = Depends(auth.require_admin)):
    return crud.report_appointments(db, from_date, to_date, clinic_id)


@app.get("/api/v1/admin/reports/registrations", response_model=list[schemas.RegistrationPoint])
def admin_report_registrations(months: int = Query(6, ge=1, le=24), db: Session = Depends(get_db),
                               current_user: models.User = Depends(auth.require_admin)):
    return crud.report_registrations(db, months)


# --- Patient Portal (§5.9) ---
@app.post("/api/v1/portal/book", response_model=schemas.AppointmentResponse)
def portal_book(req: schemas.PortalBookingRequest, db: Session = Depends(get_db)):
    clinic = crud.get_clinic(db, req.clinic_id)
    if not clinic:
        raise HTTPException(status_code=400, detail="Invalid clinic")

    # Validate slot within clinic operating hours (§5.9.1)
    if not (clinic.timing_start <= req.appt_time < clinic.timing_end):
        raise HTTPException(status_code=400,
                            detail=f"Time must be between {clinic.timing_start} and {clinic.timing_end}")

    # One active booking per mobile per day at the same time
    dupes = db.query(models.Appointment).join(models.Patient).filter(
        models.Patient.mobile == req.mobile,
        models.Appointment.appt_date == req.appt_date,
        models.Appointment.appt_time == req.appt_time,
        models.Appointment.status.in_(["Scheduled", "Confirmed"]),
    ).count()
    if dupes:
        raise HTTPException(status_code=400, detail="You already have an appointment at this date/time")

    patient = crud.create_patient(db, schemas.PatientCreate(
        full_name=req.full_name, dob=req.dob, gender=req.gender, mobile=req.mobile,
        address="-", occupation="-",
    ))
    doctor = db.query(models.User).filter(models.User.role == "Doctor", models.User.is_active.is_(True)).first()
    if not doctor:
        raise HTTPException(status_code=503, detail="Online booking unavailable right now")
    appt = crud.create_appointment(db, schemas.AppointmentCreate(
        patient_id=patient.patient_id,
        doctor_id=doctor.user_id if doctor else "unassigned",
        clinic_id=req.clinic_id,
        appt_date=req.appt_date,
        appt_time=req.appt_time,
        visit_type=req.visit_type,
        notes=req.notes,
    ), "patient-portal")
    return appt

@app.post("/api/v1/portal/otp/request")
def portal_request_otp(body: schemas.OtpRequest, db: Session = Depends(get_db)):
    auth.otp_limiter.check(f"otp:{body.mobile}")
    patient = crud.get_patient_by_mobile(db, body.mobile)
    if not patient:
        raise HTTPException(status_code=404, detail="No patient record found for this mobile number")

    code = f"{secrets.randbelow(900000) + 100000}"
    row = models.OTPCode(
        mobile=body.mobile,
        code_hash=auth.hash_token(code),
        expires_at=datetime.utcnow() + timedelta(minutes=10),
    )
    db.add(row)
    db.commit()

    sms_configured = bool(os.getenv("SMS_PROVIDER"))
    crud.notify(db, "otp_login", "SMS", body.mobile,
                f"Your HCMS login code is {code}. Valid for 10 minutes.",
                patient_id=patient.patient_id)
    resp = {"ok": True, "message": "OTP sent via SMS"}
    if not sms_configured:
        # Dev mode: no SMS gateway configured (TBD-2) — surface the code so the flow is testable.
        resp["dev_otp"] = code
    return resp


@app.post("/api/v1/portal/otp/verify", response_model=schemas.PatientToken)
def portal_verify_otp(body: schemas.OtpVerify, db: Session = Depends(get_db)):
    auth.otp_limiter.check(f"otpv:{body.mobile}")
    now = datetime.utcnow()
    rows = db.query(models.OTPCode).filter(
        models.OTPCode.mobile == body.mobile,
        models.OTPCode.consumed.is_(False),
        models.OTPCode.expires_at > now,
    ).order_by(models.OTPCode.created_at.desc()).limit(5).all()
    match = next((r for r in rows if r.code_hash == auth.hash_token(body.code)), None)
    if not match:
        raise HTTPException(status_code=401, detail="Invalid or expired OTP")
    match.consumed = True
    db.commit()
    auth.otp_limiter.reset(f"otp:{body.mobile}")
    auth.otp_limiter.reset(f"otpv:{body.mobile}")

    patient = crud.get_patient_by_mobile(db, body.mobile)
    access = auth.create_access_token(data={"sub": patient.patient_id, "principal": "patient"})
    refresh = auth.create_refresh_token(db, "patient", patient.patient_id)
    return {
        "access_token": access, "refresh_token": refresh, "token_type": "bearer",
        "patient_id": patient.patient_id, "full_name": patient.full_name,
    }


@app.get("/api/v1/portal/me/appointments", response_model=list[schemas.AppointmentResponse])
def portal_my_appointments(db: Session = Depends(get_db),
                           patient: models.Patient = Depends(auth.get_current_patient)):
    return crud.get_patient_appointments(db, patient.patient_id)


@app.put("/api/v1/portal/appointments/{appt_id}/cancel", response_model=schemas.AppointmentResponse)
def portal_cancel(appt_id: str, body: schemas.PortalCancel, db: Session = Depends(get_db),
                  patient: models.Patient = Depends(auth.get_current_patient)):
    appt = crud.get_appointment(db, appt_id)
    if not appt or appt.patient_id != patient.patient_id:
        raise HTTPException(status_code=404, detail="Appointment not found")
    return crud.update_appointment_status(db, appt_id, "Cancelled", f"patient:{patient.patient_id}",
                                          reason=body.reason or "Cancelled by patient")


@app.put("/api/v1/portal/appointments/{appt_id}/reschedule", response_model=schemas.AppointmentResponse)
def portal_reschedule(appt_id: str, body: schemas.AppointmentReschedule, db: Session = Depends(get_db),
                      patient: models.Patient = Depends(auth.get_current_patient)):
    appt = crud.get_appointment(db, appt_id)
    if not appt or appt.patient_id != patient.patient_id:
        raise HTTPException(status_code=404, detail="Appointment not found")
    return crud.reschedule_appointment(db, appt_id, body, f"patient:{patient.patient_id}")


@app.get("/api/v1/portal/me/invoices", response_model=list[schemas.InvoiceResponse])
def portal_my_invoices(db: Session = Depends(get_db),
                       patient: models.Patient = Depends(auth.get_current_patient)):
    return crud.get_invoices(db, patient.patient_id)


# --- Inventory Routes ---
@app.post("/api/v1/inventory", response_model=schemas.MedicineResponse)
def create_medicine(med: schemas.MedicineCreate, db: Session = Depends(get_db),
                    current_user: models.User = Depends(auth.require_receptionist)):
    clinic = crud.get_clinic(db, med.clinic_id)
    if not clinic:
        raise HTTPException(status_code=400, detail="Invalid clinic")
    return crud.create_medicine(db, med, current_user.user_id)


@app.get("/api/v1/inventory/stats", response_model=schemas.InventoryStatsResponse)
def get_inventory_stats(clinic_id: str, db: Session = Depends(get_db),
                        current_user: models.User = Depends(auth.require_any_user)):
    return crud.get_inventory_stats(db, clinic_id)


@app.get("/api/v1/inventory", response_model=list[schemas.MedicineResponse])
def list_medicines(clinic_id: Optional[str] = None, search: Optional[str] = None,
                   low_stock: Optional[bool] = None, near_expiry: Optional[bool] = None,
                   db: Session = Depends(get_db),
                   current_user: models.User = Depends(auth.require_any_user)):
    return crud.get_medicines(db, clinic_id, search, low_stock, near_expiry)


@app.put("/api/v1/inventory/{medicine_id}", response_model=schemas.MedicineResponse)
def update_medicine(medicine_id: str, data: schemas.MedicineUpdate,
                    db: Session = Depends(get_db),
                    current_user: models.User = Depends(auth.require_receptionist)):
    return crud.update_medicine(db, medicine_id, data, current_user.user_id)


@app.post("/api/v1/inventory/{medicine_id}/stock-inward", response_model=schemas.MedicineResponse)
def stock_inward(medicine_id: str, body: dict, db: Session = Depends(get_db),
                 current_user: models.User = Depends(auth.require_receptionist)):
    qty = body.get("quantity", 0)
    return crud.stock_inward(db, medicine_id, qty, current_user.user_id)
