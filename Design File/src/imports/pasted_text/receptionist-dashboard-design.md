Design a modern Healthcare Clinic Management Web Dashboard for the Receptionist role only.

Important:

* Doctor dashboard already exists and is already designed.
* Do NOT redesign doctor screens.
* Create only Receptionist workflow screens.
* The system starts with a Role Selection Page containing:

  * Doctor
  * Receptionist

Doctor card should navigate to existing doctor flow.

Receptionist card should navigate to a dedicated Receptionist Dashboard.

Create a complete web dashboard experience using modern SaaS dashboard patterns similar to Notion, Linear, Stripe Dashboard, Hubspot, Zoho, and modern Healthcare CRM systems.

Style:

* Professional healthcare management platform
* Responsive desktop-first design
* Clean layout
* Sidebar navigation
* Top header
* White and blue healthcare theme
* Minimal but data-rich interface
* Modern cards, tables, filters, drawers, and modals
* Optimized for reception staff managing daily clinic operations

---

## MAIN APPLICATION STRUCTURE

Layout:

Left Sidebar Navigation

* Dashboard
* Patients
* Appointments
* Queue Management
* Billing & Invoices
* Payments
* Inventory
* Reports
* Notifications
* Settings

Top Header

* Global Search
* Clinic Name
* Today's Date
* Notification Bell
* User Profile
* Logout

---

## RECEPTIONIST DASHBOARD

Design a command-center style dashboard.

Top KPI Cards:

* Today's Patients
* Active Queue
* Today's Revenue
* Pending Payments
* Low Stock Medicines
* Near Expiry Medicines

Middle Section:

Live Queue Widget

Columns:

* Waiting
* In Consultation
* Completed
* No Show

Appointment Overview

* Today's Appointments
* Walk Ins
* Follow Ups
* Cancelled

Bottom Section:

Recent Payments
Recent Patients
Recent Inventory Activities

Quick Actions Panel

* Register Patient
* Book Appointment
* Walk In Registration
* Generate Invoice
* Record Payment
* Add Stock Inward

---

## PATIENT MANAGEMENT

Patient List Page

Large searchable table.

Columns:

* Patient ID
* Name
* Mobile
* Age
* Gender
* Last Visit
* Outstanding Due
* Status

Filters:

* New
* Follow Up
* Active
* Archived

Actions:

* View Profile
* Edit
* New Appointment
* Generate Invoice

Patient Profile Page

Tabs:

* Overview
* Timeline
* Attachments
* Billing History
* Payment History

Right Panel:

* Upcoming Appointment
* Pending Dues
* Recent Activity

---

## APPOINTMENT MANAGEMENT

Calendar View

* Daily
* Weekly

Table View

Columns:

* Token
* Patient
* Appointment Time
* Status
* Doctor
* Type

Actions:

* Book
* Reschedule
* Cancel
* Confirm

Walk-In Registration Flow

Step 1:
Search Patient

Step 2:
Create New Patient if Needed

Step 3:
Create Appointment

Step 4:
Mark Arrived

Step 5:
Generate Token

Success Screen:
Display generated token number.

---

## QUEUE MANAGEMENT

This should be one of the strongest screens.

Real-Time Queue Board.

Columns:

WAITING
IN CONSULTATION
COMPLETED
NO SHOW

Queue Card:

* Token Number
* Patient Name
* Arrival Time
* Appointment Type

Actions:

* Mark Arrived
* Start Consultation
* Complete
* Mark No Show
* Requeue

Queue Summary:

* Total Waiting
* Average Waiting Time
* Total Completed Today

Display large token numbers.

Use status colors and queue analytics.

---

## BILLING & INVOICES

Invoice Dashboard

Metrics:

* Total Invoices
* Paid
* Partial
* Overdue
* Refunded

Invoice Table

Columns:

* Invoice Number
* Patient
* Date
* Amount
* Paid
* Due
* Status

Create Invoice Screen

Invoice Builder Layout

Left:
Patient Information

Center:
Line Items

Right:
Invoice Summary

Support:

* Consultation Fee
* Medicine Charges
* Registration Fee
* Procedure Charges
* Follow Up Package
* Miscellaneous

Discount Support:

* Percentage
* Fixed Amount

Mandatory Discount Reason

---

## PAYMENTS

Payments Dashboard

Metrics:

* Cash Collections
* UPI Collections
* Card Collections
* Pending Dues

Payment Table

Columns:

* Receipt No
* Patient
* Invoice
* Amount
* Mode
* Status
* Date

Payment Modal

Modes:

* Cash
* UPI
* Card
* Net Banking
* Wallet
* Payment Link
* Advance Payment

Support:

* Full Payment
* Partial Payment
* Split Payment

Receipt Generation Screen

Refund Request Flow

Receptionist can:

* Create refund request

Receptionist cannot:

* Approve refund

Refund Status:

* Pending Approval
* Approved
* Rejected

---

## INVENTORY MANAGEMENT

Inventory Dashboard

Cards:

* Total Medicines
* Low Stock
* Near Expiry
* Expired

Medicine Table

Columns:

* Medicine
* Potency
* Form
* Quantity
* Unit
* Batch Number
* Expiry Date

Stock Inward Form

Fields:

* Medicine
* Supplier
* Quantity
* Batch
* Expiry
* Purchase Rate

Stock Outward Form

Fields:

* Medicine
* Quantity
* Patient Visit Reference
* Notes

Stock Adjustment Modal

Reason Dropdown:

* Physical Count Correction
* Wastage
* Damage
* Expired Disposal

Alert Screens

* Low Stock Alert
* Near Expiry Alert

Movement History Timeline

Receptionist Permissions:

Allowed:

* View inventory
* Stock inward
* Stock outward
* Stock adjustment

Restricted:

* Add medicine master
* Edit medicine pricing
* Edit medicine potency
* Edit thresholds
* Delete stock records

---

## REPORTS

Day-End Summary Dashboard

Metrics:

* Revenue
* Collections
* Outstanding Dues
* Refund Requests

Charts:

* Revenue Trend
* Collection By Payment Mode
* Daily Patient Count

Export Actions:

* PDF
* Excel

---

## DESIGN OUTPUT

Generate all screens, states, dialogs, tables, drawers, modals, confirmation screens, empty states, success states, filters, and workflows required for a complete Receptionist Dashboard experience.

The result should look like a production-ready healthcare SaaS admin dashboard that integrates into an existing Doctor module through a role-selection entry screen.
