from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional, Dict, Any
from datetime import datetime

# --- Auth Schemas ---
class Token(BaseModel):
    access_token: str
    token_type: str
    role: str
    full_name: str
    user_id: str

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

# --- User Schemas ---
class UserCreate(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    role: str  # "Receptionist", "Doctor", "Patient", "SuperAdmin"
    clinic_ids: Optional[List[str]] = []

class UserResponse(BaseModel):
    user_id: str
    full_name: str
    email: EmailStr
    role: str
    clinic_ids: Optional[List[str]]
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class PasswordReset(BaseModel):
    email: EmailStr
    new_password: str

# --- Clinic Schemas ---
class ClinicCreate(BaseModel):
    name: str
    address: str
    timing_start: str  # "HH:MM"
    timing_end: str    # "HH:MM"
    timezone: Optional[str] = "Asia/Kolkata"

class ClinicResponse(BaseModel):
    clinic_id: str
    name: str
    address: str
    timing_start: str
    timing_end: str
    timezone: str
    
    class Config:
        from_attributes = True

# --- Patient Schemas ---
class PatientCreate(BaseModel):
    full_name: str
    dob: str  # YYYY-MM-DD
    gender: str  # M / F / Other
    mobile: str
    address: str
    occupation: str
    email: Optional[EmailStr] = None
    blood_group: Optional[str] = None
    emergency_contact: Optional[str] = None
    allergies: Optional[str] = None
    chronic_conditions: Optional[str] = None
    referred_by: Optional[str] = None

class PatientResponse(BaseModel):
    patient_id: str
    full_name: str
    dob: str
    gender: str
    mobile: str
    address: str
    occupation: str
    unique_patient_id: str
    email: Optional[EmailStr]
    blood_group: Optional[str]
    emergency_contact: Optional[str]
    allergies: Optional[str]
    chronic_conditions: Optional[str]
    referred_by: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True

# --- Medicine Schema ---
class MedicineSchema(BaseModel):
    name: str
    potency: str
    dosage: str
    frequency: str
    duration: str

# --- Prescription Schemas ---
class PrescriptionCreate(BaseModel):
    appt_id: str
    patient_id: str
    chief_complaint: str
    diagnosis: str
    medicines: List[MedicineSchema]
    instructions: Optional[str] = None
    follow_up_date: Optional[str] = None
    is_fee_waived: Optional[bool] = False

class PrescriptionResponse(BaseModel):
    prescription_id: str
    appt_id: str
    patient_id: str
    chief_complaint: str
    diagnosis: str
    medicines: List[MedicineSchema]
    instructions: Optional[str]
    follow_up_date: Optional[str]
    is_fee_waived: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

# --- Appointment Schemas ---
class AppointmentCreate(BaseModel):
    patient_id: str
    doctor_id: str
    clinic_id: str
    appt_date: str  # YYYY-MM-DD
    appt_time: str  # HH:MM
    visit_type: str  # "New", "Follow-Up", "Walk-In"
    notes: Optional[str] = None

class AppointmentStatusUpdate(BaseModel):
    status: str  # e.g., "Arrived", "In Consultation", "Completed"

class AppointmentReschedule(BaseModel):
    appt_date: str
    appt_time: str

class AppointmentResponse(BaseModel):
    appt_id: str
    patient_id: str
    doctor_id: str
    clinic_id: str
    appt_date: str
    appt_time: str
    visit_type: str
    status: str
    notes: Optional[str]
    created_at: datetime
    patient: Optional[PatientResponse] = None
    
    class Config:
        from_attributes = True

# --- Payment Schemas ---
class PaymentCreate(BaseModel):
    amount: float
    payment_mode: str  # Cash, Card, UPI, Online
    transaction_id: Optional[str] = None

class PaymentResponse(BaseModel):
    payment_id: str
    invoice_id: str
    amount: float
    payment_mode: str
    transaction_id: Optional[str]
    status: str
    paid_at: datetime
    
    class Config:
        from_attributes = True

# --- Invoice Schemas ---
class InvoiceCreate(BaseModel):
    patient_id: str
    appt_id: Optional[str] = None
    consultation_fee: float = 0.0
    medicine_charges: float = 0.0
    misc_charges: float = 0.0
    discount: float = 0.0

class InvoiceResponse(BaseModel):
    invoice_id: str
    patient_id: str
    appt_id: Optional[str]
    consultation_fee: float
    medicine_charges: float
    misc_charges: float
    discount: float
    total_amount: float
    paid_amount: float
    due_amount: float
    status: str
    issued_at: Optional[datetime]
    updated_at: datetime
    payments: List[PaymentResponse] = []
    patient: Optional[PatientResponse] = None
    
    class Config:
        from_attributes = True

# --- Audit Log Schemas ---
class AuditLogResponse(BaseModel):
    log_id: str
    entity_type: str
    entity_id: str
    action: str
    performed_by: str
    timestamp: datetime
    changes_json: Dict[str, Any]
    
    class Config:
        from_attributes = True

# --- Dashboard Schemas ---
class KpisResponse(BaseModel):
    today_patients: int
    active_queue: int
    today_revenue: float
    pending_dues: float
    low_stock_alert: int
