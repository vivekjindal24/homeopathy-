from datetime import datetime
import os
from typing import Optional, List
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from database import engine, Base, get_db
import models, schemas, crud, auth

# Initialize database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Verma Homeopathy Clinic OS API",
    version="1.0.0",
    docs_url="/api/v1/docs",
    openapi_url="/api/v1/openapi.json"
)

# Set up CORS middleware to allow connection from the Flutter Web client
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all hosts for deployment/demo, can restrict later
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Seed initial data on startup if database is empty
@app.on_event("startup")
def seed_data():
    db = next(get_db())
    try:
        # 1. Seed Clinics
        if db.query(models.Clinic).count() == 0:
            clinic_a = models.Clinic(
                name="Vijay Nagar Branch (Clinic A)",
                address="102, Orbit Mall, Vijay Nagar, Indore, MP",
                timing_start="09:00",
                timing_end="13:00"
            )
            clinic_b = models.Clinic(
                name="Palasia Branch (Clinic B)",
                address="5, Saket Nagar Main Rd, Palasia, Indore, MP",
                timing_start="17:00",
                timing_end="21:00"
            )
            db.add(clinic_a)
            db.add(clinic_b)
            db.commit()
            db.refresh(clinic_a)
            db.refresh(clinic_b)
            
            # 2. Seed Users (SuperAdmin, Receptionist, Doctor)
            if db.query(models.User).count() == 0:
                # Super Admin
                super_admin = models.User(
                    full_name="Dr. Vishvesh Kumar Verma",
                    email="admin@vermahomeopathy.com",
                    password_hash=auth.get_password_hash("admin123"),
                    role="SuperAdmin",
                    clinic_ids=[clinic_a.clinic_id, clinic_b.clinic_id]
                )
                # Doctor
                doctor = models.User(
                    full_name="Dr. Vishvesh Kumar Verma (Doctor)",
                    email="doctor@vermahomeopathy.com",
                    password_hash=auth.get_password_hash("doctor123"),
                    role="Doctor",
                    clinic_ids=[clinic_a.clinic_id, clinic_b.clinic_id]
                )
                # Receptionist
                receptionist = models.User(
                    full_name="Vijay Front Desk",
                    email="receptionist@vermahomeopathy.com",
                    password_hash=auth.get_password_hash("frontdesk123"),
                    role="Receptionist",
                    clinic_ids=[clinic_a.clinic_id, clinic_b.clinic_id]
                )
                db.add(super_admin)
                db.add(doctor)
                db.add(receptionist)
                db.commit()
    finally:
        db.close()

# --- Auth Routes ---
@app.post("/api/v1/auth/login", response_model=schemas.Token)
def login(login_req: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = crud.get_user_by_email(db, login_req.email)
    if not user or not auth.verify_password(login_req.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = auth.create_access_token(data={"sub": user.email})
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": user.role,
        "full_name": user.full_name,
        "user_id": user.user_id
    }

@app.post("/api/v1/auth/register", response_model=schemas.UserResponse)
def register_user(user: schemas.UserCreate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_admin)):
    existing = crud.get_user_by_email(db, user.email)
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    return crud.create_user(db, user, current_user.user_id)

@app.get("/api/v1/users/me", response_model=schemas.UserResponse)
def get_me(current_user: models.User = Depends(auth.get_current_user)):
    return current_user

# --- Clinic Routes ---
@app.post("/api/v1/clinics", response_model=schemas.ClinicResponse)
def create_clinic(clinic: schemas.ClinicCreate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_admin)):
    return crud.create_clinic(db, clinic, current_user.user_id)

@app.get("/api/v1/clinics", response_model=list[schemas.ClinicResponse])
def get_clinics(db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_any_user)):
    return crud.get_clinics(db)

# --- Patient Routes ---
@app.post("/api/v1/patients", response_model=schemas.PatientResponse)
def create_patient(patient: schemas.PatientCreate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_receptionist)):
    return crud.create_patient(db, patient, current_user.user_id)

@app.get("/api/v1/patients", response_model=list[schemas.PatientResponse])
def get_patients(search: Optional[str] = None, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_any_user)):
    return crud.get_patients(db, search)

@app.get("/api/v1/patients/{patient_id}", response_model=schemas.PatientResponse)
def get_patient(patient_id: str, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_any_user)):
    p = crud.get_patient(db, patient_id)
    if not p:
        raise HTTPException(status_code=404, detail="Patient not found")
    return p

@app.get("/api/v1/patients/{patient_id}/7day-waiver")
def check_waiver(patient_id: str, appt_date: str, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_any_user)):
    eligible = crud.check_7day_waiver_eligibility(db, patient_id, appt_date)
    return {"eligible": eligible}

# --- Appointment Routes ---
@app.post("/api/v1/appointments", response_model=schemas.AppointmentResponse)
def create_appointment(appt: schemas.AppointmentCreate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_receptionist)):
    return crud.create_appointment(db, appt, current_user.user_id)

@app.get("/api/v1/appointments", response_model=list[schemas.AppointmentResponse])
def get_appointments(clinic_id: Optional[str] = None, appt_date: Optional[str] = None, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_any_user)):
    appts = crud.get_appointments(db, clinic_id, appt_date)
    # Populate patient object in response
    for a in appts:
        a.patient = crud.get_patient(db, a.patient_id)
    return appts

@app.put("/api/v1/appointments/{appt_id}/status", response_model=schemas.AppointmentResponse)
def update_appt_status(appt_id: str, update: schemas.AppointmentStatusUpdate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_any_user)):
    return crud.update_appointment_status(db, appt_id, update.status, current_user.user_id)

@app.put("/api/v1/appointments/{appt_id}/reschedule", response_model=schemas.AppointmentResponse)
def reschedule_appt(appt_id: str, reschedule: schemas.AppointmentReschedule, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_receptionist)):
    return crud.reschedule_appointment(db, appt_id, reschedule, current_user.user_id)

# --- Prescription Routes ---
@app.post("/api/v1/prescriptions", response_model=schemas.PrescriptionResponse)
def create_prescription(rx: schemas.PrescriptionCreate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_doctor)):
    return crud.create_prescription(db, rx, current_user.user_id)

@app.get("/api/v1/patients/{patient_id}/prescriptions", response_model=list[schemas.PrescriptionResponse])
def get_patient_prescriptions(patient_id: str, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_any_user)):
    return crud.get_prescriptions_by_patient(db, patient_id)

# --- Invoice Routes ---
@app.post("/api/v1/invoices", response_model=schemas.InvoiceResponse)
def create_invoice(invoice: schemas.InvoiceCreate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_receptionist)):
    inv = crud.create_invoice(db, invoice, current_user.user_id)
    inv.patient = crud.get_patient(db, inv.patient_id)
    return inv

@app.get("/api/v1/invoices", response_model=list[schemas.InvoiceResponse])
def get_invoices(patient_id: Optional[str] = None, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_any_user)):
    invoices = crud.get_invoices(db, patient_id)
    for inv in invoices:
        inv.patient = crud.get_patient(db, inv.patient_id)
        # Fetch payment models
        inv.payments = db.query(models.Payment).filter(models.Payment.invoice_id == inv.invoice_id).all()
    return invoices

@app.get("/api/v1/invoices/{invoice_id}", response_model=schemas.InvoiceResponse)
def get_invoice(invoice_id: str, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_any_user)):
    inv = crud.get_invoice(db, invoice_id)
    if not inv:
        raise HTTPException(status_code=404, detail="Invoice not found")
    inv.patient = crud.get_patient(db, inv.patient_id)
    inv.payments = db.query(models.Payment).filter(models.Payment.invoice_id == inv.invoice_id).all()
    return inv

@app.put("/api/v1/invoices/{invoice_id}/issue", response_model=schemas.InvoiceResponse)
def issue_invoice(invoice_id: str, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_receptionist)):
    return crud.issue_invoice(db, invoice_id, current_user.user_id)

@app.post("/api/v1/invoices/{invoice_id}/payments", response_model=schemas.PaymentResponse)
def record_payment(invoice_id: str, payment: schemas.PaymentCreate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_receptionist)):
    return crud.create_payment(db, invoice_id, payment, current_user.user_id)

# --- Audit Log Routes ---
@app.get("/api/v1/audit-logs", response_model=list[schemas.AuditLogResponse])
def get_audit_logs(db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_admin)):
    return crud.get_audit_logs(db)

# --- Dashboard Routes ---
@app.get("/api/v1/dashboard/kpis", response_model=schemas.KpisResponse)
def get_kpis(clinic_id: str, date_str: str, db: Session = Depends(get_db), current_user: models.User = Depends(auth.require_any_user)):
    return crud.get_dashboard_kpis(db, clinic_id, date_str)
