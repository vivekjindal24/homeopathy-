HCMS Receptionist Dashboard – Design Revision & Interaction Update

Apply the following improvements to the existing Receptionist Dashboard design.

GLOBAL DESIGN IMPROVEMENTS

* Remove all colored background cards from KPI widgets.
* Current cards look visually heavy and cheap.
* Use clean white cards with subtle shadows.
* Use color only on icons, status badges, indicators, and small accents.
* Maintain a premium healthcare SaaS appearance.
* Follow modern dashboard design patterns similar to Stripe, Linear, Notion, HubSpot, and Zoho.
* Increase whitespace consistency.
* Improve alignment and spacing.
* Use professional typography hierarchy.
* Make all buttons, links, actions, and CTAs appear interactive.
* Every action button should open its corresponding screen, modal, drawer, or workflow.
* Avoid dead-end UI elements.

---

DASHBOARD MODULE

Update KPI cards:

Current:

* Colored backgrounds

Replace with:

* White cards
* Colored icons only
* Clean metrics
* Small trend indicators

Cards:

* Today's Patients
* Active Queue
* Today's Revenue
* Pending Payments
* Low Stock Medicines
* Near Expiry Medicines

---

PATIENT MANAGEMENT MODULE

Patient table should include:

* Patient ID
* Name
* Mobile
* Age
* Last Visit
* Due Balance
* Actions

Top-right button:

ADD NEW PATIENT

This button must be interactive.

When clicked:

Open Add Patient Form Drawer or Modal.

Fields:

Mandatory:

* Full Name
* DOB / Age
* Gender
* Mobile Number
* Address
* Occupation

Optional:

* Email
* Blood Group
* Emergency Contact
* Allergies
* Chronic Conditions

Buttons:

* Save Patient
* Save & Book Appointment
* Cancel

Success Toast:
"Patient successfully registered."

---

APPOINTMENT MODULE

BOOK APPOINTMENT button must be interactive.

When clicked:

Open Appointment Creation Modal.

Fields:

* Search Patient
* Appointment Date
* Appointment Time
* Appointment Type
* Notes

Buttons:

* Book Appointment
* Cancel

Success Toast:
"Appointment booked successfully."

---

APPOINTMENT TABLE ACTIONS

Current actions:

* Confirm
* Reschedule
* Cancel

All actions must work visually.

CONFIRM

On click:
Show confirmation dialog.

Message:
"Confirm this appointment?"

After confirmation:
Status updates.

Toast:
"Patient appointment confirmed successfully."

---

RESCHEDULE

On click:
Open Reschedule Modal.

Fields:

* New Date
* New Time
* Reason

Buttons:

* Save
* Cancel

Toast:
"Appointment rescheduled successfully."

---

CANCEL

On click:
Open confirmation popup.

Message:
"Are you sure you want to cancel this appointment?"

Buttons:

* Yes Cancel
* Keep Appointment

Toast:
"Appointment cancelled successfully."

---

QUEUE MANAGEMENT MODULE

Improve queue logic representation.

Columns:

1. Waiting
2. In Consultation
3. Completed
4. No Show

Important:

IN CONSULTATION should display only ONE active patient at a time.

Reason:
Only one patient can be consulting with the doctor simultaneously.

The design should visually communicate this.

Use:

Large consultation card

Patient details:

* Token Number
* Name
* Start Time
* Doctor Name

Actions:

* Complete Consultation

---

WAITING QUEUE

Each waiting patient card:

* Token Number
* Patient Name
* Arrival Time
* Appointment Type

Actions:

* Start Consultation
* Mark No Show

Receptionist can collect consultation fees before consultation when applicable.

Some follow-up patients may not be charged.

Display:

Consultation Fee Status

Examples:

* Pending Payment
* Paid
* Follow-Up Exempt

---

COMPLETED QUEUE

Once consultation is completed:

Automatically move patient into completed section.

Generate:

* Visit Record
* Invoice
* Payment Flow

---

INVOICE MODULE

Remove colorful statistic cards.

Use clean white KPI cards.

Top-right:

NEW INVOICE button

Must be interactive.

When clicked:

Open Invoice Builder Screen.

Layout:

Left:
Patient Details

Center:
Invoice Line Items

Right:
Invoice Summary

Buttons:

* Save Draft
* Issue Invoice
* Generate PDF

All buttons should display resulting screens.

---

INVOICE TABLE ACTIONS

Current actions:

* View
* Pay

Both must work.

VIEW

Open Invoice Detail Drawer.

Show:

* Invoice Information
* Line Items
* Status
* Payment History

---

PAY

Open Payment Collection Modal.

Fields:

* Payment Mode
* Amount
* Notes

Buttons:

* Record Payment
* Cancel

Success Toast:

"Payment recorded successfully."

---

PAYMENT MODULE

Update dashboard cards:

White cards only.

Colored icons only.

Metrics:

* Cash
* UPI
* Card
* Pending Dues

---

PAYMENT TABLE ACTIONS

All actions must be clickable.

Receipt Action:

Open Receipt Preview.

Refund Action:

Open Refund Request Form.

Refund status:

* Pending Approval
* Approved
* Rejected

Receptionist cannot approve refunds.

---

GENERAL INTERACTIONS

Implement realistic UI behavior throughout the design.

Every:

* Button
* Action
* Link
* Menu Item
* Table Action
* Card Action

must visibly lead somewhere.

Use:

* Drawers
* Modals
* Dialogs
* Toast Notifications
* Success Screens
* Empty States
* Confirmation Screens

Do not leave any action without a resulting interface.

---

DESIGN QUALITY

Final design should feel:

* Enterprise SaaS
* Premium Healthcare Product
* Clean
* Minimal
* Pixel Perfect
* Production Ready

Avoid:

* Excessive colors
* Decorative gradients
* Background illustrations
* Fancy dashboard effects

Prioritize:
Functionality
Readability
Data Density
Operational Efficiency
Professional Clinic Management Experience
