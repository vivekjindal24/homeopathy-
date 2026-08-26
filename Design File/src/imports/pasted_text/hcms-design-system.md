Design a complete UI/UX system and high-fidelity web app interface for a Homeopathic Clinic Management System (HCMS) for Dr. Vishvesh Kumar Verma Homeopathy Clinic, Indore, Madhya Pradesh, India. The product is a professional clinic operations platform used across three role-specific environments: Doctor on iPad, Receptionist on Android, and Administrator/Accountant on a web portal. Create the design language so it feels modern, minimal, calm, trustworthy, structured, and operationally efficient, with a premium healthcare workflow aesthetic rather than a generic SaaS startup dashboard. Figma should generate a real product experience, not a landing page.

The visual style should be minimal and professional, inspired by modern product dashboards and healthcare record systems, with strong information hierarchy, restrained use of color, highly readable typography, clean spacing, soft surfaces, subtle shadows, and compact but comfortable workflows. Use a neutral base palette with white or off-white surfaces, very light gray backgrounds, muted text hierarchy, and a restrained primary accent such as teal, slate blue, or medical green for focus, CTAs, active navigation, and status emphasis. Avoid loud gradients, neon highlights, decorative blobs, over-illustration, playful consumer-health styling, or marketing-style hero sections.

Design the system around role-based workflows instead of a single generic dashboard. The doctor experience should prioritize case taking, follow-up history, handwritten and digital prescription workflows, and a calm large-canvas consultation experience on iPad. The receptionist experience should prioritize fast patient registration, appointment booking, billing, payment collection, and receipt generation with minimal taps. The admin web portal should prioritize dashboards, financial oversight, reports, audit logs, system configuration, and operational analytics.

Create these primary information architecture sections:

Auth and role-based login

Dashboard

Patients

Appointments

Consultations / Case Taking

Prescriptions

Billing / Invoices

Payments / Refunds

Inventory

Expenses

Reports / Analytics

Notifications

Audit Logs

Settings / User Management

Design the following core screens in detail:

Login / Authentication

Secure login screen

Role-aware sign-in

Clean clinic branding

Professional, minimal healthcare tone

Optional device trust / biometric-friendly flow concept for doctor devices

Doctor iPad Dashboard

Today’s appointments

Waiting queue with token numbers

Follow-ups due

Recent patients

Quick actions: start consultation, open last prescription, create visit, write handwritten prescription

Large touch-friendly cards and split-view layout suitable for Apple Pencil workflow

Receptionist Dashboard

Fast new patient registration

Walk-in appointment booking

Today’s schedule

Pending payments

Quick invoice creation

Payment collection shortcuts

Compact, efficient layout optimized for fast front-desk use

Admin Dashboard

Daily revenue

Collections by payment mode

Pending dues

Appointment trends

Expense summary

Profit/loss snapshot

Patient retention widgets

Export/report shortcuts

Audit and reconciliation summary

Patient Registration Screen

Full patient intake form

Mandatory and optional patient fields

Patient code generation display

Profile photo upload

Attachments section

Searchable referred-by and medical history fields

Minimal, structured form UX with grouped sections and smart defaults

Patient List Screen

Search by name, mobile, patient code, visit date

Filter chips

Status and archive visibility

Sort options

Paginated table for admin/receptionist

Card/list hybrid for tablet

Very fast-scanning interface with sticky search and top filters

Patient Profile

Demographics summary

Medical history

Allergies

Chronic conditions

Attachments

Visit timeline

Prescriptions history

Billing history

Payments and receipts

Follow-up reminders

Layout should support a timeline-based clinical record view with clean tabs or segmented sections

Appointment Management

Daily and weekly calendar views

Queue/today list with token numbers

Walk-in flow

Status badges: scheduled, arrived, in consultation, completed, follow-up due, cancelled, no show

Reschedule interaction

Clear transitions and status handling

Case Taking / Consultation Screen

Large structured clinical form for homeopathic case taking

Sections for chief complaints, duration, onset, modalities, mental symptoms, physical generals, cravings, aversions, thirst, perspiration, bowel/bladder, sleep, dreams, thermal state, past history, family history, doctor notes

Doctor-friendly writing layout with distraction-free mode

Reusable case templates

Follow-up notes section

Timeline comparison with previous visits

Digital Prescription Screen

Structured medicine table with medicine name, potency, dosage, frequency, duration, instructions

Review date

Draft vs finalized state

PDF preview panel

Signature line area

Clean medical prescription layout that looks print-ready

Handwritten Prescription Experience

Full-screen iPad prescription canvas

Minimal chrome

A4/A5 portrait writing frame

Apple Pencil first interaction model

Save draft, finalize, new page, undo, clear, and patient/visit context always visible

History of all handwritten prescriptions in chronological order

Emphasize that finalized handwritten prescriptions are immutable

Billing / Invoice Screen

Draft invoice builder

Line items for consultation fee, medicine, procedure, registration fee, follow-up package, misc

Discount type and reason

Auto-calculated subtotal, total amount, paid amount, due amount

Draft, issued, partially paid, paid, overdue, cancelled, refunded states

PDF invoice preview/download action

Payment Collection Screen

Record cash, UPI, card, net banking, wallet, payment link, advance payment

Split payments

Partial payments

Due tracking

Receipt generation state

Razorpay initiation and link flow

Reconciliation-friendly cashier UI

Refund Management

Refund initiation

Admin approval state

Link to original payment

Clear audit visibility

High-trust financial UI styling with warning states handled carefully

Inventory Management

Medicine master

Supplier info

Batch number, potency, quantity, rates, expiry date

Stock inward/outward/adjustment

Low stock and expiry alerts

Dense but readable table-centered admin design

Expenses Module

Expense entry

Category breakdown

Receipt upload

Date and recorded-by visibility

Lightweight operational UI

Analytics / Reports

Revenue trends

Profit/loss

Collections by mode

Top services

Patient retention

Daily reconciliation

Use professional medical-admin analytics styling with clean charts, summary cards, and export actions

Audit Log

Immutable event log UI

Filter by entity type, user, action, date

Show before/after diff entry design

Make this dense, professional, traceable, and enterprise-like

Settings

Clinic profile

Doctor profile

Staff users and roles

Payment gateway settings

Notification preferences

Prescription templates

Session timeout and system configuration

UX constraints
Design the experience for real clinic operations, where staff are under time pressure and need clarity over visual flourish. Figma should optimize for short workflows such as patient search → new visit → prescription → bill, and registration → appointment → invoice → payment, keeping steps minimal and status always visible. Figma should also include loading states, empty states, inline errors, success confirmations, offline/sync indicators, and permission-aware screen differences by role.

Use these component patterns throughout:

Sidebar navigation for web portal

Top app bar with search, notifications, profile, and clinic switch/settings

KPI cards

Search bars with quick filters

Data tables with sticky headers

Status badges

Timeline components

Form sections with grouped fieldsets

PDF preview panels

Calendar and queue widgets

Tabs/segmented controls

Drawers/modals for quick actions

Toasts plus inline confirmations

Sync status and audit indicators

Visual direction
Use a healthcare operations aesthetic, not a hospital marketing aesthetic. The design should feel like a serious internal system for doctors and staff: calm, clean, clinical, efficient, compliant, readable, and modern. Prefer left-aligned layouts, compact dashboard typography, subtle borders, consistent spacing, restrained radius, and accessible contrast. Use iconography only to support scanning, not to dominate the interface.

Typography should be clean sans serif, compact, and highly legible. Use a strong page title, medium section headers, restrained body sizes, and clear table typography. Avoid oversized marketing headlines and avoid decorative illustration-heavy sections. Every screen should look implementation-ready for a real clinic software product.

Design system
Also generate a reusable design system / component library including:

Color tokens

Typography scale

Spacing system

Buttons

Inputs

Selects

Date pickers

Textareas

Tables

Status badges

Cards

Navigation

Tabs

Modals

Alerts

Empty states

File upload components

Timeline components

Calendar cells

Financial summary widgets

Prescription layout patterns

Print/PDF preview blocks

Output requirement
Generate:

Doctor iPad app key screens

Receptionist Android app key screens

Admin/accountant responsive web portal screens

A shared visual language across all three platforms

Light mode first, with optional dark mode-ready tokenization

High-fidelity flows for Phase 1 modules first: patients, appointments, consultation, digital prescription, handwritten prescription, billing, payments, basic analytics