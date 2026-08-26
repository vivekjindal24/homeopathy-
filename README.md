# HCMS — Homeopathy Clinic Management System

A full-stack clinic management platform for multi-speciality homeopathy practices.

## Tech Stack
- **Backend**: Python 3.11+ · FastAPI · SQLAlchemy · SQLite (dev) · Pydantic v2
- **Frontend**: Flutter 3.x · Dart · Material Design 3
- **Auth**: JWT with role-based access (SuperAdmin, Doctor, Receptionist, Patient)

## Architecture
- `backend/` — FastAPI REST API with SQLAlchemy ORM, JWT auth, audit logging
- `frontend/` — Flutter Web SPA with role-based dashboards
- `Design File/` — Figma design exports

## Quick Start

### Backend
```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```
API docs: http://localhost:8000/docs

### Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome --port 8080
```

### Default Credentials
Set via environment variables (or use seed data defaults):
```
ADMIN_EMAIL=admin@hcms.com / ADMIN_PASSWORD=admin123
DOCTOR_EMAIL=dr.verma@hcms.com / DOCTOR_PASSWORD=doctor123
```

## Features
- Role-based dashboards (Doctor, Receptionist, Admin, Patient Portal)
- Patient registration with unique ID generation
- Appointment scheduling with walk-in support
- Prescription management
- Invoice generation and payment tracking
- Inventory management with low-stock and near-expiry alerts
- Real-time queue management
- Audit logging and notifications
- OTP-based patient portal authentication

## API Endpoints
53 REST endpoints covering: Auth, Patients, Appointments, Prescriptions, Invoices, Payments, Inventory, Notifications, Audit Logs, Admin Reports, Patient Portal.

## Project Structure
See `HCMS_PRD_v4.0.md` for the full product requirements document.
