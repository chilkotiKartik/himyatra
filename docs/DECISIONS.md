# Architectural Decisions & Owner Confirmations

**Product Name:** HimYatra  
**Status:** Open for Owner Confirmation  
**Reference Document:** `Trekking_Management_Detailed_Project_Specification.pdf` (Section 15)  

---

## 1. Summary of Architectural Decisions

The original project specification highlights several operational edge cases where business requirements leave room for implementation choices. For each decision, a **Proposed Default** has been established to ensure a reliable, robust first version. These are cataloged below for explicit project owner review.

---

## 2. Decision Log

| # | Question / Ambiguity | Proposed Default (Adopted for Foundation) | Rationale | Owner Confirmation Status |
| :- | :--- | :--- | :--- | :--- |
| **DEC-001** | Can staff edit general trek details (title, dates, location)? | **No.** Only Administrators can alter trek names, locations, and schedules. Staff manage slot capacity and status (`Open`/`Closed`/`In Progress`/`Completed`). | Prevents guide itinerary drift and protects participant expectations once published. | Proposed Default |
| **DEC-002** | Can a trek have multiple assigned staff/guides? | **No.** Single primary guide assignment per trek for the MVP. | Keeps relational cardinality clean (1-to-many from staff to treks) without needing a many-to-many junction table. | Proposed Default |
| **DEC-003** | How should the "Started" trek state be formally represented? | **Add explicit `In Progress` status.** Transitions: `Open`/`Closed` $\to$ `In Progress` $\to$ `Completed`. | Eliminates ambiguity between open registrations and actively ongoing field expeditions. | Proposed Default |
| **DEC-004** | Can trekkers cancel their own active bookings? | **Yes, before the start date.** Booking status changes to `Cancelled`, and the slot is returned to available capacity. | Standard operational necessity; prevents dead capacity while preserving historical records. | Proposed Default |
| **DEC-005** | What occurs when an account with active bookings is blacklisted? | **Retain historical records; immediately block protected access.** Admin can review and cancel existing bookings manually if needed. | Preserves database integrity and prevents automatic cascading cancellation without admin awareness. | Proposed Default |
| **DEC-006** | Can an administrator physically delete a trek with existing bookings? | **No. Soft-delete / Archive (`is_archived = 1`) only.** Unbooked drafts may be permanently removed. | Guarantees that historical booking ledgers and participant safety records remain intact. | Proposed Default |
| **DEC-007** | Does closing a trek cancel existing bookings? | **No.** Setting status to `Closed` halts *new* bookings only. All confirmed reservations remain valid. | Closing is an administrative capacity cap or pre-departure freeze, not a cancellation. | Proposed Default |
| **DEC-008** | What happens if the start date arrives while status is still `Open`? | **Server refuses new bookings.** Server checks `CURRENT_DATE < start_date` during booking attempt. Guide/admin should mark `In Progress`. | Eliminates late bookings on ongoing treks without needing cron/background daemons. | Proposed Default |
| **DEC-009** | What happens to active `Booked` records when a trek is marked `Completed`? | **Transition active `Booked` records to `Completed`.** | Closes participant expedition lifecycle cleanly; distinguishes successful completions from cancellations. | Proposed Default |
| **DEC-010** | Can a trekker book the same trek again after cancelling? | **Yes, subject to capacity and date eligibility.** Past `Cancelled` row remains; new `Booked` row is inserted. | Supported by SQLite partial unique index (`WHERE status = 'Booked'`). | Proposed Default |
| **DEC-011** | Are online payments, live GPS tracking, or SMS gateways required? | **No. Strictly out of scope for MVP.** | Focuses development purely on core operational reliability, RBAC, and ACID concurrency. | Proposed Default |
