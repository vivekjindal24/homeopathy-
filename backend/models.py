import uuid
from datetime import datetime

from sqlalchemy import (
    Column, String, Integer, DateTime, Date, Boolean, ForeignKey,
    Numeric, Enum as SAEnum, JSON,
)
from sqlalchemy.orm import relationship

from database import Base


def generate_uuid():
    return str(uuid.uuid4())


# Canonical enums (PRD §5.3.2, §5.5.4, §3, §5.6.3, §9)
AppointmentStatus = SAEnum(
    "Scheduled", "Confirmed", "Arrived", "In Consultation",
    "Completed", "No-Show", "Cancelled",
    name="appointment_status", native_enum=False,
)
InvoiceStatus = SAEnum(
    "Draft", "Issued", "Partially Paid", "Paid",
    name="invoice_status", native_enum=False,
)
UserRole = SAEnum("Receptionist", "Doctor", "Patient", "SuperAdmin", name="user_role", native_enum=False)
VisitType = SAEnum("New", "Follow-Up", "Walk-In", name="visit_type", native_enum=False)
Gender = SAEnum("M", "F", "Other", name="gender", native_enum=False)
PaymentMode = SAEnum("Cash", "Card", "UPI", "Online", name="payment_mode", native_enum=False)
PaymentStatus = SAEnum("Success", "Pending", "Failed", name="payment_status", native_enum=False)


class User(Base):
    __tablename__ = "users"

    user_id = Column(String(36), primary_key=True, default=generate_uuid)
    full_name = Column(String(200), nullable=False)
    email = Column(String(200), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    role = Column(UserRole, nullable=False)
    clinic_ids = Column(JSON, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class Clinic(Base):
    __tablename__ = "clinics"

    clinic_id = Column(String(36), primary_key=True, default=generate_uuid)
    name = Column(String(200), nullable=False)
    address = Column(String(500), nullable=False)
    timing_start = Column(String(10), nullable=False)  # "HH:MM"
    timing_end = Column(String(10), nullable=False)    # "HH:MM"
    timezone = Column(String(50), default="Asia/Kolkata")
    consultation_fee = Column(Numeric(10, 2), nullable=False, default=500)


class Patient(Base):
    __tablename__ = "patients"

    patient_id = Column(String(36), primary_key=True, default=generate_uuid)
    full_name = Column(String(200), nullable=False, index=True)
    dob = Column(Date, nullable=False)
    gender = Column(Gender, nullable=False)
    mobile = Column(String(15), nullable=False, index=True)
    address = Column(String(500), nullable=False)
    occupation = Column(String(100), nullable=False)
    unique_patient_id = Column(String(20), unique=True, nullable=False, index=True)
    email = Column(String(200), nullable=True)
    blood_group = Column(String(5), nullable=True)
    emergency_contact = Column(String(200), nullable=True)
    allergies = Column(String(1000), nullable=True)
    chronic_conditions = Column(String(1000), nullable=True)
    referred_by = Column(String(200), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    appointments = relationship("Appointment", back_populates="patient", cascade="all, delete-orphan")
    invoices = relationship("Invoice", back_populates="patient", cascade="all, delete-orphan")


class Appointment(Base):
    __tablename__ = "appointments"

    appt_id = Column(String(36), primary_key=True, default=generate_uuid)
    patient_id = Column(String(36), ForeignKey("patients.patient_id"), nullable=False)
    doctor_id = Column(String(36), ForeignKey("users.user_id"), nullable=False)
    clinic_id = Column(String(36), ForeignKey("clinics.clinic_id"), nullable=False)
    appt_date = Column(Date, nullable=False, index=True)
    appt_time = Column(String(10), nullable=False)
    visit_type = Column(VisitType, nullable=False)
    status = Column(AppointmentStatus, nullable=False, default="Scheduled")
    notes = Column(String(1000), nullable=True)
    cancel_reason = Column(String(500), nullable=True)
    token_number = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    patient = relationship("Patient", back_populates="appointments")
    clinic = relationship("Clinic")
    doctor = relationship("User")
    invoices = relationship("Invoice", back_populates="appointment")
    prescriptions = relationship("Prescription", back_populates="appointment", cascade="all, delete-orphan")


class Prescription(Base):
    __tablename__ = "prescriptions"

    prescription_id = Column(String(36), primary_key=True, default=generate_uuid)
    appt_id = Column(String(36), ForeignKey("appointments.appt_id"), nullable=False)
    patient_id = Column(String(36), ForeignKey("patients.patient_id"), nullable=False)
    chief_complaint = Column(String(2000), nullable=False)
    diagnosis = Column(String(1000), nullable=False)
    medicines = Column(JSON, nullable=False)
    instructions = Column(String(2000), nullable=True)
    follow_up_date = Column(Date, nullable=True)
    is_fee_waived = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    appointment = relationship("Appointment", back_populates="prescriptions")


class Invoice(Base):
    __tablename__ = "invoices"

    invoice_id = Column(String(36), primary_key=True, default=generate_uuid)
    patient_id = Column(String(36), ForeignKey("patients.patient_id"), nullable=False)
    appt_id = Column(String(36), ForeignKey("appointments.appt_id"), nullable=True)
    consultation_fee = Column(Numeric(10, 2), nullable=False, default=0)
    medicine_charges = Column(Numeric(10, 2), nullable=False, default=0)
    misc_charges = Column(Numeric(10, 2), nullable=False, default=0)
    discount = Column(Numeric(10, 2), nullable=False, default=0)
    total_amount = Column(Numeric(10, 2), nullable=False, default=0)
    paid_amount = Column(Numeric(10, 2), nullable=False, default=0)
    due_amount = Column(Numeric(10, 2), nullable=False, default=0)
    status = Column(InvoiceStatus, nullable=False, default="Draft")
    issued_at = Column(DateTime, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    patient = relationship("Patient", back_populates="invoices")
    appointment = relationship("Appointment", back_populates="invoices")
    payments = relationship("Payment", back_populates="invoice", cascade="all, delete-orphan")


class Payment(Base):
    __tablename__ = "payments"

    payment_id = Column(String(36), primary_key=True, default=generate_uuid)
    invoice_id = Column(String(36), ForeignKey("invoices.invoice_id"), nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    payment_mode = Column(PaymentMode, nullable=False)
    transaction_id = Column(String(200), nullable=True)
    status = Column(PaymentStatus, nullable=False, default="Success")
    paid_at = Column(DateTime, default=datetime.utcnow)

    invoice = relationship("Invoice", back_populates="payments")


class AuditLog(Base):
    __tablename__ = "audit_logs"

    log_id = Column(String(36), primary_key=True, default=generate_uuid)
    entity_type = Column(String(50), nullable=False, index=True)
    entity_id = Column(String(36), nullable=False, index=True)
    action = Column(SAEnum("CREATE", "UPDATE", "DELETE", name="audit_action", native_enum=False), nullable=False)
    performed_by = Column(String(36), ForeignKey("users.user_id"), nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    changes_json = Column(JSON, nullable=False)


class OTPCode(Base):
    """Short-lived OTP codes for patient portal login (mobile-first auth)."""
    __tablename__ = "otp_codes"

    otp_id = Column(String(36), primary_key=True, default=generate_uuid)
    mobile = Column(String(15), nullable=False, index=True)
    code_hash = Column(String(255), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    consumed = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class RefreshToken(Base):
    """Rotating refresh tokens (NFR-5): one-time use, revocable."""
    __tablename__ = "refresh_tokens"

    token_id = Column(String(36), primary_key=True, default=generate_uuid)
    principal_type = Column(SAEnum("user", "patient", name="principal_type", native_enum=False), nullable=False)
    principal_id = Column(String(36), nullable=False, index=True)
    family_id = Column(String(36), nullable=False, index=True, default=generate_uuid)
    token_hash = Column(String(255), nullable=False, index=True, unique=True)
    expires_at = Column(DateTime, nullable=False)
    revoked = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class NotificationLog(Base):
    """Notification outbox (§5.11): every trigger recorded here; providers deliver later."""
    __tablename__ = "notification_logs"

    notification_id = Column(String(36), primary_key=True, default=generate_uuid)
    event = Column(String(50), nullable=False, index=True)  # appointment_booked, confirmed, ...
    channel = Column(SAEnum("SMS", "WhatsApp", "Email", name="notif_channel", native_enum=False), nullable=False)
    recipient = Column(String(200), nullable=False)
    subject = Column(String(200), nullable=True)
    body = Column(String(2000), nullable=False)
    status = Column(SAEnum("Queued", "Sent", "Failed", name="notif_status", native_enum=False), default="Queued", nullable=False)
    patient_id = Column(String(36), ForeignKey("patients.patient_id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    sent_at = Column(DateTime, nullable=True)

    patient = relationship("Patient")
