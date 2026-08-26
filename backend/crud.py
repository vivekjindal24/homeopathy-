import re
from datetime import datetime, date, timedelta
from decimal import Decimal
from typing import Optional

from sqlalchemy.orm import Session, joinedload, selectinload
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy import or_

import models, schemas, auth

MONEY_QUANT = Decimal("0.01")


def _q(v) -> Decimal:
    return Decimal(str(v)).quantize(MONEY_QUANT)


# --- Audit Logging Helper (NFR-7) ---
def log_audit(db: Session, entity_type: str, entity_id: str, action: str,
              performed_by: str, before_data: dict = None, after_data: dict = None):
    log_entry = models.AuditLog(
        entity_type=entity_type,
        entity_id=entity_id,
        action=action,
        performed_by=performed_by,
        changes_json={"before": before_data or {}, "after": after_data or {}},
    )
    db.add(log_entry)
    db.commit()


def model_to_dict(model_instance) -> dict:
    if not model_instance:
        return {}
    res = {}
    for column in model_instance.__table__.columns:
        val = getattr(model_instance, column.name)
        if isinstance(val, (datetime, date)):
            res[column.name] = val.isoformat()
        elif isinstance(val, Decimal):
            res[column.name] = float(_q(val))
        else:
            res[column.name] = val
    return res


# --- Notifications outbox (§5.11) ---
def notify(db: Session, event: str, channel: str, recipient: str, body: str,
           patient_id: str = None, subject: str = None):
    row = models.NotificationLog(
        event=event, channel=channel, recipient=recipient,
        subject=subject, body=body, status="Queued", patient_id=patient_id,
    )
    db.add(row)
    db.commit()


# --- Clinic CRUD ---
def create_clinic(db: Session, clinic: schemas.ClinicCreate, user_id: str) -> models.Clinic:
    db_clinic = models.Clinic(**clinic.model_dump())
    db.add(db_clinic)
    db.commit()
    db.refresh(db_clinic)
    log_audit(db, "Clinic", db_clinic.clinic_id, "CREATE", user_id, after_data=model_to_dict(db_clinic))
    return db_clinic


def update_clinic(db: Session, clinic_id: str, data: schemas.ClinicUpdate, user_id: str) -> models.Clinic:
    clinic = get_clinic(db, clinic_id)
    if not clinic:
        raise HTTPException(status_code=404, detail="Clinic not found")
    before = model_to_dict(clinic)
    updates = data.model_dump(exclude_unset=True)
    for k, v in updates.items():
        setattr(clinic, k, v)
    db.commit()
    db.refresh(clinic)
    log_audit(db, "Clinic", clinic.clinic_id, "UPDATE", user_id,
              before_data=before, after_data=model_to_dict(clinic))
    return clinic


def get_clinics(db: Session) -> list[models.Clinic]:
    return db.query(models.Clinic).all()


def get_clinic(db: Session, clinic_id: str) -> Optional[models.Clinic]:
    return db.query(models.Clinic).filter(models.Clinic.clinic_id == clinic_id).first()


# --- User CRUD ---
def create_user(db: Session, user: schemas.UserCreate, creator_id: str = None) -> models.User:
    db_user = models.User(
        full_name=user.full_name,
        email=user.email,
        password_hash=auth.get_password_hash(user.password),
        role=user.role,
        clinic_ids=user.clinic_ids,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    if creator_id:
        log_audit(db, "User", db_user.user_id, "CREATE", creator_id, after_data=model_to_dict(db_user))
    return db_user


def get_user_by_email(db: Session, email: str) -> Optional[models.User]:
    return db.query(models.User).filter(models.User.email == email).first()


def get_users(db: Session) -> list[models.User]:
    return db.query(models.User).order_by(models.User.created_at.desc()).all()


def update_user(db: Session, user_id: str, data: schemas.UserUpdate, actor_id: str) -> models.User:
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    before = model_to_dict(user)
    for k, v in data.model_dump(exclude_unset=True).items():
        setattr(user, k, v)
    db.commit()
    db.refresh(user)
    log_audit(db, "User", user.user_id, "UPDATE", actor_id,
              before_data=before, after_data=model_to_dict(user))
    return user


def reset_password(db: Session, user_id: str, new_password: str, actor_id: str):
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.password_hash = auth.get_password_hash(new_password)
    auth.revoke_all_refresh_tokens(db, "user", user_id)
    log_audit(db, "User", user_id, "UPDATE", actor_id,
              after_data={"password": "reset"})


def delete_user(db: Session, user_id: str, actor_id: str):
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.user_id == actor_id:
        raise HTTPException(status_code=400, detail="Cannot delete your own account")
    before = model_to_dict(user)
    auth.revoke_all_refresh_tokens(db, "user", user_id)
    db.delete(user)
    db.commit()
    log_audit(db, "User", user_id, "DELETE", actor_id, before_data=before)


# --- Patient CRUD ---
def generate_unique_patient_id(db: Session) -> str:
    """Race-safe-enough sequential ID: VHC-YYYY-NNNN derived from max suffix."""
    year = datetime.now().year
    prefix = f"VHC-{year}-"
    rows = db.query(models.Patient.unique_patient_id).filter(
        models.Patient.unique_patient_id.like(f"{prefix}%")
    ).all()
    max_n = 1000
    for (uid,) in rows:
        m = re.match(rf"^{prefix}(\d+)$", uid or "")
        if m:
            max_n = max(max_n, int(m.group(1)))
    return f"{prefix}{max_n + 1}"


def create_patient(db: Session, patient: schemas.PatientCreate, user_id: str = None) -> models.Patient:
    # Idempotent on mobile: existing patient lookup (PRD §13.1 — mobile is the identifier)
    existing = get_patient_by_mobile(db, patient.mobile)
    if existing:
        return existing
    data = patient.model_dump()
    unique_id = generate_unique_patient_id(db)
    for attempt in range(3):
        try:
            db_patient = models.Patient(**data, unique_patient_id=unique_id)
            db.add(db_patient)
            db.commit()
            db.refresh(db_patient)
            break
        except IntegrityError:
            db.rollback()
            unique_id = generate_unique_patient_id(db)
    else:
        raise HTTPException(status_code=500, detail="Could not allocate a unique patient ID")
    if user_id:
        log_audit(db, "Patient", db_patient.patient_id, "CREATE", user_id, after_data=model_to_dict(db_patient))
    return db_patient


def get_patient_by_mobile(db: Session, mobile: str) -> Optional[models.Patient]:
    return db.query(models.Patient).filter(models.Patient.mobile == mobile).first()


def get_patients(db: Session, search: str = None) -> list[models.Patient]:
    query = db.query(models.Patient)
    if search:
        like = f"%{search}%"
        query = query.filter(
            (models.Patient.full_name.ilike(like))
            | (models.Patient.mobile.contains(search))
            | (models.Patient.unique_patient_id.ilike(like))
        )
    return query.order_by(models.Patient.created_at.desc()).all()


def get_patient(db: Session, patient_id: str) -> Optional[models.Patient]:
    return db.query(models.Patient).filter(models.Patient.patient_id == patient_id).first()


# --- 7-Day Consultation Fee Waiver Check (BR-3) ---
def check_7day_waiver_eligibility(db: Session, patient_id: str, appt_date_str: str) -> bool:
    try:
        current_date = date.fromisoformat(appt_date_str)
    except ValueError:
        return False

    last_appt = db.query(models.Appointment).filter(
        models.Appointment.patient_id == patient_id,
        models.Appointment.status == "Completed",
    ).order_by(models.Appointment.appt_date.desc()).first()

    if not last_appt:
        return False
    diff = (current_date - last_appt.appt_date).days
    return 0 <= diff <= 7


# --- Appointment CRUD ---
APPT_TRANSITIONS = {
    "Scheduled": {"Confirmed", "Cancelled"},
    "Confirmed": {"Arrived", "Cancelled", "Scheduled"},
    "Arrived": {"In Consultation", "No-Show", "Cancelled"},
    "In Consultation": {"Completed"},
    "Completed": set(),
    "No-Show": {"Confirmed"},   # allow re-booking flow via confirm
    "Cancelled": {"Scheduled"},
}


def next_token_number(db: Session, clinic_id: str, appt_date: date) -> int:
    max_tok = db.query(models.Appointment.token_number).filter(
        models.Appointment.clinic_id == clinic_id,
        models.Appointment.appt_date == appt_date,
    ).all()
    vals = [t for (t,) in max_tok if t]
    return (max(vals) + 1) if vals else 1


def create_appointment(db: Session, appt: schemas.AppointmentCreate, user_id: str) -> models.Appointment:
    doctor = db.query(models.User).filter(
        models.User.user_id == appt.doctor_id, models.User.is_active.is_(True)
    ).first()
    if not doctor:
        raise HTTPException(status_code=400, detail="Doctor not found or inactive")

    db_appt = models.Appointment(**appt.model_dump())
    db_appt.token_number = next_token_number(db, appt.clinic_id, appt.appt_date)
    db.add(db_appt)
    db.commit()
    db.refresh(db_appt)
    log_audit(db, "Appointment", db_appt.appt_id, "CREATE", user_id, after_data=model_to_dict(db_appt))

    patient = get_patient(db, db_appt.patient_id)
    notify(db, "appointment_booked", "SMS",
           patient.mobile if patient else "unknown",
           f"Appointment booked for {db_appt.appt_date} at {db_appt.appt_time}. Token #{db_appt.token_number}",
           patient_id=db_appt.patient_id)
    return db_appt


def get_appointments(db: Session, clinic_id: str = None, date_str: str = None) -> list[models.Appointment]:
    query = db.query(models.Appointment).options(joinedload(models.Appointment.patient))
    if clinic_id:
        query = query.filter(models.Appointment.clinic_id == clinic_id)
    if date_str:
        query = query.filter(models.Appointment.appt_date == date.fromisoformat(date_str))
    return query.order_by(models.Appointment.appt_time.asc()).all()


def get_appointment(db: Session, appt_id: str) -> Optional[models.Appointment]:
    return db.query(models.Appointment).options(joinedload(models.Appointment.patient)).filter(
        models.Appointment.appt_id == appt_id).first()


def update_appointment_status(db: Session, appt_id: str, status_update: str,
                              user_id: str, reason: str = None) -> models.Appointment:
    appt = get_appointment(db, appt_id)
    if not appt:
        raise HTTPException(status_code=404, detail="Appointment not found")

    if status_update == "Cancelled" and not reason:
        raise HTTPException(status_code=400, detail="A cancellation reason is required (BR-5)")

    allowed = APPT_TRANSITIONS.get(appt.status, set())
    if status_update != appt.status and status_update not in allowed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid transition: '{appt.status}' → '{status_update}'. Allowed: {sorted(allowed) or 'none'}",
        )

    # BR-2 / BR-12: single active consultation per clinic/day
    if status_update == "In Consultation":
        active_appt = db.query(models.Appointment).filter(
            models.Appointment.clinic_id == appt.clinic_id,
            models.Appointment.appt_date == appt.appt_date,
            models.Appointment.status == "In Consultation",
            models.Appointment.appt_id != appt_id,
        ).first()
        if active_appt:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Action blocked: Patient {active_appt.patient.full_name} is already in consultation.",
            )

    before = model_to_dict(appt)
    now = datetime.utcnow()
    if status_update == "Arrived":
        appt.waiting_started_at = now
    elif status_update == "In Consultation":
        appt.consultation_started_at = now
    appt.status = status_update
    if status_update == "Cancelled":
        appt.cancel_reason = reason
    db.commit()
    db.refresh(appt)
    log_audit(db, "Appointment", appt.appt_id, "UPDATE", user_id,
              before_data=before, after_data=model_to_dict(appt))

    events = {"Confirmed": "appointment_confirmed", "Cancelled": "appointment_cancelled"}
    if appt.status in events:
        notify(db, events[appt.status], "SMS", appt.patient.mobile,
               f"Your appointment on {appt.appt_date} is {appt.status.lower()}."
               + (f" Reason: {reason}" if reason else ""),
               patient_id=appt.patient_id)
    return appt


def reschedule_appointment(db: Session, appt_id: str, r: schemas.AppointmentReschedule,
                           user_id: str) -> models.Appointment:
    appt = get_appointment(db, appt_id)
    if not appt:
        raise HTTPException(status_code=404, detail="Appointment not found")
    if appt.status in ("Completed", "Cancelled"):
        raise HTTPException(status_code=400, detail=f"Cannot reschedule a {appt.status.lower()} appointment")
    if appt.status == "In Consultation":
        raise HTTPException(status_code=400, detail="Cannot reschedule while in consultation")

    before = model_to_dict(appt)
    appt.appt_date = r.appt_date
    appt.appt_time = r.appt_time
    appt.status = "Confirmed"
    db.commit()
    db.refresh(appt)
    log_audit(db, "Appointment", appt.appt_id, "UPDATE", user_id,
              before_data=before, after_data=model_to_dict(appt))
    notify(db, "appointment_rescheduled", "SMS", appt.patient.mobile,
           f"Appointment rescheduled to {r.appt_date} at {r.appt_time}.",
           patient_id=appt.patient_id)
    return appt


# --- Prescription CRUD ---
def create_prescription(db: Session, p: schemas.PrescriptionCreate, user_id: str) -> models.Prescription:
    appt = get_appointment(db, p.appt_id)
    if not appt:
        raise HTTPException(status_code=404, detail="Appointment not found")
    if appt.status not in ("In Consultation", "Arrived"):
        raise HTTPException(status_code=400,
                            detail=f"Prescription can only be written for an active consultation (current status: {appt.status})")
    if appt.patient_id != p.patient_id:
        raise HTTPException(status_code=400, detail="Patient does not match the appointment")

    db_rx = models.Prescription(
        appt_id=p.appt_id,
        patient_id=p.patient_id,
        chief_complaint=p.chief_complaint,
        diagnosis=p.diagnosis,
        medicines=[m.model_dump() for m in p.medicines],
        instructions=p.instructions,
        follow_up_date=p.follow_up_date,
        is_fee_waived=p.is_fee_waived,
    )
    db.add(db_rx)

    # §5.8.4: completing prescription completes the consultation; billing handoff follows
    appt.status = "Completed"
    db.commit()
    db.refresh(db_rx)
    log_audit(db, "Prescription", db_rx.prescription_id, "CREATE", user_id,
              after_data=model_to_dict(db_rx))
    return db_rx


def get_prescriptions_by_patient(db: Session, patient_id: str) -> list[models.Prescription]:
    return db.query(models.Prescription).filter(
        models.Prescription.patient_id == patient_id
    ).order_by(models.Prescription.created_at.desc()).all()


# --- Invoice CRUD (BR-10, BR-11, §5.5) ---
def compute_invoice_totals(fees: dict) -> dict:
    total = (_q(fees["consultation_fee"]) + _q(fees["medicine_charges"])
             + _q(fees["misc_charges"]) - _q(fees["discount"]))
    total = max(total, Decimal("0.00"))
    return {"total_amount": total.quantize(MONEY_QUANT), "due_amount": total.quantize(MONEY_QUANT)}


def create_invoice(db: Session, invoice: schemas.InvoiceCreate, user_id: str) -> models.Invoice:
    totals = compute_invoice_totals(invoice.model_dump())
    db_invoice = models.Invoice(
        patient_id=invoice.patient_id,
        appt_id=invoice.appt_id,
        consultation_fee=_q(invoice.consultation_fee),
        medicine_charges=_q(invoice.medicine_charges),
        misc_charges=_q(invoice.misc_charges),
        discount=_q(invoice.discount),
        total_amount=totals["total_amount"],
        paid_amount=Decimal("0.00"),
        due_amount=totals["due_amount"],
        status="Draft",
    )
    db.add(db_invoice)
    db.commit()
    db.refresh(db_invoice)
    log_audit(db, "Invoice", db_invoice.invoice_id, "CREATE", user_id, after_data=model_to_dict(db_invoice))
    return db_invoice


def get_invoices(db: Session, patient_id: str = None) -> list[models.Invoice]:
    query = db.query(models.Invoice).options(
        selectinload(models.Invoice.payments),
        selectinload(models.Invoice.patient),
    )
    if patient_id:
        query = query.filter(models.Invoice.patient_id == patient_id)
    return query.order_by(models.Invoice.updated_at.desc()).all()


def get_invoice(db: Session, invoice_id: str) -> Optional[models.Invoice]:
    return db.query(models.Invoice).options(
        selectinload(models.Invoice.payments),
        selectinload(models.Invoice.patient),
    ).filter(models.Invoice.invoice_id == invoice_id).first()


def issue_invoice(db: Session, invoice_id: str, user_id: str) -> models.Invoice:
    invoice = get_invoice(db, invoice_id)
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
    if invoice.status != "Draft":
        raise HTTPException(status_code=400, detail=f"Only Draft invoices can be issued (current: {invoice.status})")
    if invoice.total_amount <= 0:
        raise HTTPException(status_code=400, detail="Cannot issue an invoice with zero total")

    before = model_to_dict(invoice)
    invoice.status = "Issued"
    invoice.issued_at = datetime.utcnow()
    db.commit()
    db.refresh(invoice)
    log_audit(db, "Invoice", invoice.invoice_id, "UPDATE", user_id,
              before_data=before, after_data=model_to_dict(invoice))
    notify(db, "invoice_issued", "WhatsApp", invoice.patient.mobile,
           f"Invoice issued. Total ₹{invoice.total_amount}. Due ₹{invoice.due_amount}.",
           patient_id=invoice.patient_id)
    return invoice


# --- Payment CRUD (§5.6, BR-11) ---
def create_payment(db: Session, invoice_id: str, payment: schemas.PaymentCreate, user_id: str) -> models.Payment:
    invoice = get_invoice(db, invoice_id)
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
    if invoice.status not in ("Issued", "Partially Paid"):
        raise HTTPException(status_code=400,
                            detail=f"Payments allowed only on Issued/Partially Paid invoices (current: {invoice.status})")

    amount = _q(payment.amount)
    due = _q(invoice.due_amount)
    if amount > due:
        raise HTTPException(status_code=400,
                            detail=f"Payment ₹{amount} exceeds due amount ₹{due}")

    before_invoice = model_to_dict(invoice)
    db_payment = models.Payment(
        invoice_id=invoice_id,
        amount=amount,
        payment_mode=payment.payment_mode,
        transaction_id=payment.transaction_id,
        status="Success",
    )
    db.add(db_payment)

    invoice.paid_amount = (_q(invoice.paid_amount) + amount).quantize(MONEY_QUANT)
    invoice.due_amount = max(_q(invoice.total_amount) - invoice.paid_amount, Decimal("0.00"))
    invoice.status = "Paid" if invoice.due_amount <= 0 else "Partially Paid"

    db.commit()
    db.refresh(db_payment)
    db.refresh(invoice)

    log_audit(db, "Payment", db_payment.payment_id, "CREATE", user_id, after_data=model_to_dict(db_payment))
    log_audit(db, "Invoice", invoice.invoice_id, "UPDATE", user_id,
              before_data=before_invoice, after_data=model_to_dict(invoice))
    notify(db, "payment_received", "Email", invoice.patient.email or "-",
           f"Payment of ₹{amount} received. Remaining due ₹{invoice.due_amount}.",
           patient_id=invoice.patient_id)
    return db_payment


# --- Audit Logs ---
def get_audit_logs(db: Session, entity_type: str = None, action: str = None,
                   from_date: str = None, to_date: str = None) -> list[models.AuditLog]:
    query = db.query(models.AuditLog)
    if entity_type:
        query = query.filter(models.AuditLog.entity_type == entity_type)
    if action:
        query = query.filter(models.AuditLog.action == action)
    if from_date:
        query = query.filter(models.AuditLog.timestamp >= datetime.fromisoformat(from_date))
    if to_date:
        query = query.filter(models.AuditLog.timestamp <= datetime.fromisoformat(to_date + "T23:59:59"))
    return query.order_by(models.AuditLog.timestamp.desc()).limit(1000).all()


# --- Notifications ---
def get_notifications(db: Session) -> list[models.NotificationLog]:
    return db.query(models.NotificationLog).order_by(models.NotificationLog.created_at.desc()).limit(500).all()


# --- Dashboard KPIs ---
def get_avg_wait_minutes(db: Session, clinic_id: str, date_str: str) -> float:
    """Average wait time in minutes for completed/in-progress appointments on a given date.

    Wait duration = consultation_started_at - waiting_started_at.
    Only includes appointments where both timestamps are set.
    For currently waiting patients (no consultation_started_at yet), uses now().
    """
    d = date.fromisoformat(date_str)
    appts = db.query(models.Appointment).filter(
        models.Appointment.clinic_id == clinic_id,
        models.Appointment.appt_date == d,
        models.Appointment.waiting_started_at.isnot(None),
    ).all()
    if not appts:
        return 0.0
    durations = []
    now = datetime.utcnow()
    for a in appts:
        start = a.waiting_started_at
        if a.consultation_started_at is not None:
            end = a.consultation_started_at
        elif a.status == "Arrived":
            end = now  # still waiting, count elapsed time
        else:
            continue  # no valid end point
        diff = (end - start).total_seconds() / 60.0
        if diff >= 0:
            durations.append(diff)
    if not durations:
        return 0.0
    return round(sum(durations) / len(durations), 1)


def get_dashboard_kpis(db: Session, clinic_id: str, date_str: str) -> dict:
    d = date.fromisoformat(date_str)
    today_patients = db.query(models.Appointment.patient_id).filter(
        models.Appointment.clinic_id == clinic_id,
        models.Appointment.appt_date == d,
    ).distinct().count()

    active_queue = db.query(models.Appointment).filter(
        models.Appointment.clinic_id == clinic_id,
        models.Appointment.appt_date == d,
        models.Appointment.status.in_(["Arrived", "In Consultation"]),
    ).count()

    day_start = datetime(d.year, d.month, d.day)
    day_end = day_start + timedelta(days=1)
    payments = db.query(models.Payment).join(models.Invoice).join(models.Appointment).filter(
        models.Appointment.clinic_id == clinic_id,
        models.Payment.paid_at >= day_start,
        models.Payment.paid_at < day_end,
        models.Payment.status == "Success",
    ).all()
    today_revenue = sum((_q(p.amount) for p in payments), Decimal("0.00"))

    pending_dues_rows = db.query(models.Invoice).join(models.Appointment).filter(
        models.Appointment.clinic_id == clinic_id,
        models.Invoice.status.in_(["Issued", "Partially Paid"]),
    ).all()
    pending_dues = sum((_q(i.due_amount) for i in pending_dues_rows), Decimal("0.00"))

    low_stock_count = db.query(models.Medicine).filter(
        models.Medicine.clinic_id == clinic_id,
        models.Medicine.quantity < models.Medicine.low_stock_threshold,
    ).count()

    return {
        "today_patients": today_patients,
        "active_queue": active_queue,
        "today_revenue": today_revenue,
        "pending_dues": pending_dues,
        "avg_wait_minutes": get_avg_wait_minutes(db, clinic_id, date_str),
        "low_stock_alert": low_stock_count,
    }


# --- Reports (§5.10.4) ---
def report_revenue(db: Session, from_date: str, to_date: str, clinic_id: str = None) -> list[schemas.RevenuePoint]:
    start = datetime.fromisoformat(from_date)
    end = datetime.fromisoformat(to_date) + timedelta(days=1)
    q = db.query(models.Payment).filter(
        models.Payment.status == "Success",
        models.Payment.paid_at >= start,
        models.Payment.paid_at < end,
    )
    if clinic_id:
        q = q.join(models.Invoice).join(models.Appointment).filter(models.Appointment.clinic_id == clinic_id)
    buckets: dict[str, list] = {}
    for p in q.all():
        key = p.paid_at.date().isoformat()
        buckets.setdefault(key, []).append(p.amount)
    points = []
    for day in sorted(buckets):
        amounts = buckets[day]
        points.append(schemas.RevenuePoint(
            date=day,
            revenue=sum((_q(a) for a in amounts), Decimal("0.00")),
            payments_count=len(amounts),
        ))
    return points


def report_appointments(db: Session, from_date: str, to_date: str, clinic_id: str = None) -> schemas.AppointmentSummary:
    q = db.query(models.Appointment).filter(
        models.Appointment.appt_date >= date.fromisoformat(from_date),
        models.Appointment.appt_date <= date.fromisoformat(to_date),
    )
    if clinic_id:
        q = q.filter(models.Appointment.clinic_id == clinic_id)
    rows = q.all()
    counts: dict[str, int] = {}
    for a in rows:
        counts[a.status] = counts.get(a.status, 0) + 1
    return schemas.AppointmentSummary(
        total=len(rows),
        completed=counts.get("Completed", 0),
        cancelled=counts.get("Cancelled", 0),
        no_show=counts.get("No-Show", 0),
        scheduled=counts.get("Scheduled", 0),
        confirmed=counts.get("Confirmed", 0),
    )


def report_registrations(db: Session, months: int = 6) -> list[schemas.RegistrationPoint]:
    cutoff = datetime.utcnow() - timedelta(days=30 * months)
    patients = db.query(models.Patient).filter(models.Patient.created_at >= cutoff).all()
    buckets: dict[str, int] = {}
    for p in patients:
        key = p.created_at.strftime("%Y-%m")
        buckets[key] = buckets.get(key, 0) + 1
    return [schemas.RegistrationPoint(month=k, registrations=v) for k, v in sorted(buckets.items())]


# --- Portal helpers (§5.9) ---
def get_patient_appointments(db: Session, patient_id: str) -> list[models.Appointment]:
    return db.query(models.Appointment).options(joinedload(models.Appointment.patient)).filter(
        models.Appointment.patient_id == patient_id
    ).order_by(models.Appointment.appt_date.desc(), models.Appointment.appt_time.asc()).all()


# --- Inventory CRUD ---
NEAR_EXPIRY_DAYS = 90


def create_medicine(db: Session, med: schemas.MedicineCreate, user_id: str) -> models.Medicine:
    db_med = models.Medicine(
        name=med.name,
        manufacturer=med.manufacturer,
        batch_number=med.batch_number,
        quantity=med.quantity,
        unit_price=_q(med.unit_price),
        expiry_date=med.expiry_date,
        low_stock_threshold=med.low_stock_threshold,
        clinic_id=med.clinic_id,
    )
    db.add(db_med)
    db.commit()
    db.refresh(db_med)
    log_audit(db, "Medicine", db_med.medicine_id, "CREATE", user_id, after_data=model_to_dict(db_med))
    return db_med


def get_medicines(db: Session, clinic_id: str = None, search: str = None,
                  low_stock: bool = None, near_expiry: bool = None) -> list[models.Medicine]:
    query = db.query(models.Medicine)
    if clinic_id:
        query = query.filter(models.Medicine.clinic_id == clinic_id)
    if search:
        like = f"%{search}%"
        query = query.filter(
            or_(
                models.Medicine.name.ilike(like),
                models.Medicine.manufacturer.ilike(like),
                models.Medicine.batch_number.ilike(like),
            )
        )
    today = date.today()
    if low_stock:
        query = query.filter(models.Medicine.quantity <= models.Medicine.low_stock_threshold)
    if near_expiry:
        cutoff = (today + timedelta(days=NEAR_EXPIRY_DAYS)).isoformat()
        query = query.filter(
            models.Medicine.expiry_date.isnot(None),
            models.Medicine.expiry_date <= cutoff,
        )
    return query.order_by(models.Medicine.name.asc()).all()


def update_medicine(db: Session, medicine_id: str, data: schemas.MedicineUpdate,
                    user_id: str) -> models.Medicine:
    med = db.query(models.Medicine).filter(models.Medicine.medicine_id == medicine_id).first()
    if not med:
        raise HTTPException(status_code=404, detail="Medicine not found")
    before = model_to_dict(med)
    for k, v in data.model_dump(exclude_unset=True).items():
        if k == "unit_price":
            v = _q(v)
        setattr(med, k, v)
    db.commit()
    db.refresh(med)
    log_audit(db, "Medicine", med.medicine_id, "UPDATE", user_id,
              before_data=before, after_data=model_to_dict(med))
    return med


def stock_inward(db: Session, medicine_id: str, quantity: int, user_id: str) -> models.Medicine:
    med = db.query(models.Medicine).filter(models.Medicine.medicine_id == medicine_id).first()
    if not med:
        raise HTTPException(status_code=404, detail="Medicine not found")
    if quantity <= 0:
        raise HTTPException(status_code=400, detail="Quantity must be positive")
    before = model_to_dict(med)
    med.quantity += quantity
    db.commit()
    db.refresh(med)
    log_audit(db, "Medicine", med.medicine_id, "UPDATE", user_id,
              before_data=before, after_data=model_to_dict(med))
    return med


def get_inventory_stats(db: Session, clinic_id: str) -> dict:
    query = db.query(models.Medicine).filter(models.Medicine.clinic_id == clinic_id)
    today = date.today()
    cutoff = (today + timedelta(days=NEAR_EXPIRY_DAYS)).isoformat()
    all_meds = query.all()
    low_stock_count = sum(1 for m in all_meds if m.quantity <= m.low_stock_threshold)
    near_expiry_count = sum(
        1 for m in all_meds
        if m.expiry_date and m.expiry_date <= cutoff
    )
    return {
        "low_stock_count": low_stock_count,
        "near_expiry_count": near_expiry_count,
        "total_medicines": len(all_meds),
    }
