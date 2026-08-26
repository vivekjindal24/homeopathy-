# Product Requirements Document
## Homeopathic Clinic Management System (HCMS)

**Document Version:** 4.0 (Consolidated — Deployment Ready)
**Prepared For:** Dr. Vishvesh Kumar Verma Homeopathy Clinic
**Location:** Indore, Madhya Pradesh, India
**Date:** 22 June 2026
**Status:** ✅ Approved for Development & Deployment
**Supersedes:** PRD v3.0, PRD v3.1, PRD v3.2
**SRS Reference:** SRS-HCMS-001 v1.0 (21 June 2026)
**Standard:** IEEE Std 830-1998 aligned

---

## Document History

| Version | Date | Author | Summary of Changes |
|---------|------|--------|-------------------|
| 3.0 | Prior | HCMS Team | Base product requirements (unreferenced baseline) |
| 3.1 | Prior | HCMS Team | Incremental update (unreferenced) |
| 3.2 | Jun 2026 | HCMS Team | Receptionist UI, queue, invoice, appointment patch |
| **4.0** | **22 Jun 2026** | **HCMS Dev Team** | **Full consolidation with SRS; deployment-ready; two-clinic support, patient portal, super-admin, security, data dictionary, NFRs added** |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Scope](#2-product-scope)
3. [User Roles & Personas](#3-user-roles--personas)
4. [Operating Environment & Technology Stack](#4-operating-environment--technology-stack)
5. [Functional Requirements](#5-functional-requirements)
   - 5.1 [Receptionist — Dashboard](#51-receptionist--dashboard)
   - 5.2 [Receptionist — Patient Management](#52-receptionist--patient-management)
   - 5.3 [Receptionist — Appointment Management](#53-receptionist--appointment-management)
   - 5.4 [Receptionist — Queue Management](#54-receptionist--queue-management)
   - 5.5 [Receptionist — Invoice Management](#55-receptionist--invoice-management)
   - 5.6 [Receptionist — Payment Management](#56-receptionist--payment-management)
   - 5.7 [Receptionist — UI Quality & Interaction Standards](#57-receptionist--ui-quality--interaction-standards)
   - 5.8 [Doctor Interface (iPad)](#58-doctor-interface-ipad)
   - 5.9 [Patient Portal](#59-patient-portal)
   - 5.10 [Super Administrator Module](#510-super-administrator-module)
   - 5.11 [Notification System](#511-notification-system)
   - 5.12 [Multi-Clinic Support](#512-multi-clinic-support)
6. [Non-Functional Requirements](#6-non-functional-requirements)
7. [External Interface Requirements](#7-external-interface-requirements)
8. [Business Rules](#8-business-rules)
9. [Data Model & Dictionary](#9-data-model--dictionary)
10. [Security & Compliance Requirements](#10-security--compliance-requirements)
11. [Acceptance Criteria](#11-acceptance-criteria)
12. [Deployment Requirements](#12-deployment-requirements)
13. [Assumptions, Dependencies & Constraints](#13-assumptions-dependencies--constraints)
14. [Out of Scope](#14-out-of-scope)
15. [Open Items (TBD)](#15-open-items-tbd)

---

## 1. Executive Summary

The Homeopathic Clinic Management System (HCMS) is a custom web- and tablet-based clinical operations platform designed for a single-doctor homeopathic practice operating across **two clinic locations** with different schedules. The system digitises and streamlines every touchpoint from patient registration through to payment settlement.

**Core value delivered:**
- Receptionists gain a fast, minimal, fully operational web dashboard for daily workflows.
- The doctor receives a clean iPad-native prescription writing interface.
- Patients can self-book, reschedule, and cancel appointments online.
- The clinic owner/administrator has full control over users, clinics, schedules, and system settings.

**Technology:** Flutter (web + iPad) frontend, FastAPI (Python 3.11+) backend, PostgreSQL 15 database, deployed via Docker/Kubernetes.

**Regulatory alignment:** DPDP Act 2023, IT Act 2000, WCAG 2.1 AA.

---

## 2. Product Scope

### 2.1 In Scope

| Module | Description |
|--------|-------------|
| Receptionist Dashboard | KPI cards, quick actions, clinic-selector |
| Patient Management | Registration, search, profile, medical history |
| Appointment Management | Booking, confirmation, rescheduling, cancellation, status tracking |
| Queue Management | Real-time queue board with state machine, billing hooks |
| Invoice Management | Draft, issue, line items, waivers, discounts |
| Payment Management | Collection, ledger update, gateway integration |
| Doctor Interface | iPad-native prescription writing, patient schedule view |
| Patient Portal | Online self-booking, rescheduling, cancellation |
| Super-Admin Console | User management, clinic config, roles, reports |
| Notification System | SMS/WhatsApp/Email appointment reminders and confirmations |
| Audit Logging | Immutable log for all entity changes |
| Multi-Clinic Support | Two clinic locations, different timings, single doctor |

### 2.2 Out of Scope

- GST invoices for patients (GST handling limited to supplier/medicine procurement only).
- Telemedicine or video consultation features.
- Multi-doctor scheduling (system designed for single doctor; extensible in future).
- Inventory/pharmacy stock management beyond Low Stock Alert KPI.
- Laboratory report integration.
- ABDM / Ayushman Bharat health ID integration (future consideration).

---

## 3. User Roles & Personas

| Role | Description | Primary Goals | Access Level |
|------|-------------|---------------|--------------|
| **Receptionist** | Clinic front-desk staff; moderate computer literacy; needs a fast, error-free interface | Register patients, manage appointments, manage queue, generate invoices, collect payments | Receptionist module only |
| **Doctor** | Licensed homeopathic practitioner; uses iPad; not expected to operate billing | View own schedule, write prescriptions, mark consultation completed, apply fee waiver | Doctor module + read-only patient/appointment view |
| **Patient** | General public; may book online or walk in; expects simple and secure experience | Self-book/reschedule/cancel appointments, view invoices, make payments, receive notifications | Patient portal only |
| **Super Administrator** | IT-savvy clinic owner or manager | Manage users, clinics, roles, system config, view all reports | Full system access |

### 3.1 RBAC Summary

| Feature | Receptionist | Doctor | Patient | Super Admin |
|---------|:---:|:---:|:---:|:---:|
| Patient registration | ✅ | ❌ | ❌ | ✅ |
| Appointment booking | ✅ | ❌ | ✅ (own) | ✅ |
| Queue management | ✅ | Read | ❌ | ✅ |
| Invoice create/edit | ✅ | ❌ | ❌ | ✅ |
| Payment collection | ✅ | ❌ | ✅ (online) | ✅ |
| Prescription writing | ❌ | ✅ | ❌ | ❌ |
| Fee waiver decision | ❌ | ✅ | ❌ | ✅ |
| User management | ❌ | ❌ | ❌ | ✅ |
| Clinic configuration | ❌ | ❌ | ❌ | ✅ |
| Audit log view | ❌ | ❌ | ❌ | ✅ |
| Aggregate reports | ❌ | ❌ | ❌ | ✅ |

---

## 4. Operating Environment & Technology Stack

### 4.1 Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Frontend (Web) | Flutter Web | Latest stable |
| Frontend (iPad) | Flutter Native | Latest stable |
| Backend API | FastAPI (Python) | Python 3.11+ |
| Database | PostgreSQL | 15 |
| Cache (optional) | Redis | 7 |
| ORM | SQLAlchemy | Latest compatible |
| Auth | OAuth2 + JWT | — |
| API Docs | OpenAPI 3.0 (Swagger UI) | — |
| Containerisation | Docker | Latest stable |
| Orchestration | Kubernetes (prod) / Docker Compose (pilot) | — |
| Payment Gateway | Razorpay or PayTM (TBD) | — |
| Notification | Twilio / MSG91 (TBD) | — |
| Log Aggregation | ELK Stack or Loki/Grafana (TBD) | — |

### 4.2 Supported Environments

- **Server OS:** Ubuntu 22.04 LTS or equivalent Linux
- **Browsers:** Chrome ≥ 110, Edge ≥ 110, Firefox ≥ 109, Safari ≥ 16 (iPad)
- **iPad:** iPadOS 14+
- **Desktop/Laptop:** Intel/AMD CPU, ≥ 4 GB RAM
- **Network:** HTTPS (TLS 1.2+); optional WebSocket for real-time updates

---

## 5. Functional Requirements

### 5.1 Receptionist — Dashboard

#### 5.1.1 Visual Style
- The receptionist dashboard **must** follow a minimal, clean, clinic-grade interface.
- KPI/stat cards (Today's Patients, Active Queue, Today's Revenue, Pending Dues, Low Stock Alert) must use **neutral or white surface backgrounds only**.
- Cards must **not** use decorative color fills, tinted backgrounds, gradient fills, textured overlays, background illustrations, or image-like treatments.
- Visual emphasis must be applied **only** through icon, status dot, border accent, or numeric highlight — not through full-card background color.
- The overall design must feel professional, calm, and operational.
- Layout spacing, typography, alignment, icon sizing, and table rhythm must be pixel-consistent across all receptionist screens.

#### 5.1.2 Dashboard Card Behaviour
- Each card may include a monochrome or lightly accented surface; the icon container may carry semantic color (e.g., rupee icon in green on a neutral Today's Revenue card).
- Cards must align to a consistent height and spacing grid.
- Cards must be responsive across tablet and desktop widths without breaking layout balance.

#### 5.1.3 Dashboard KPIs
Minimum KPI cards required:
- Today's Patients
- Active Queue (count)
- Today's Revenue (₹)
- Pending Dues (₹)
- Low Stock Alert (count of medicines below threshold)

#### 5.1.4 Clinic Selector
- A visible clinic selector must be present allowing the receptionist to switch between Clinic A and Clinic B.
- All schedule, queue, and appointment data must refresh to reflect the selected clinic.

---

### 5.2 Receptionist — Patient Management

#### 5.2.1 New Patient Registration
- The **New Patient** button must be fully functional; on click, a modal/drawer/full-screen form must appear immediately.
- **Mandatory fields:**
  - Full Name
  - Age or Date of Birth
  - Gender
  - Mobile Number
  - Address
  - Occupation
  - Unique Patient ID (auto-generated by system)
- **Optional fields:**
  - Email
  - Blood Group
  - Emergency Contact
  - Allergies
  - Chronic Conditions
  - Referred By
- Save action must validate all mandatory fields and display inline validation errors for missing or malformed data.
- On successful save: patient added to list immediately + success toast shown.
- On cancel: form closes without saving.

#### 5.2.2 Patient List
- Patient listing table must be visually clean, horizontally aligned, and fully readable.
- Every visible action button must be operational — no decorative placeholders.
- Minimum table columns: Patient ID, Name, Mobile, Last Visit, Actions.
- Actions must include: View Profile, Edit, Book Appointment.

#### 5.2.3 Patient Profile
- View patient demographics, visit history, prescriptions, invoices, and payment ledger.
- All records must be read-only for the receptionist; edits go through the edit flow.

---

### 5.3 Receptionist — Appointment Management

#### 5.3.1 Book Appointment
- The **Book Appointment** button must be fully functional; on click, a booking interface (modal/drawer/page) must open.
- The booking interface must support:
  - Patient selection or quick patient search
  - Appointment date
  - Appointment time
  - Doctor selection (single doctor currently; field reserved for future multi-doctor expansion)
  - Visit type: New Consultation / Follow-Up / Walk-In Conversion
  - Optional note or internal receptionist remark
- On successful booking: appointment added to list immediately + success toast shown.

#### 5.3.2 Appointment Statuses
The system must support all of the following statuses with defined transitions:

| Status | Meaning |
|--------|---------|
| Scheduled | Appointment booked, not yet confirmed |
| Confirmed | Receptionist or system confirmed attendance |
| Arrived | Patient has arrived at clinic |
| In Consultation | Patient is with the doctor |
| Completed | Consultation finished |
| No-Show | Patient did not arrive |
| Cancelled | Appointment cancelled by patient or clinic |

- Status transitions must be reflected immediately in the UI without requiring a full page reload.

#### 5.3.3 Appointment Table Actions
All of the following actions must be fully functional:

**Confirm:**
- Updates appointment status to Confirmed.
- Shows toast: "Patient appointment has been confirmed."

**Reschedule:**
- Opens interface with editable date/time fields.
- On save: updates appointment table; shows success toast.
- Must preserve audit trail of previous date/time values.

**Cancel:**
- Displays a confirmation prompt before final cancellation.
- On confirmation: status updated to Cancelled; success toast/popup shown.
- Requires explicit confirmation step — no one-click cancellation.

#### 5.3.4 Appointment History & Audit Trail
- All reschedules must log the previous date/time with timestamp and actor ID in the AuditLog.
- Cancellation must log reason if provided.

---

### 5.4 Receptionist — Queue Management

#### 5.4.1 Queue States
The queue management board must support the following operational states:

| State | Meaning |
|-------|---------|
| Waiting | Patient has arrived and is waiting |
| In Consultation | Patient is currently with the doctor |
| Completed | Consultation finished |
| No-Show | Patient expected but did not appear or left before consultation |

#### 5.4.2 Single Active Consultation Rule
- At any moment, **only one patient** may be in **In Consultation** state per doctor/clinic stream.
- If a receptionist attempts to move a second patient into In Consultation while one is already active, the system must **block the action** and display an explanatory message.
- This rule enforces the single-doctor, single-consultation constraint.

#### 5.4.3 Receptionist Billing During Waiting State
- While a patient is in the Waiting state, the receptionist may:
  - Record consultation fee eligibility
  - Identify whether the visit is chargeable or fee-waived
  - Prepare an invoice draft
  - Collect registration or consultation fee where clinic policy permits pre-consultation collection
- The system must present billing action hooks from the queue card/row for waiting patients.

#### 5.4.4 Seven-Day Consultation Fee Rule
- If a patient returns within **7 days** of a previous eligible consultation, the doctor may decide no consultation fee is applicable.
- The receptionist interface must support both outcomes:
  - **Charge consultation fee** (default)
  - **Waive consultation fee** (with visible reason or system note)
- If fee is waived: the invoice must show consultation fee as ₹0 or marked **Waived**, while still permitting medicine charges.

#### 5.4.5 Post-Consultation Billing Continuity
- Marking a patient as Completed must not terminate the financial workflow.
- The system must naturally hand off to invoice and payment processing.
- Invoice and payment generation must support: consultation fee, medicine charges, other line items, fee waiver, and discounts.

---

### 5.5 Receptionist — Invoice Management

#### 5.5.1 Invoice Summary Cards
- Cards above the invoice table (Total Invoices, Paid, Unpaid, Partially Paid, Due Today) must use neutral backgrounds and icon-only color emphasis. No decorative filled backgrounds.

#### 5.5.2 New Invoice
- The **New Invoice** button must be fully functional; on click, the Create Invoice interface must appear reliably.

#### 5.5.3 Create Invoice Workflow
The receptionist must be able to:
1. Select patient (search-enabled)
2. Link to an appointment (optional)
3. Add consultation fee (or mark as waived)
4. Add medicine charges (line items)
5. Add miscellaneous/procedure charges
6. Apply discount (if permitted by clinic policy)
7. Mark consultation fee as waived when the 7-day rule applies
8. Save as Draft
9. Issue Invoice
10. Proceed to Payment Collection

#### 5.5.4 Invoice Statuses

| Status | Meaning |
|--------|---------|
| Draft | Being prepared, not yet issued |
| Issued | Finalised and presented to patient |
| Partially Paid | Some amount collected, balance remaining |
| Paid | Fully settled |

#### 5.5.5 Invoice Actions — All Must Be Functional

| Action | Behaviour |
|--------|-----------|
| Save Draft | Saves invoice in Draft status; no ledger update |
| Issue Invoice | Finalises invoice; status → Issued |
| Record Payment / Pay Now | Opens payment collection interface for this invoice |
| View Invoice | Opens invoice detail in modal/drawer/detail page |
| Close / Cancel | Closes without saving (with unsaved-changes prompt if applicable) |

#### 5.5.6 Invoice Table Actions
- **View:** Opens invoice details.
- **Pay:** Opens payment collection interface for that invoice.
- After successful payment: invoice table refreshes to show updated paid amount, due amount, and status.

#### 5.5.7 GST Handling
- Patient invoices must **not** include GST unless required by law.
- GST on medicine procurement from suppliers is handled separately in the procurement module and does not appear on patient-facing invoices.
- Invoice total = Consultation Fee + Medicine Charges + Misc Charges − Discount.
- Zero consultation fee must be supported (medicine-only billing).

---

### 5.6 Receptionist — Payment Management

#### 5.6.1 Payment Summary Cards
- Cards must use neutral/minimal treatment.
- Color restricted to icons, payment status chips, or small indicators — not entire card backgrounds.

#### 5.6.2 Payment Collection Flow
- Payment action buttons must be fully functional.
- Editable fields include: amount, payment mode (Cash / Card / UPI / Online), transaction reference.
- Save/confirm buttons must be interactive and validated.
- On successful collection: success toast shown + ledger updated immediately.
- Payment record must store invoice ID (linkage to originating invoice).

#### 5.6.3 Payment Modes Supported
- Cash
- Card (POS/Swipe)
- UPI (QR / ID)
- Online (Payment Gateway — Razorpay/PayTM)

#### 5.6.4 Partial Payment
- System must support partial payment recording.
- Invoice status transitions: Issued → Partially Paid → Paid.
- Due amount = Total Amount − Sum of all payments against invoice.

---

### 5.7 Receptionist — UI Quality & Interaction Standards

#### 5.7.1 General Interaction Rule
- Any button, action icon, chip action, or CTA visible on the receptionist UI **must** be backed by a real interaction flow.
- No visible controls may remain as static placeholders.
- If an action is temporarily unavailable, the UI must either **hide it** or show a **disabled state with explanation**.

#### 5.7.2 Feedback on State-Changing Actions
Every successful state-changing action must show immediate feedback via toast, snackbar, inline success indicator, or confirmation popup. Required feedback events:

| Action | Required Feedback |
|--------|-------------------|
| Patient created | "Patient registered successfully." |
| Appointment confirmed | "Patient appointment has been confirmed." |
| Appointment rescheduled | "Appointment rescheduled to [new date/time]." |
| Appointment cancelled | "Appointment has been cancelled." |
| Queue status updated | Status chip updates immediately; optional toast |
| Invoice created/issued | "Invoice INV-XXXX issued successfully." |
| Payment recorded | "Payment of ₹[amount] recorded." |

- Error messages must be **specific and actionable** (e.g., "Mobile number is required" — not just "Error").

#### 5.7.3 Layout and Design Quality
- The receptionist UI must be pixel-clean, aligned, and production-ready.
- Vertical spacing, table column rhythm, button sizing, icon alignment, and form field spacing must remain consistent across all modules.
- Interface must avoid rough, overly colorful, mismatched, or visually cheap treatments.
- Modal windows, drawers, and popups must feel like part of a consistent design system.

#### 5.7.4 Responsive Layout
- The layout must remain visually correct on supported tablet and desktop views.
- Tables, popups, forms, and action groups must not visually break or overlap at standard screen resolutions.
- All primary workflows must remain reachable without layout clipping.

#### 5.7.5 Animation Standards
- Animation, if used, must be **subtle and functional only**.
- Animation must never interfere with speed of operation.
- Toasts, dialogs, and overlays must open and close smoothly and consistently.

#### 5.7.6 State Persistence
- State changes must be reflected immediately in the local interface **and** persisted to the backend without requiring a manual refresh.

---

### 5.8 Doctor Interface (iPad)

#### 5.8.1 Target Device
- Flutter native app targeting iPadOS 14+.
- Optimised for touch and Apple Pencil input.

#### 5.8.2 Schedule View
- Doctor must see their appointment schedule for the selected clinic and date.
- Schedule must show: patient name, visit type, appointment time, and current status.

#### 5.8.3 Prescription Writing
- Doctor can open a patient's consultation record and write a prescription.
- Prescription fields: chief complaint, diagnosis, medicines (name, dosage, frequency, duration), instructions, follow-up date.
- Save prescription must persist to the backend and be visible to the receptionist.

#### 5.8.4 Consultation Completion
- Doctor can mark a consultation as Completed.
- On completion: queue state for that patient updates to Completed; billing workflow is triggered.

#### 5.8.5 Fee Waiver Decision
- Doctor can apply the 7-day consultation fee waiver during or after consultation.
- Decision is recorded against the patient's visit and reflected in the invoice.

---

### 5.9 Patient Portal

#### 5.9.1 Online Appointment Booking
- Patients must be able to search for and book an appointment via the public-facing patient portal.
- Portal must show doctor availability based on the selected clinic's configured timings.
- Booking inputs: preferred clinic, date, time slot, visit type, contact details.

#### 5.9.2 Rescheduling and Cancellation
- Patients must be able to reschedule or cancel their own appointments from the portal.
- Cancellation must adhere to any clinic-configured cancellation policy (e.g., cancellation window).
- All patient-initiated changes must generate an AuditLog entry.

#### 5.9.3 Appointment Confirmation
- Upon booking, patient receives a confirmation notification (SMS/WhatsApp/Email based on clinic config).
- Portal must show the patient a list of their upcoming and past appointments.

#### 5.9.4 Invoice & Payment View
- Patients must be able to view their invoices and outstanding dues via the portal.
- Online payment via Razorpay/PayTM must be supported where configured.

#### 5.9.5 Portal Design Standards
- Web-responsive Flutter application.
- WCAG 2.1 AA compliant.
- Clean, minimal, welcoming aesthetic consistent with clinic brand.
- Simple booking flow; minimise the number of steps to complete a booking.

---

### 5.10 Super Administrator Module

#### 5.10.1 User Management
- Create, edit, deactivate, and delete users: Receptionists, Doctors.
- Assign roles and clinic access.
- Reset passwords.

#### 5.10.2 Clinic Configuration
- Configure clinic name, address, timezone.
- Set operating hours (timing_start, timing_end) per clinic.
- Enable/disable appointment time slots.
- Configure consultation fee defaults and fee waiver rules.

#### 5.10.3 System Settings
- Configure SMS/WhatsApp notification templates and gateway credentials.
- Configure payment gateway credentials.
- Set appointment cancellation policy (minimum notice period).
- Configure medicine low-stock alert thresholds.

#### 5.10.4 Reports & Analytics
- Daily/weekly/monthly revenue reports.
- Appointment summary (total, completed, no-shows, cancellations).
- Patient registration trends.
- Export reports as CSV/PDF.

#### 5.10.5 Audit Log View
- Super Admin can view the full immutable AuditLog.
- Filters: entity type, date range, actor, action type.

---

### 5.11 Notification System

#### 5.11.1 Supported Channels
- SMS (via Twilio / MSG91 or equivalent Indian provider)
- WhatsApp (via Business API)
- Email (SMTP — optional, configurable)

#### 5.11.2 Notification Triggers

| Trigger | Recipient | Channel |
|---------|-----------|---------|
| Appointment booked | Patient | SMS/WhatsApp |
| Appointment confirmed | Patient | SMS/WhatsApp |
| Appointment rescheduled | Patient | SMS/WhatsApp |
| Appointment cancelled | Patient | SMS/WhatsApp |
| Appointment reminder | Patient | SMS/WhatsApp (24h before) |
| Invoice issued | Patient | WhatsApp/Email |
| Payment received | Patient | WhatsApp/Email |

#### 5.11.3 Cost Responsibility
- SMS/WhatsApp API costs are borne by the clinic.
- The system provides configuration fields for API keys and sender IDs.

---

### 5.12 Multi-Clinic Support

- The system must support **two clinic locations** for the single doctor, each with independent:
  - Name and address
  - Operating hours (timing_start, timing_end)
  - Appointment slots
  - Queue
- The doctor's schedule across both clinics is configurable by the Super Admin.
- The receptionist dashboard includes a clinic selector; all data displayed is scoped to the selected clinic.
- Appointments and patient records are shared across clinics (patient registered once, appointments at either clinic).

---

## 6. Non-Functional Requirements

| ID | Category | Requirement |
|----|----------|-------------|
| NFR-1 | Performance | System must support ≥ 50 concurrent users with response time ≤ 2 seconds for typical CRUD operations (patient / appointment / invoice / payment). |
| NFR-2 | Availability | Target 99.9% uptime excluding scheduled maintenance windows. |
| NFR-3 | Security — Data at Rest | All stored patient and transaction data must be encrypted using AES-256. |
| NFR-4 | Security — Data in Transit | All client-server communication must use TLS 1.2 or higher. |
| NFR-5 | Security — Authentication | Passwords hashed with bcrypt (work factor ≥ 12); JWT access tokens with ≤ 15 min expiry; refresh-token rotation enforced. |
| NFR-6 | Security — Authorization | RBAC must enforce distinct permissions for Receptionist, Doctor, Patient, and Super Admin. No role may access another role's restricted endpoints. |
| NFR-7 | Auditability | Immutable audit log for every CREATE, UPDATE, DELETE on Patient, Appointment, Invoice, Payment, and User entities. Log must store: timestamp, user ID, action, entity type, entity ID, before/after values (JSON). |
| NFR-8 | Accessibility | Frontend must conform to WCAG 2.1 AA (keyboard navigation, ARIA labels, sufficient color contrast ≥ 4.5:1 for body text). |
| NFR-9 | API Documentation | All backend endpoints documented via OpenAPI 3.0 (Swagger UI) and versioned under `/api/v1/`. |
| NFR-10 | Backup & Recovery | Daily automated PostgreSQL backups with point-in-time recovery (PITR); backups stored off-site or in a separate cloud bucket. RTO ≤ 4 hours, RPO ≤ 24 hours. |
| NFR-11 | Scalability | Backend containerised (Docker) and orchestratable via Kubernetes to support horizontal scaling and additional clinics in future. |
| NFR-12 | Frontend Load Time | Initial page load (login/dashboard) ≤ 3 seconds on a 5 Mbps broadband connection. |
| NFR-13 | Regulatory Compliance | System must meet Indian legal requirements: medical record retention ≥ 3 years; data privacy per DPDP Act 2023 and IT Act 2000. |
| NFR-14 | Offline Capability *(Optional)* | Receptionist UI should queue actions locally when network connectivity is lost and synchronise upon reconnection. |
| NFR-15 | Internationalisation | All UI strings must be externalised (i18n-ready) for future Hindi/Marathi localisation. |
| NFR-16 | Structured Logging | Backend must emit structured JSON logs (timestamp, level, service, trace-ID) to a centralised log aggregator. |

---

## 7. External Interface Requirements

### 7.1 User Interfaces

| Interface | Platform | Optimisation |
|-----------|----------|-------------|
| Receptionist UI | Flutter Web (responsive) | Tablet and desktop |
| Doctor UI | Flutter Native | iPad touch and Apple Pencil |
| Patient Portal | Flutter Web (responsive) | Mobile-first, WCAG 2.1 AA |
| Super-Admin Console | Flutter Web (responsive) | Desktop-first |

### 7.2 Hardware Interfaces
- Standard desktop/laptop (Intel/AMD, ≥ 4 GB RAM)
- Apple iPad (iPadOS 14+)
- No specialised or proprietary hardware required

### 7.3 Software Interfaces

| Interface | Protocol/Standard | Notes |
|-----------|------------------|-------|
| Backend API | RESTful JSON over HTTPS (`/api/v1/`) | Versioned |
| Authentication | OAuth2 + JWT (access + refresh token) | |
| Payment Gateway | HTTPS POST to Razorpay / PayTM | TBD — see §15 |
| Notification Gateway | HTTP/SMS API — Twilio / MSG91 | TBD — see §15 |
| Database | PostgreSQL via SQLAlchemy ORM | Connection pooling enabled |
| Cache | Redis pub/sub (optional) | Real-time updates |
| Email | SMTP | Invoice and receipt delivery |

### 7.4 Communications Interfaces
- All client-server communication over HTTPS (TLS 1.2+)
- WebSocket (optional) for real-time queue/status push updates
- Email/SMTP for invoices and receipts (if clinic opts in)

---

## 8. Business Rules

| ID | Rule |
|----|------|
| BR-1 | A visible action button must never be shipped without mapped behaviour, validation, and user feedback. |
| BR-2 | Only one patient may hold the **In Consultation** status at a time in a single-doctor clinic stream. |
| BR-3 | Consultation fee may be waived for a revisit within 7 days, subject to doctor approval and clinic configuration. |
| BR-4 | Invoice generation must support zero consultation fee (medicine-only billing). |
| BR-5 | Appointment cancellation must require an explicit confirmation step before final status change. |
| BR-6 | Rescheduling must preserve appointment history via an audit trail of previous date/time values. |
| BR-7 | Patient invoices must not include GST unless required by applicable Indian law. |
| BR-8 | Patient records are shared across both clinic locations; appointments are clinic-specific. |
| BR-9 | The doctor's availability and schedule per clinic is configurable only by the Super Administrator. |
| BR-10 | Invoice total formula: `Total = Consultation Fee + Medicine Charges + Misc Charges − Discount`. |
| BR-11 | Due amount formula: `Due = Total Amount − Sum of all Payments against invoice`. |
| BR-12 | A patient may not be moved to In Consultation if another patient is already in that state for the same doctor. |

---

## 9. Data Model & Dictionary

### 9.1 Core Entities

#### Patient
| Attribute | Type | Required | Notes |
|-----------|------|----------|-------|
| `patient_id` | UUID | ✅ | Primary key |
| `full_name` | VARCHAR(200) | ✅ | |
| `dob` | DATE | ✅ | Age or DOB (one required) |
| `gender` | ENUM | ✅ | M / F / Other |
| `mobile` | VARCHAR(15) | ✅ | Primary contact |
| `address` | TEXT | ✅ | |
| `occupation` | VARCHAR(100) | ✅ | |
| `unique_patient_id` | VARCHAR(20) | ✅ | Auto-generated, human-readable |
| `email` | VARCHAR(200) | ❌ | |
| `blood_group` | VARCHAR(5) | ❌ | |
| `emergency_contact` | VARCHAR(200) | ❌ | |
| `allergies` | TEXT | ❌ | |
| `chronic_conditions` | TEXT | ❌ | |
| `referred_by` | VARCHAR(200) | ❌ | |
| `created_at` | TIMESTAMPTZ | ✅ | Auto |
| `updated_at` | TIMESTAMPTZ | ✅ | Auto |

#### Doctor
| Attribute | Type | Required | Notes |
|-----------|------|----------|-------|
| `doctor_id` | UUID | ✅ | Primary key |
| `name` | VARCHAR(200) | ✅ | |
| `specialization` | VARCHAR(100) | ✅ | |
| `clinic_ids` | UUID[] | ✅ | FK → Clinic |

#### Clinic
| Attribute | Type | Required | Notes |
|-----------|------|----------|-------|
| `clinic_id` | UUID | ✅ | Primary key |
| `name` | VARCHAR(200) | ✅ | |
| `address` | TEXT | ✅ | |
| `timing_start` | TIME | ✅ | |
| `timing_end` | TIME | ✅ | |
| `timezone` | VARCHAR(50) | ✅ | IANA timezone identifier |

#### Appointment
| Attribute | Type | Required | Notes |
|-----------|------|----------|-------|
| `appt_id` | UUID | ✅ | Primary key |
| `patient_id` | UUID | ✅ | FK → Patient |
| `doctor_id` | UUID | ✅ | FK → Doctor |
| `clinic_id` | UUID | ✅ | FK → Clinic |
| `appt_date` | DATE | ✅ | |
| `appt_time` | TIME | ✅ | |
| `visit_type` | ENUM | ✅ | New / Follow-Up / Walk-In |
| `status` | ENUM | ✅ | See §5.3.2 |
| `notes` | TEXT | ❌ | Receptionist remark |
| `created_at` | TIMESTAMPTZ | ✅ | Auto |
| `updated_at` | TIMESTAMPTZ | ✅ | Auto |

#### Invoice
| Attribute | Type | Required | Notes |
|-----------|------|----------|-------|
| `invoice_id` | UUID | ✅ | Primary key |
| `patient_id` | UUID | ✅ | FK → Patient |
| `appt_id` | UUID | ❌ | FK → Appointment |
| `consultation_fee` | NUMERIC(10,2) | ✅ | May be 0 if waived |
| `medicine_charges` | NUMERIC(10,2) | ✅ | |
| `misc_charges` | NUMERIC(10,2) | ✅ | Default 0 |
| `discount` | NUMERIC(10,2) | ✅ | Default 0 |
| `total_amount` | NUMERIC(10,2) | ✅ | Computed: see BR-10 |
| `paid_amount` | NUMERIC(10,2) | ✅ | Sum of payments |
| `due_amount` | NUMERIC(10,2) | ✅ | Computed: see BR-11 |
| `status` | ENUM | ✅ | Draft / Issued / Partially Paid / Paid |
| `issued_at` | TIMESTAMPTZ | ❌ | Set when status → Issued |
| `updated_at` | TIMESTAMPTZ | ✅ | Auto |

#### Payment
| Attribute | Type | Required | Notes |
|-----------|------|----------|-------|
| `payment_id` | UUID | ✅ | Primary key |
| `invoice_id` | UUID | ✅ | FK → Invoice |
| `amount` | NUMERIC(10,2) | ✅ | |
| `payment_mode` | ENUM | ✅ | Cash / Card / UPI / Online |
| `transaction_id` | VARCHAR(200) | ❌ | Gateway reference |
| `status` | ENUM | ✅ | Success / Pending / Failed |
| `paid_at` | TIMESTAMPTZ | ✅ | |

#### AuditLog
| Attribute | Type | Required | Notes |
|-----------|------|----------|-------|
| `log_id` | UUID | ✅ | Primary key |
| `entity_type` | VARCHAR(50) | ✅ | Patient, Appointment, Invoice, etc. |
| `entity_id` | UUID | ✅ | ID of affected record |
| `action` | ENUM | ✅ | CREATE / UPDATE / DELETE |
| `performed_by` | UUID | ✅ | User ID |
| `timestamp` | TIMESTAMPTZ | ✅ | UTC |
| `changes_json` | JSONB | ✅ | Before/after field values |

#### User
| Attribute | Type | Required | Notes |
|-----------|------|----------|-------|
| `user_id` | UUID | ✅ | Primary key |
| `full_name` | VARCHAR(200) | ✅ | |
| `email` | VARCHAR(200) | ✅ | Unique |
| `password_hash` | VARCHAR(255) | ✅ | bcrypt |
| `role` | ENUM | ✅ | Receptionist / Doctor / Patient / SuperAdmin |
| `clinic_ids` | UUID[] | ❌ | Assigned clinics |
| `is_active` | BOOLEAN | ✅ | |
| `created_at` | TIMESTAMPTZ | ✅ | Auto |

---

## 10. Security & Compliance Requirements

### 10.1 Authentication & Authorisation
- Passwords hashed with **bcrypt** (work factor ≥ 12).
- JWT access tokens with ≤ 15 min expiry; refresh tokens with rotation.
- All API endpoints protected by RBAC middleware.
- Unauthenticated requests return HTTP 401; unauthorised access returns HTTP 403.

### 10.2 Data Encryption
- **At rest:** AES-256 for all stored patient and transaction data.
- **In transit:** TLS 1.2+ enforced on all connections.

### 10.3 DPDP Act 2023 Compliance
- Patient personal data (name, DOB, mobile, address, medical info) is sensitive personal data.
- Data collection limited to what is necessary for clinic operations (data minimisation).
- Data must not be shared with third parties without patient consent.
- Patients must be able to request deletion of their data subject to medical record retention requirements.
- Medical records must be retained for a minimum of **3 years** as per Indian law.

### 10.4 OWASP ASVS Alignment
- Input validation on all API endpoints.
- SQL injection prevention via ORM parameterisation.
- XSS prevention via Content Security Policy headers.
- CSRF protection on state-changing endpoints.
- Rate limiting on authentication endpoints.

### 10.5 Audit Trail
- Immutable AuditLog (no UPDATE or DELETE on log records).
- Log entries include before/after values for all entity changes.
- Accessible only to Super Administrator.

---

## 11. Acceptance Criteria

### 11.1 Dashboard
- [ ] KPI cards render on a neutral/white surface; no decorative color fills on card backgrounds.
- [ ] Color emphasis applied only through icons, status dots, or numeric values.
- [ ] Clinic selector is present and switches dashboard context to the selected clinic.

### 11.2 Patient Management
- [ ] Clicking **New Patient** opens a working registration form.
- [ ] Mandatory field validation is enforced; inline errors are shown.
- [ ] Successful save adds patient to list immediately with a success toast.
- [ ] Cancel closes the form without saving.
- [ ] All patient table action buttons are functional.

### 11.3 Appointment Management
- [ ] Clicking **Book Appointment** opens a working booking interface.
- [ ] Successful booking adds appointment to the list with a success toast.
- [ ] **Confirm** action updates status and shows toast.
- [ ] **Reschedule** opens editable date/time interface; updates appointment on save; shows toast.
- [ ] **Cancel** requires confirmation before status changes; shows toast.
- [ ] Previous date/time values are preserved in audit trail on reschedule.
- [ ] All 7 appointment statuses are supported and transition correctly.

### 11.4 Queue Management
- [ ] Queue board shows Waiting, In Consultation, Completed, No-Show states.
- [ ] System blocks moving a second patient to In Consultation when one is already active.
- [ ] Blocking action shows an explanatory message.
- [ ] Receptionist can access billing actions from a Waiting patient's queue entry.
- [ ] 7-day fee waiver rule is surfaced in the interface when applicable.

### 11.5 Invoice Management
- [ ] Clicking **New Invoice** opens a working invoice creation flow.
- [ ] Invoice can be created with zero consultation fee (medicine-only billing).
- [ ] Save Draft, Issue Invoice, View, Pay actions are all functional.
- [ ] Payment collection updates invoice to reflect paid/due amounts immediately.

### 11.6 Payment Management
- [ ] Payment collection form accepts amount, payment mode, and optional transaction reference.
- [ ] Successful payment shows success toast and updates ledger.
- [ ] Payment is linked to the originating invoice.

### 11.7 Interaction Standards
- [ ] No visible action button or CTA is a static placeholder.
- [ ] Every state-changing action shows immediate feedback.
- [ ] Error messages are specific and actionable.
- [ ] No layout breakage on tablet (768px+) or desktop (1024px+) screen sizes.

### 11.8 Doctor Interface
- [ ] Doctor can view their schedule on iPad.
- [ ] Doctor can write and save a prescription.
- [ ] Doctor can mark a consultation as Completed.
- [ ] Doctor can apply the fee waiver decision.

### 11.9 Patient Portal
- [ ] Patient can book an appointment and receive a confirmation notification.
- [ ] Patient can reschedule and cancel their own appointments.
- [ ] Patient can view their invoices and dues.

### 11.10 Security
- [ ] All endpoints require valid JWT; expired tokens are rejected.
- [ ] RBAC enforced — Receptionist cannot access Admin endpoints.
- [ ] AuditLog records created for all entity mutations.
- [ ] Data encrypted at rest and in transit.

---

## 12. Deployment Requirements

### 12.1 Infrastructure
- Backend deployed in Docker containers.
- Production: Kubernetes cluster with at least 2 replica sets for the API service.
- Single-clinic pilot: Docker Compose is acceptable.
- PostgreSQL 15 with daily automated backups and PITR.
- Redis 7 (optional) for session and pub/sub.
- HTTPS enforced via reverse proxy (Nginx / Caddy / Cloudflare).

### 12.2 CI/CD
- Source code hosted on GitHub (or equivalent).
- CI pipeline: automated tests (unit + integration) on every pull request.
- CD pipeline: automated deployment to staging on merge to `main`; production deploy is manual-approval gated.

### 12.3 Environment Configuration
- All secrets (DB credentials, JWT secret, payment gateway keys, SMS API keys) managed via environment variables or a secrets manager.
- No hardcoded credentials in source code.

### 12.4 Monitoring & Logging
- Structured JSON logs from all backend services forwarded to log aggregator (ELK or Loki/Grafana — TBD).
- Application health check endpoints exposed for Kubernetes liveness/readiness probes.
- Uptime monitoring configured (e.g., UptimeRobot / Grafana Alerting).

### 12.5 Database Migrations
- All schema changes managed via migration files (Alembic for SQLAlchemy).
- Migrations must be reversible where possible.
- Production migrations require a backup snapshot before execution.

---

## 13. Assumptions, Dependencies & Constraints

### 13.1 Assumptions
- The clinic has reliable broadband internet (≥ 5 Mbps). Offline mode is optional and not guaranteed in v1.
- Only one doctor operates across the two clinics.
- The clinic owner (Super Admin) is reasonably IT-literate for system configuration tasks.
- Patient mobile numbers are unique identifiers for patient lookup.

### 13.2 Dependencies
- Payment gateway integration depends on clinic's commercial agreement with Razorpay or PayTM.
- SMS/WhatsApp notifications require a registered account with the chosen provider (Twilio / MSG91).
- Apple Developer Program membership is required for Flutter iPad app distribution.
- Cloud hosting account (AWS / GCP / Azure / Hetzner) to be provisioned by the client.

### 13.3 Design Constraints
- UI must follow a clean, minimal, medical-operations aesthetic; no decorative card backgrounds.
- All visible controls must be functional — hidden or disabled (with explanation) if not yet available.
- Backend API must be versioned under `/api/v1/`.
- Flutter must be used for both web and iPad frontends to share business logic.

---

## 14. Out of Scope

The following are **explicitly excluded** from HCMS v1.0:

- GST invoicing on patient bills (only GST on supplier medicine procurement).
- Telemedicine / video consultation.
- Multi-doctor scheduling engine.
- Laboratory integration / test result management.
- Pharmacy stock management beyond low-stock alert.
- ABDM / Ayushman Bharat Digital Mission integration.
- Mobile app for patients (web portal only in v1).
- Offline-first PWA (optional stretch goal only).
- Advanced analytics / BI dashboards (basic reports only in v1).
- Insurance claim processing.

---

## 15. Open Items (TBD)

| # | Item | Owner | Target Resolution |
|---|------|-------|------------------|
| TBD-1 | Final payment gateway selection: Razorpay vs. PayTM vs. Stripe India | Clinic Owner | Before Sprint 3 kickoff |
| TBD-2 | SMS/WhatsApp provider selection and pricing model: Twilio vs. MSG91 | Dev Team | Before Sprint 2 kickoff |
| TBD-3 | Offline sync strategy: local storage approach and conflict resolution | Tech Lead | Before Sprint 4 kickoff |
| TBD-4 | Log aggregation toolchain: ELK Stack vs. Loki/Grafana | DevOps | Before Deployment Sprint |
| TBD-5 | Cloud hosting provider and environment provisioning | Clinic Owner / Dev Team | Before Sprint 1 kickoff |
| TBD-6 | Apple Developer Program account for iPad app distribution | Clinic Owner | Before Sprint 5 (Doctor UI) |
| TBD-7 | Exact appointment cancellation policy window (e.g., ≥ 2 hours before) | Clinic Owner | Before Sprint 2 kickoff |

---

## Appendix A — Glossary

| Term | Definition |
|------|-----------|
| Walk-in Patient | A patient arriving at the clinic without a prior appointment |
| Follow-up Visit | A return visit for a condition previously treated |
| Consultation Fee | The charge levied by the doctor per clinical consultation episode |
| Fee Waiver | Reduction of consultation fee to zero, applied at the doctor's discretion for qualifying revisits within 7 days |
| Invoice Draft | An invoice in preparation, not yet issued to the patient |
| Issued Invoice | A finalised invoice presented to the patient for payment |
| Ledger | Running record of all financial transactions for a patient or clinic |
| KPI | Key Performance Indicator — a summary metric shown on the dashboard |
| RBAC | Role-Based Access Control — access control model based on assigned roles |
| DPDP | Digital Personal Data Protection Act, India, 2023 |
| PITR | Point-in-Time Recovery — database backup capability |
| SAC | Services Accounting Code (used for GST classification of IT services) |

---

## Appendix B — Use Case Summary

| ID | Use Case | Primary Actor |
|----|----------|--------------|
| UC-01 | Register New Patient | Receptionist |
| UC-02 | Book Appointment | Receptionist / Patient |
| UC-03 | Confirm Appointment | Receptionist |
| UC-04 | Reschedule Appointment | Receptionist / Patient |
| UC-05 | Cancel Appointment | Receptionist / Patient |
| UC-06 | Manage Queue | Receptionist |
| UC-07 | Process Pre-Consultation Billing | Receptionist |
| UC-08 | Write Prescription | Doctor |
| UC-09 | Mark Consultation Completed | Doctor |
| UC-10 | Apply Fee Waiver | Doctor |
| UC-11 | Create Invoice | Receptionist |
| UC-12 | Collect Payment | Receptionist |
| UC-13 | Online Booking | Patient |
| UC-14 | View Invoice & Pay Online | Patient |
| UC-15 | Manage Users & Clinics | Super Admin |
| UC-16 | View Reports | Super Admin |
| UC-17 | View Audit Log | Super Admin |

---

*End of Document — HCMS PRD v4.0 — 22 June 2026*
*Supersedes all previous PRD versions. Ready for development sprint planning.*
