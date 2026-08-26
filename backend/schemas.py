from datetime import datetime, date
from decimal import Decimal
from typing import List, Optional, Dict, Any, Literal

from pydantic import BaseModel, EmailStr, Field, field_validator, ConfigDict

# --- Canonical literal types (PRD §5.3.2, §5.5.4, §3.1, §9) ---
UserRoleT = Literal["Receptionist", "Doctor", "Patient", "SuperAdmin"]
ApptStatusT = Literal[
    "Scheduled", "Confirmed", "Arrived", "In Consultation",
    "Completed", "No-Show", "Cancelled",
]
InvoiceStatusT = Literal["Draft", "Issued", "Partially Paid", "Paid"]
VisitTypeT = Literal["New", "Follow-Up", "Walk-In"]
GenderT = Literal["M", "F", "Other"]
PaymentModeT = Literal["Cash", "Card", "UPI", "Online"]
Money = Field(default=Decimal("0.00"), ge=0, max_digits=10, decimal_places=2)


def _validate_date(v: Any, field: str) -> str:
    try:
        date.fromisoformat(v)
    except (TypeError, ValueError):
        raise ValueError(f"{field} must be a valid ISO date (YYYY-MM-DD)")
    return v


def _validate_time(v: Any, field: str = "time") -> str:
    try:
        h, m = v.split(":")
        if not (0 <= int(h) <= 23 and 0 <= int(m) <= 59 and len(h) == 2 and len(m) == 2):
            raise ValueError
    except (ValueError, AttributeError):
        raise ValueError(f"{field} must be in HH:MM 24-hour format")
    return v


class ORMModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)


# --- Auth Schemas ---
class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    role: str
    full_name: str
    user_id: str


class PatientToken(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    patient_id: str
    full_name: str


class RefreshRequest(BaseModel):
    refresh_token: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


# --- User Schemas ---
class UserCreate(BaseModel):
    full_name: str = Field(min_length=1, max_length=200)
    email: EmailStr
    password: str = Field(min_length=8)
    role: UserRoleT
    clinic_ids: List[str] = []


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    role: Optional[UserRoleT] = None
    clinic_ids: Optional[List[str]] = None
    is_active: Optional[bool] = None


class PasswordReset(BaseModel):
    new_password: str = Field(min_length=8)


class UserResponse(ORMModel):
    user_id: str
    full_name: str
    email: EmailStr
    role: str
    clinic_ids: Optional[List[str]]
    is_active: bool
    created_at: datetime


# --- Clinic Schemas ---
class ClinicCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    address: str = Field(min_length=1, max_length=500)
    timing_start: str
    timing_end: str
    timezone: str = "Asia/Kolkata"

    _v_ts = field_validator("timing_start")(lambda cls, v: _validate_time(v, "timing_start"))
    _v_te = field_validator("timing_end")(lambda cls, v: _validate_time(v, "timing_end"))


class ClinicUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    timing_start: Optional[str] = None
    timing_end: Optional[str] = None
    timezone: Optional[str] = None


class ClinicResponse(ORMModel):
    clinic_id: str
    name: str
    address: str
    timing_start: str
    timing_end: str
    timezone: str


# --- Patient Schemas ---
class PatientCreate(BaseModel):
    full_name: str = Field(min_length=1, max_length=200)
    dob: date
    gender: GenderT
    mobile: str = Field(pattern=r"^[6-9]\d{9}$")  # Indian mobile
    address: str = Field(min_length=1, max_length=500)
    occupation: str = Field(min_length=1, max_length=100)
    email: Optional[EmailStr] = None
    blood_group: Optional[str] = None
    emergency_contact: Optional[str] = None
    allergies: Optional[str] = None
    chronic_conditions: Optional[str] = None
    referred_by: Optional[str] = None


class PatientResponse(ORMModel):
    patient_id: str
    full_name: str
    dob: date
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


# --- Prescription Medicine Schema (in-RX, not inventory) ---
class MedicineSchema(BaseModel):
    name: str = Field(min_length=1)
    potency: str = Field(min_length=1)
    dosage: str = Field(min_length=1)
    frequency: str = Field(min_length=1)
    duration: str = Field(min_length=1)


# --- Inventory Medicine Schemas ---
class MedicineCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    manufacturer: Optional[str] = None
    batch_number: Optional[str] = None
    quantity: int = Field(ge=0, default=0)
    unit_price: Decimal = Field(ge=0, default=Decimal("0.00"), max_digits=10, decimal_places=2)
    expiry_date: Optional[str] = None
    low_stock_threshold: int = Field(ge=0, default=10)
    clinic_id: str


class MedicineUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=200)
    manufacturer: Optional[str] = None
    batch_number: Optional[str] = None
    quantity: Optional[int] = Field(default=None, ge=0)
    unit_price: Optional[Decimal] = Field(default=None, ge=0, max_digits=10, decimal_places=2)
    expiry_date: Optional[str] = None
    low_stock_threshold: Optional[int] = Field(default=None, ge=0)


class MedicineResponse(ORMModel):
    medicine_id: str
    name: str
    manufacturer: Optional[str]
    batch_number: Optional[str]
    quantity: int
    unit_price: Decimal
    expiry_date: Optional[str]
    low_stock_threshold: int
    clinic_id: str
    created_at: datetime


class InventoryStatsResponse(BaseModel):
    low_stock_count: int
    near_expiry_count: int
    total_medicines: int


# --- Prescription Schemas ---
class PrescriptionCreate(BaseModel):
    appt_id: str
    patient_id: str
    chief_complaint: str = Field(min_length=1, max_length=2000)
    diagnosis: str = Field(min_length=1, max_length=1000)
    medicines: List[MedicineSchema] = Field(min_length=1)
    instructions: Optional[str] = None
    follow_up_date: Optional[date] = None
    is_fee_waived: bool = False


class PrescriptionResponse(ORMModel):
    prescription_id: str
    appt_id: str
    patient_id: str
    chief_complaint: str
    diagnosis: str
    medicines: List[MedicineSchema]
    instructions: Optional[str]
    follow_up_date: Optional[date]
    is_fee_waived: bool
    created_at: datetime


# --- Appointment Schemas ---
class AppointmentCreate(BaseModel):
    patient_id: str
    doctor_id: str
    clinic_id: str
    appt_date: date
    appt_time: str
    visit_type: VisitTypeT
    notes: Optional[str] = None

    _v_t = field_validator("appt_time")(lambda cls, v: _validate_time(v, "appt_time"))


class AppointmentStatusUpdate(BaseModel):
    status: ApptStatusT
    reason: Optional[str] = None  # required for Cancelled per BR-5


class AppointmentReschedule(BaseModel):
    appt_date: date
    appt_time: str

    _v_t = field_validator("appt_time")(lambda cls, v: _validate_time(v, "appt_time"))


class AppointmentResponse(ORMModel):
    appt_id: str
    patient_id: str
    doctor_id: str
    clinic_id: str
    appt_date: date
    appt_time: str
    visit_type: str
    status: str
    notes: Optional[str]
    cancel_reason: Optional[str] = None
    token_number: Optional[int] = None
    created_at: datetime
    patient: Optional[PatientResponse] = None


# --- Payment Schemas ---
class PaymentCreate(BaseModel):
    amount: Decimal = Field(gt=0, max_digits=10, decimal_places=2)
    payment_mode: PaymentModeT
    transaction_id: Optional[str] = None


class PaymentResponse(ORMModel):
    payment_id: str
    invoice_id: str
    amount: Decimal
    payment_mode: str
    transaction_id: Optional[str]
    status: str
    paid_at: datetime


# --- Invoice Schemas ---
class InvoiceCreate(BaseModel):
    patient_id: str
    appt_id: Optional[str] = None
    consultation_fee: Decimal = Money
    medicine_charges: Decimal = Money
    misc_charges: Decimal = Money
    discount: Decimal = Money


class InvoiceResponse(ORMModel):
    invoice_id: str
    patient_id: str
    appt_id: Optional[str]
    consultation_fee: Decimal
    medicine_charges: Decimal
    misc_charges: Decimal
    discount: Decimal
    total_amount: Decimal
    paid_amount: Decimal
    due_amount: Decimal
    status: str
    issued_at: Optional[datetime]
    updated_at: datetime
    payments: List[PaymentResponse] = []
    patient: Optional[PatientResponse] = None


# --- Audit Log Schemas ---
class AuditLogResponse(ORMModel):
    log_id: str
    entity_type: str
    entity_id: str
    action: str
    performed_by: str
    timestamp: datetime
    changes_json: Dict[str, Any]


# --- Dashboard Schemas ---
class KpisResponse(BaseModel):
    today_patients: int
    active_queue: int
    today_revenue: Decimal
    pending_dues: Decimal
    avg_wait_minutes: float = 0.0
    low_stock_alert: int


# --- Portal Schemas ---
class PortalBookingRequest(BaseModel):
    """Public self-booking (§5.9.1). Existing patients matched by mobile."""
    full_name: str = Field(min_length=1, max_length=200)
    mobile: str = Field(pattern=r"^[6-9]\d{9}$")
    dob: date
    gender: GenderT
    clinic_id: str
    appt_date: date
    appt_time: str
    visit_type: VisitTypeT = "New"
    notes: Optional[str] = None

    _v_t = field_validator("appt_time")(lambda cls, v: _validate_time(v, "appt_time"))


class OtpRequest(BaseModel):
    mobile: str = Field(pattern=r"^[6-9]\d{9}$")


class OtpVerify(BaseModel):
    mobile: str = Field(pattern=r"^[6-9]\d{9}$")
    code: str = Field(min_length=4, max_length=8)


class PortalCancel(BaseModel):
    reason: Optional[str] = None


# --- Notification Schemas ---
class NotificationResponse(ORMModel):
    notification_id: str
    event: str
    channel: str
    recipient: str
    subject: Optional[str]
    body: str
    status: str
    patient_id: Optional[str]
    created_at: datetime
    sent_at: Optional[datetime]


# --- Report Schemas ---
class RevenuePoint(BaseModel):
    date: str
    revenue: Decimal
    payments_count: int


class AppointmentSummary(BaseModel):
    total: int
    completed: int
    cancelled: int
    no_show: int
    scheduled: int
    confirmed: int


class RegistrationPoint(BaseModel):
    month: str
    registrations: int
