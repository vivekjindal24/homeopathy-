from datetime import datetime, date
import json
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
import models, schemas, auth

# --- Audit Logging Helper ---
def log_audit(db: Session, entity_type: str, entity_id: str, action: str, performed_by: str, before_data: dict = None, after_data: dict = None):
    changes = {
        "before": before_data or {},
        "after": after_data or {}
    }
    log_entry = models.AuditLog(
        entity_type=entity_type,
        entity_id=entity_id,
        action=action,
        performed_by=performed_by,
        changes_json=changes
    )
    db.add(log_entry)
    db.commit()

# Helper to serialize SQLAlchemy model to dict for audit logs
def model_to_dict(model_instance) -> dict:
    if not model_instance:
        return {}
    res = {}
    for column in model_instance.__table__.columns:
        val = getattr(model_instance, column.name)
        if isinstance(val, (datetime, date)):
            res[column.name] = val.isoformat()
        else:
            res[column.name] = val
    return res

# --- Clinic CRUD ---
def create_clinic(db: Session, clinic: schemas.ClinicCreate, user_id: str) -> models.Clinic:
    db_clinic = models.Clinic(**clinic.model_dump())
    db.add(db_clinic)
    db.commit()
    db.refresh(db_clinic)
    log_audit(db, "Clinic", db_clinic.clinic_id, "CREATE", user_id, after_data=model_to_dict(db_clinic))
    return db_clinic

def get_clinics(db: Session) -> list[models.Clinic]:
    return db.query(models.Clinic).all()

def get_clinic(db: Session, clinic_id: str) -> models.Clinic:
    return db.query(models.Clinic).filter(models.Clinic.clinic_id == clinic_id).first()

# --- User CRUD ---
def create_user(db: Session, user: schemas.UserCreate, creator_id: str = None) -> models.User:
    db_user = models.User(
        full_name=user.full_name,
        email=user.email,
        password_hash=auth.get_password_hash(user.password),
        role=user.role,
        clinic_ids=user.clinic_ids
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    if creator_id:
        log_audit(db, "User", db_user.user_id, "CREATE", creator_id, after_data=model_to_dict(db_user))
    return db_user

def get_user_by_email(db: Session, email: str) -> models.User:
    return db.query(models.User).filter(models.User.email == email).first()

def get_users(db: Session) -> list[models.User]:
    return db.query(models.User).all()

# --- Patient CRUD ---
def create_patient(db: Session, patient: schemas.PatientCreate, user_id: str) -> models.Patient:
    # Auto-generate a human-readable unique patient ID (e.g. VHC-2026-0001)
    count = db.query(models.Patient).count()
    unique_id = f"VHC-{datetime.now().year}-{1000 + count + 1}"
    
    db_patient = models.Patient(
        **patient.model_dump(),
        unique_patient_id=unique_id
    )
    db.add(db_patient)
    db.commit()
    db.refresh(db_patient)
    log_audit(db, "Patient", db_patient.patient_id, "CREATE", user_id, after_data=model_to_dict(db_patient))
    return db_patient

def get_patients(db: Session, search: str = None) -> list[models.Patient]:
    query = db.query(models.Patient)
    if search:
        query = query.filter(
            (models.Patient.full_name.icontains(search)) |
            (models.Patient.mobile.contains(search)) |
            (models.Patient.unique_patient_id.icontains(search))
        )
    return query.order_by(models.Patient.created_at.desc()).all()

def get_patient(db: Session, patient_id: str) -> models.Patient:
    return db.query(models.Patient).filter(models.Patient.patient_id == patient_id).first()

# --- 7-Day Consultation Fee Waiver Check ---
def check_7day_waiver_eligibility(db: Session, patient_id: str, appt_date_str: str) -> bool:
    try:
        current_date = datetime.strptime(appt_date_str, "%Y-%m-%d").date()
    except ValueError:
        return False
        
    # Get last completed consultation for this patient
    last_appt = db.query(models.Appointment).filter(
        models.Appointment.patient_id == patient_id,
        models.Appointment.status == "Completed"
    ).order_by(models.Appointment.appt_date.desc()).first()
    
    if not last_appt:
        return False
        
    try:
        last_date = datetime.strptime(last_appt.appt_date, "%Y-%m-%d").date()
        diff = (current_date - last_date).days
        return 0 <= diff <= 7
    except ValueError:
        return False

# --- Appointment CRUD ---
def create_appointment(db: Session, appt: schemas.AppointmentCreate, user_id: str) -> models.Appointment:
    db_appt = models.Appointment(**appt.model_dump())
    db.add(db_appt)
    db.commit()
    db.refresh(db_appt)
    log_audit(db, "Appointment", db_appt.appt_id, "CREATE", user_id, after_data=model_to_dict(db_appt))
    return db_appt

def get_appointments(db: Session, clinic_id: str = None, date_str: str = None) -> list[models.Appointment]:
    query = db.query(models.Appointment)
    if clinic_id:
        query = query.filter(models.Appointment.clinic_id == clinic_id)
    if date_str:
        query = query.filter(models.Appointment.appt_date == date_str)
    return query.order_by(models.Appointment.appt_time.asc()).all()

def get_appointment(db: Session, appt_id: str) -> models.Appointment:
    return db.query(models.Appointment).filter(models.Appointment.appt_id == appt_id).first()

def update_appointment_status(db: Session, appt_id: str, status_update: str, user_id: str) -> models.Appointment:
    appt = db.query(models.Appointment).filter(models.Appointment.appt_id == appt_id).first()
    if not appt:
        raise HTTPException(status_code=404, detail="Appointment not found")
        
    before = model_to_dict(appt)
    
    # Enforce Single Active Consultation Rule
    if status_update == "In Consultation":
        active_appt = db.query(models.Appointment).filter(
            models.Appointment.clinic_id == appt.clinic_id,
            models.Appointment.appt_date == appt.appt_date,
            models.Appointment.status == "In Consultation",
            models.Appointment.appt_id != appt_id
        ).first()
        if active_appt:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Action blocked: Patient {active_appt.patient.full_name} is already in consultation with the doctor."
            )
            
    appt.status = status_update
    db.commit()
    db.refresh(appt)
    log_audit(db, "Appointment", appt.appt_id, "UPDATE", user_id, before_data=before, after_data=model_to_dict(appt))
    return appt

def reschedule_appointment(db: Session, appt_id: str, reschedule_data: schemas.AppointmentReschedule, user_id: str) -> models.Appointment:
    appt = db.query(models.Appointment).filter(models.Appointment.appt_id == appt_id).first()
    if not appt:
        raise HTTPException(status_code=404, detail="Appointment not found")
        
    before = model_to_dict(appt)
    appt.appt_date = reschedule_data.appt_date
    appt.appt_time = reschedule_data.appt_time
    appt.status = "Confirmed"  # Automatically confirm on reschedule
    
    db.commit()
    db.refresh(appt)
    log_audit(db, "Appointment", appt.appt_id, "UPDATE", user_id, before_data=before, after_data=model_to_dict(appt))
    return appt

# --- Prescription CRUD ---
def create_prescription(db: Session, prescription: schemas.PrescriptionCreate, user_id: str) -> models.Prescription:
    db_rx = models.Prescription(
        appt_id=prescription.appt_id,
        patient_id=prescription.patient_id,
        chief_complaint=prescription.chief_complaint,
        diagnosis=prescription.diagnosis,
        medicines=[m.model_dump() for m in prescription.medicines],
        instructions=prescription.instructions,
        follow_up_date=prescription.follow_up_date,
        is_fee_waived=prescription.is_fee_waived
    )
    db.add(db_rx)
    
    # Automatically update appointment to Completed
    appt = db.query(models.Appointment).filter(models.Appointment.appt_id == prescription.appt_id).first()
    if appt:
        appt.status = "Completed"
        
    db.commit()
    db.refresh(db_rx)
    log_audit(db, "Prescription", db_rx.prescription_id, "CREATE", user_id, after_data=model_to_dict(db_rx))
    return db_rx

def get_prescriptions_by_patient(db: Session, patient_id: str) -> list[models.Prescription]:
    return db.query(models.Prescription).filter(models.Prescription.patient_id == patient_id).order_by(models.Prescription.created_at.desc()).all()

# --- Invoice CRUD ---
def create_invoice(db: Session, invoice: schemas.InvoiceCreate, user_id: str) -> models.Invoice:
    # Compute totals
    total = invoice.consultation_fee + invoice.medicine_charges + invoice.misc_charges - invoice.discount
    due = total
    
    db_invoice = models.Invoice(
        patient_id=invoice.patient_id,
        appt_id=invoice.appt_id,
        consultation_fee=invoice.consultation_fee,
        medicine_charges=invoice.medicine_charges,
        misc_charges=invoice.misc_charges,
        discount=invoice.discount,
        total_amount=total,
        paid_amount=0.0,
        due_amount=due,
        status="Draft"
    )
    db.add(db_invoice)
    db.commit()
    db.refresh(db_invoice)
    log_audit(db, "Invoice", db_invoice.invoice_id, "CREATE", user_id, after_data=model_to_dict(db_invoice))
    return db_invoice

def get_invoices(db: Session, patient_id: str = None) -> list[models.Invoice]:
    query = db.query(models.Invoice)
    if patient_id:
        query = query.filter(models.Invoice.patient_id == patient_id)
    return query.order_by(models.Invoice.updated_at.desc()).all()

def get_invoice(db: Session, invoice_id: str) -> models.Invoice:
    return db.query(models.Invoice).filter(models.Invoice.invoice_id == invoice_id).first()

def issue_invoice(db: Session, invoice_id: str, user_id: str) -> models.Invoice:
    invoice = db.query(models.Invoice).filter(models.Invoice.invoice_id == invoice_id).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
    before = model_to_dict(invoice)
    invoice.status = "Issued"
    invoice.issued_at = datetime.utcnow()
    db.commit()
    db.refresh(invoice)
    log_audit(db, "Invoice", invoice.invoice_id, "UPDATE", user_id, before_data=before, after_data=model_to_dict(invoice))
    return invoice

# --- Payment CRUD ---
def create_payment(db: Session, invoice_id: str, payment: schemas.PaymentCreate, user_id: str) -> models.Payment:
    invoice = db.query(models.Invoice).filter(models.Invoice.invoice_id == invoice_id).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
        
    before_invoice = model_to_dict(invoice)
    
    # Record payment
    db_payment = models.Payment(
        invoice_id=invoice_id,
        amount=payment.amount,
        payment_mode=payment.payment_mode,
        transaction_id=payment.transaction_id,
        status="Success"
    )
    db.add(db_payment)
    
    # Update invoice paid and due amounts
    invoice.paid_amount += payment.amount
    invoice.due_amount = max(0.0, invoice.total_amount - invoice.paid_amount)
    
    if invoice.due_amount <= 0:
        invoice.status = "Paid"
    else:
        invoice.status = "Partially Paid"
        
    db.commit()
    db.refresh(db_payment)
    db.refresh(invoice)
    
    log_audit(db, "Payment", db_payment.payment_id, "CREATE", user_id, after_data=model_to_dict(db_payment))
    log_audit(db, "Invoice", invoice.invoice_id, "UPDATE", user_id, before_data=before_invoice, after_data=model_to_dict(invoice))
    
    return db_payment

# --- Audit Logs ---
def get_audit_logs(db: Session) -> list[models.AuditLog]:
    return db.query(models.AuditLog).order_by(models.AuditLog.timestamp.desc()).all()

# --- Dashboard Stats ---
def get_dashboard_kpis(db: Session, clinic_id: str, date_str: str) -> dict:
    # Today's Patients (distinct patients who had appointments today)
    today_patients = db.query(models.Appointment.patient_id).filter(
        models.Appointment.clinic_id == clinic_id,
        models.Appointment.appt_date == date_str
    ).distinct().count()
    
    # Active Queue: Patients in Waiting or In Consultation state today
    active_queue = db.query(models.Appointment).filter(
        models.Appointment.clinic_id == clinic_id,
        models.Appointment.appt_date == date_str,
        models.Appointment.status.in_(["Waiting", "In Consultation"])
    ).count()
    
    # Today's Revenue: Sum of payments collected today
    # Note: for simplicity, query payments where paid_at date matches date_str
    today_start = datetime.strptime(date_str, "%Y-%m-%d")
    today_end = today_start.replace(hour=23, minute=59, second=59)
    
    today_revenue_q = db.query(models.Payment).join(models.Invoice).join(models.Appointment).filter(
        models.Appointment.clinic_id == clinic_id,
        models.Payment.paid_at >= today_start,
        models.Payment.paid_at <= today_end,
        models.Payment.status == "Success"
    ).all()
    today_revenue = sum(p.amount for p in today_revenue_q)
    
    # Pending Dues: Sum of due_amount on issued/partially paid invoices linked to this clinic
    pending_dues_q = db.query(models.Invoice).join(models.Appointment).filter(
        models.Appointment.clinic_id == clinic_id,
        models.Invoice.status.in_(["Issued", "Partially Paid"])
    ).all()
    pending_dues = sum(inv.due_amount for inv in pending_dues_q)
    
    return {
        "today_patients": today_patients,
        "active_queue": active_queue,
        "today_revenue": today_revenue,
        "pending_dues": pending_dues,
        "low_stock_alert": 3 # Hardcoded placeholder for stock metric
    }
