import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, DateTime, Date, Time, Boolean, ForeignKey, JSON
from sqlalchemy.orm import relationship
from database import Base

def generate_uuid():
    return str(uuid.uuid4())

class User(Base):
    __tablename__ = "users"
    
    user_id = Column(String(36), primary_key=True, default=generate_uuid)
    full_name = Column(String(200), nullable=False)
    email = Column(String(200), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False)  # "Receptionist", "Doctor", "Patient", "SuperAdmin"
    clinic_ids = Column(JSON, nullable=True)     # JSON list of clinic UUID strings assigned
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class Clinic(Base):
    __tablename__ = "clinics"
    
    clinic_id = Column(String(36), primary_key=True, default=generate_uuid)
    name = Column(String(200), nullable=False)
    address = Column(String(500), nullable=False)
    timing_start = Column(String(10), nullable=False)  # Store as "HH:MM"
    timing_end = Column(String(10), nullable=False)    # Store as "HH:MM"
    timezone = Column(String(50), default="Asia/Kolkata")

class Patient(Base):
    __tablename__ = "patients"
    
    patient_id = Column(String(36), primary_key=True, default=generate_uuid)
    full_name = Column(String(200), nullable=False, index=True)
    dob = Column(String(20), nullable=False)            # Stored as YYYY-MM-DD
    gender = Column(String(20), nullable=False)         # "M", "F", "Other"
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
    appt_date = Column(String(20), nullable=False, index=True)  # YYYY-MM-DD
    appt_time = Column(String(10), nullable=False)               # HH:MM
    visit_type = Column(String(50), nullable=False)             # "New", "Follow-Up", "Walk-In"
    status = Column(String(50), nullable=False, default="Scheduled") # Scheduled, Confirmed, Arrived, In Consultation, Completed, No-Show, Cancelled
    notes = Column(String(1000), nullable=True)
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
    medicines = Column(JSON, nullable=False)  # List of dicts: {name, potency, dosage, frequency, duration}
    instructions = Column(String(2000), nullable=True)
    follow_up_date = Column(String(20), nullable=True) # YYYY-MM-DD
    is_fee_waived = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    appointment = relationship("Appointment", back_populates="prescriptions")

class Invoice(Base):
    __tablename__ = "invoices"
    
    invoice_id = Column(String(36), primary_key=True, default=generate_uuid)
    patient_id = Column(String(36), ForeignKey("patients.patient_id"), nullable=False)
    appt_id = Column(String(36), ForeignKey("appointments.appt_id"), nullable=True)
    consultation_fee = Column(Float, nullable=False, default=0.0)
    medicine_charges = Column(Float, nullable=False, default=0.0)
    misc_charges = Column(Float, nullable=False, default=0.0)
    discount = Column(Float, nullable=False, default=0.0)
    total_amount = Column(Float, nullable=False, default=0.0)
    paid_amount = Column(Float, nullable=False, default=0.0)
    due_amount = Column(Float, nullable=False, default=0.0)
    status = Column(String(50), nullable=False, default="Draft") # Draft, Issued, Partially Paid, Paid
    issued_at = Column(DateTime, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    patient = relationship("Patient", back_populates="invoices")
    appointment = relationship("Appointment", back_populates="invoices")
    payments = relationship("Payment", back_populates="invoice", cascade="all, delete-orphan")

class Payment(Base):
    __tablename__ = "payments"
    
    payment_id = Column(String(36), primary_key=True, default=generate_uuid)
    invoice_id = Column(String(36), ForeignKey("invoices.invoice_id"), nullable=False)
    amount = Column(Float, nullable=False)
    payment_mode = Column(String(50), nullable=False) # Cash, Card, UPI, Online
    transaction_id = Column(String(200), nullable=True)
    status = Column(String(50), nullable=False, default="Success") # Success, Pending, Failed
    paid_at = Column(DateTime, default=datetime.utcnow)
    
    invoice = relationship("Invoice", back_populates="payments")

class AuditLog(Base):
    __tablename__ = "audit_logs"
    
    log_id = Column(String(36), primary_key=True, default=generate_uuid)
    entity_type = Column(String(50), nullable=False, index=True) # Patient, Appointment, Invoice, Payment, User, etc.
    entity_id = Column(String(36), nullable=False, index=True)
    action = Column(String(20), nullable=False)  # CREATE, UPDATE, DELETE
    performed_by = Column(String(36), ForeignKey("users.user_id"), nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    changes_json = Column(JSON, nullable=False)  # JSON diff: {"before": {...}, "after": {...}}
