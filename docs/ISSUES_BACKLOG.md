# GitHub Backlog & Milestone Specifications

This document catalogs the complete development backlog of 28 actionable, scoped, and prioritized issues for **HimYatra**, organized into six milestones (**M0** through **M5**).

---

## Milestone Summary

| Milestone | Title | Focus Area | Issue Count |
| :--- | :--- | :--- | :---: |
| **M0** | Foundation & Project Infrastructure | Docs, tooling, Flask architecture, SQLite schema | 4 |
| **M1** | Identity, Authentication & RBAC | Multi-role registration, login, seeding, blacklisting | 5 |
| **M2** | Administrator Operations | Dashboard metrics, trek CRUD, staff vetting, accounts | 5 |
| **M3** | Trek Staff Expedition Management | Assigned dashboard, participant roster, slots & progress | 4 |
| **M4** | Trekker Discovery & Booking Ledger | Expedition search/filter, detail view, bookings, cancellations | 5 |
| **M5** | Reliability, Concurrency & Release | Atomic transactions, test suites, demo seeding, zero-JS validation | 5 |

---

## Milestone M0: Foundation & Project Infrastructure

### Issue #1: [TASK]: Establish Repository Architecture, Tooling, and Linters
* **Milestone:** M0 — Foundation
* **Labels:** `type: task`, `priority: high`, `area: infrastructure`
* **PRD References:** NFR-001, NFR-002
* **Objective:** Configure standard Python project tooling, directory hierarchy, and version control hygiene.
* **Scope:**
  - Create directory skeleton (`app/`, `tests/`, `instance/`, `docs/`).
  - Configure `.gitignore`, `.editorconfig`, and `.gitattributes`.
  - Create `requirements.txt` pinning Flask, Werkzeug, pytest, and development tools.
* **Acceptance Criteria:**
  - [ ] Virtual environment installs all pinned packages cleanly.
  - [ ] Git ignores `.db`, `.sqlite`, `instance/`, and `__pycache__`.
* **Dependencies:** None

### Issue #2: [TASK]: Design SQLite DDL Schema and Connection Manager
* **Milestone:** M0 — Foundation
* **Labels:** `type: task`, `priority: critical`, `area: database`
* **PRD References:** FR-004, BR-001, BR-005, SEC-003
* **Objective:** Create the SQLite schema file and connection factory with foreign key enforcement.
* **Scope:**
  - Create `app/schema.sql` defining `accounts`, `staff_profiles`, `treks`, `bookings`, and `audit_logs`.
  - Add SQLite CHECK constraints for roles, statuses, difficulty, and capacity floor.
  - Add partial unique index on `bookings(user_id, trek_id) WHERE status = 'Booked'`.
  - Create `app/database.py` with `PRAGMA foreign_keys = ON;` and `sqlite3.Row` factory.
* **Acceptance Criteria:**
  - [ ] Foreign keys reject orphaned records.
  - [ ] Partial unique index prevents duplicate `Booked` rows while permitting re-booking after `Cancelled`.
* **Dependencies:** #1

### Issue #3: [TASK]: Implement Flask Application Factory and Environment Configuration
* **Milestone:** M0 — Foundation
* **Labels:** `type: task`, `priority: high`, `area: backend`
* **PRD References:** NFR-004, SEC-002
* **Objective:** Implement modular Flask `create_app` factory supporting Development and Testing modes.
* **Scope:**
  - Create `app/config.py` with secret key management and SQLite database paths.
  - Implement `create_app()` in `app/__init__.py`.
  - Configure CSRF protection and Blueprint registration hooks.
* **Acceptance Criteria:**
  - [ ] App initializes cleanly via `wsgi.py`.
  - [ ] Testing configuration points to in-memory or isolated test SQLite database.
* **Dependencies:** #1, #2

### Issue #4: [TASK]: Create Base Jinja2 Templates and Mountain Aesthetic Design System
* **Milestone:** M0 — Foundation
* **Labels:** `type: task`, `priority: medium`, `area: frontend`
* **PRD References:** NFR-001, NFR-002
* **Objective:** Establish the server-side rendered UI foundation with Bootstrap 5 and custom mountain aesthetic styling.
* **Scope:**
  - Create `app/templates/base.html` with responsive navbar, flash message alerts, and role-aware navigation.
  - Create `app/static/css/custom.css` with clean Himalayan color palette, typography, and badges.
  - Create error templates (`400.html`, `403.html`, `404.html`, `500.html`).
* **Acceptance Criteria:**
  - [ ] Navbar adapts dynamically based on session role.
  - [ ] Layout renders cleanly on both mobile (375px) and desktop screens without JS.
* **Dependencies:** #3

---

## Milestone M1: Identity, Authentication & RBAC

### Issue #5: [TASK]: Programmatic Administrator Seeding CLI
* **Milestone:** M1 — Authentication
* **Labels:** `type: task`, `priority: critical`, `area: auth`
* **PRD References:** FR-003, FR-004, AC-001
* **Objective:** Create programmatic setup command to seed initial administrator without public registration.
* **Scope:**
  - Add `flask init-db` and `flask seed-admin` CLI commands in `app/cli.py`.
  - Verify admin password hashing and idempotent execution (no duplicate error on repeated runs).
* **Acceptance Criteria:**
  - [ ] Admin account created with role `admin` and status `Active`.
  - [ ] Public routes for admin registration return 404.
* **Dependencies:** #2, #3

### Issue #6: [FEAT]: Trekker Registration and Account Creation
* **Milestone:** M1 — Authentication
* **Labels:** `type: feature`, `priority: high`, `area: auth`
* **PRD References:** FR-001, FR-005, T-01
* **Objective:** Implement public registration flow for trekkers at `/register/user`.
* **Scope:**
  - Create registration form validating full name, unique email, phone, and password confirmation.
  - Securely hash password and store account with role `user` and status `Active`.
  - Auto-login or redirect to login with flash notification.
* **Acceptance Criteria:**
  - [ ] Duplicate email registration is blocked with friendly error message.
  - [ ] Passwords hashed using Werkzeug `generate_password_hash`.
* **Dependencies:** #2, #4

### Issue #7: [FEAT]: Staff Application Registration with Pending Vetting State
* **Milestone:** M1 — Authentication
* **Labels:** `type: feature`, `priority: high`, `area: auth`
* **PRD References:** FR-001, FR-002, T-02
* **Objective:** Implement guide application registration at `/register/staff`.
* **Scope:**
  - Collect name, email, phone, mountain experience notes, and password.
  - Insert `accounts` row with role `staff`, and `staff_profiles` row with `approval_status = 'Pending'`.
* **Acceptance Criteria:**
  - [ ] Account created in Pending state.
  - [ ] Logging in displays informational notice: "Approval Pending. Awaiting administrative review."
  - [ ] Guide cannot access any `/staff/*` operational routes while Pending.
* **Dependencies:** #2, #4

### Issue #8: [FEAT]: Unified Authentication, Login, and Role-Aware Routing
* **Milestone:** M1 — Authentication
* **Labels:** `type: feature`, `priority: critical`, `area: auth`
* **PRD References:** FR-006, FR-009, SEC-005
* **Objective:** Implement universal login route (`/login`) with role-based routing and session handling.
* **Scope:**
  - Validate credentials against `accounts` table.
  - Route admin $\to$ `/admin`, approved staff $\to$ `/staff`, pending staff $\to$ notice page, user $\to$ `/user`.
  - Implement `/logout` POST endpoint that invalidates session and redirects to home.
* **Acceptance Criteria:**
  - [ ] Invalid credentials return generic failure notice without disclosing email existence.
  - [ ] Post/Redirect/Get flow implemented.
* **Dependencies:** #5, #6, #7

### Issue #9: [TASK]: Server-Side Authorization Decorators and Blacklist Barrier
* **Milestone:** M1 — Authentication
* **Labels:** `type: task`, `priority: critical`, `area: security`
* **PRD References:** FR-007, SEC-005, SEC-007, T-17
* **Objective:** Implement route protection decorators and immediate session invalidation on blacklist.
* **Scope:**
  - Implement `@login_required`, `@role_required(...)`, and `@verified_staff_required`.
  - Add `load_logged_in_user` hook that queries DB account status on every request.
  - Terminate session immediately if `account_status == 'Blacklisted'`.
* **Acceptance Criteria:**
  - [ ] Direct URL tampering by unauthorized roles returns HTTP 403 Forbidden.
  - [ ] Blacklisting a user terminates their active session on their next request.
* **Dependencies:** #8

---

## Milestone M2: Administrator Operations

### Issue #10: [FEAT]: Administrator Metrics Dashboard
* **Milestone:** M2 — Administrator
* **Labels:** `type: feature`, `priority: high`, `area: admin`
* **PRD References:** FR-010
* **Objective:** Build `/admin` dashboard displaying real-time operational database counters.
* **Scope:**
  - Query counts: Total Treks, Total Active Trekkers, Total Staff, Total Bookings, Pending Staff, Open Treks.
  - Render responsive dashboard cards and navigation quick links.
* **Acceptance Criteria:**
  - [ ] Counters reflect exact live SQLite records, never hard-coded.
* **Dependencies:** #9

### Issue #11: [FEAT]: Trek Creation and Lifecycle Administration
* **Milestone:** M2 — Administrator
* **Labels:** `type: feature`, `priority: critical`, `area: admin`
* **PRD References:** FR-011, BR-001, T-05, T-06
* **Objective:** Implement `/admin/treks/new` and trek management views.
* **Scope:**
  - Form fields: Name, description, location, difficulty, duration, total slots, dates, initial status.
  - Server-side validation: `end_date >= start_date`, `duration > 0`, `total_slots >= 0`.
* **Acceptance Criteria:**
  - [ ] Invalid parameters rejected with field-specific errors.
  - [ ] New trek persists in SQLite and appears in admin trek directory.
* **Dependencies:** #9, #10

### Issue #12: [FEAT]: Guide Assignment and Reassignment Engine
* **Milestone:** M2 — Administrator
* **Labels:** `type: feature`, `priority: high`, `area: admin`
* **PRD References:** FR-012, BR-008, T-07
* **Objective:** Enable administrators to assign approved guides to treks.
* **Scope:**
  - Populate guide selector only with staff accounts where `approval_status == 'Approved'` and `account_status == 'Active'`.
  - Support guide reassignment from `/admin/treks/<id>/edit`.
* **Acceptance Criteria:**
  - [ ] Pending or blacklisted staff do not appear in guide dropdown and are rejected if submitted.
* **Dependencies:** #11

### Issue #13: [FEAT]: Staff Approval Queue and Vetting Portal
* **Milestone:** M2 — Administrator
* **Labels:** `type: feature`, `priority: high`, `area: admin`
* **PRD References:** FR-014, T-03
* **Objective:** Build dedicated interface at `/admin/staff` for reviewing pending guide applications.
* **Scope:**
  - List pending staff with full name, contact details, experience notes, and application date.
  - Implement atomic `Approve` and `Blacklist` action buttons.
* **Acceptance Criteria:**
  - [ ] Approving a staff member immediately allows them to access `/staff`.
* **Dependencies:** #9, #10

### Issue #14: [FEAT]: Account Search, Directory, and Blacklisting Controls
* **Milestone:** M2 — Administrator
* **Labels:** `type: feature`, `priority: medium`, `area: admin`
* **PRD References:** FR-015, T-18
* **Objective:** Implement `/admin/accounts` with search capabilities and account deactivation.
* **Scope:**
  - Search by name fragment or numeric account ID via GET form parameters.
  - Implement toggle action to Blacklist or Restore user and staff accounts.
* **Acceptance Criteria:**
  - [ ] Search queries safely parameterized without SQL injection vulnerabilities.
* **Dependencies:** #9, #10

---

## Milestone M3: Trek Staff Expedition Management

### Issue #15: [FEAT]: Staff Expedition Dashboard and Assignment Filter
* **Milestone:** M3 — Staff
* **Labels:** `type: feature`, `priority: high`, `area: staff`
* **PRD References:** FR-017, T-08
* **Objective:** Build `/staff` dashboard displaying only treks assigned to the authenticated guide.
* **Scope:**
  - Query treks where `assigned_staff_id == session['user_id']`.
  - Display slots, booked participants, remaining seats, and current status.
  - Display explicit empty state ("No treks assigned yet") when unassigned.
* **Acceptance Criteria:**
  - [ ] Guide cannot see or access other guides' expeditions.
* **Dependencies:** #9, #12

### Issue #16: [FEAT]: Participant Roster View for Assigned Treks
* **Milestone:** M3 — Staff
* **Labels:** `type: feature`, `priority: high`, `area: staff`
* **PRD References:** FR-018, FR-019, SEC-006
* **Objective:** Provide assigned guides with real-time participant roster at `/staff/treks/<id>`.
* **Scope:**
  - Display Booking ID, Trekker Full Name, Phone, Booking Date, and Status.
  - Assert ownership: return HTTP 403 if requested trek is not assigned to current guide.
* **Acceptance Criteria:**
  - [ ] Guide A cannot view Guide B's participant roster via direct URL tampering.
* **Dependencies:** #15

### Issue #17: [FEAT]: Staff Slot Capacity Adjustment with Safety Floor
* **Milestone:** M3 — Staff
* **Labels:** `type: feature`, `priority: high`, `area: staff`
* **PRD References:** FR-020, BR-004, T-14
* **Objective:** Allow staff to adjust total expedition slots within safe bounds.
* **Scope:**
  - Form to update `total_slots` on assigned trek.
  - Validate that `new_total_slots >= current_booked_count`.
* **Acceptance Criteria:**
  - [ ] Reducing capacity below active `Booked` count is blocked with a validation error.
* **Dependencies:** #16

### Issue #18: [FEAT]: Expedition Start and Completion Workflow
* **Milestone:** M3 — Staff
* **Labels:** `type: feature`, `priority: high`, `area: staff`
* **PRD References:** FR-021, FR-022, FR-023, BR-010, T-16
* **Objective:** Implement trek progress transitions: Open/Closed $\to$ `In Progress` $\to$ `Completed`.
* **Scope:**
  - Start action sets status `In Progress` and blocks any future bookings.
  - Complete action sets status `Completed` and updates active participant bookings to `Completed`.
* **Acceptance Criteria:**
  - [ ] Completed treks cannot be reopened.
  - [ ] Participant records transition to `Completed` with timestamp.
* **Dependencies:** #16

---

## Milestone M4: Trekker Discovery & Booking Ledger

### Issue #19: [FEAT]: Trekker Home Dashboard and Activity Overview
* **Milestone:** M4 — Trekker
* **Labels:** `type: feature`, `priority: medium`, `area: trekker`
* **PRD References:** FR-024
* **Objective:** Build `/user` dashboard summarizing active and completed personal reservations.
* **Scope:**
  - Display metrics for personal Booked, Cancelled, and Completed reservations.
  - Feature carousel / list of upcoming open Himalayan expeditions.
* **Acceptance Criteria:**
  - [ ] Only personal records of the logged-in user are shown.
* **Dependencies:** #8, #9

### Issue #20: [FEAT]: Expedition Catalog with Multi-Parameter Search and Filtering
* **Milestone:** M4 — Trekker
* **Labels:** `type: feature`, `priority: high`, `area: trekker`
* **PRD References:** FR-025, T-09
* **Objective:** Implement `/treks` discovery portal with location search and difficulty filters.
* **Scope:**
  - Filter by difficulty (`Easy`, `Moderate`, `Hard`) and search text for name/location.
  - Restrict results to `status = 'Open'`, `is_archived = 0`, and `start_date > CURRENT_DATE`.
* **Acceptance Criteria:**
  - [ ] Works cleanly via GET form parameters without JavaScript.
  - [ ] Combined filters yield accurate intersections.
* **Dependencies:** #11

### Issue #21: [FEAT]: Trek Detail Page and Availability Computation
* **Milestone:** M4 — Trekker
* **Labels:** `type: feature`, `priority: high`, `area: trekker`
* **PRD References:** FR-026, BR-002, BR-003
* **Objective:** Build `/treks/<id>` detail view with live slot availability indicator.
* **Scope:**
  - Display description, difficulty badge, dates, duration, guide name, and remaining seats.
  - Render "Book Now" button only if user is logged in, trek is Open, and available slots > 0.
* **Acceptance Criteria:**
  - [ ] Displays "Fully Booked" badge when remaining slots reach 0.
* **Dependencies:** #20

### Issue #22: [FEAT]: Personal Booking Ledger and Historical Timeline
* **Milestone:** M4 — Trekker
* **Labels:** `type: feature`, `priority: high`, `area: trekker`
* **PRD References:** FR-028
* **Objective:** Implement `/user/bookings` showing complete personal reservation history.
* **Scope:**
  - Display trek name, dates, booking timestamp, and status (`Booked`, `Cancelled`, `Completed`).
  - Provide "Cancel" action button for eligible upcoming reservations.
* **Acceptance Criteria:**
  - [ ] Cancelled and completed reservations remain visible in personal history.
* **Dependencies:** #19

### Issue #23: [FEAT]: Self-Service Booking Cancellation and Slot Release
* **Milestone:** M4 — Trekker
* **Labels:** `type: feature`, `priority: high`, `area: trekker`
* **PRD References:** FR-029, BR-003, T-15
* **Objective:** Allow trekkers to cancel reservations before expedition start date.
* **Scope:**
  - POST endpoint `/user/bookings/<id>/cancel`.
  - Validate ownership and assert `start_date > CURRENT_DATE`.
  - Update status to `Cancelled` with timestamp.
* **Acceptance Criteria:**
  - [ ] Booking row is preserved (never deleted).
  - [ ] Available slots on the trek immediately increases by 1.
* **Dependencies:** #22

---

## Milestone M5: Reliability, Concurrency & Release

### Issue #24: [FEAT]: Atomic Booking Transaction Engine with SQLite Write Locking
* **Milestone:** M5 — Reliability
* **Labels:** `type: feature`, `priority: critical`, `area: database`
* **PRD References:** FR-027, BR-006, SEC-003, T-11, T-12, T-13
* **Objective:** Implement atomic reservation transaction using `BEGIN IMMEDIATE` to prevent race conditions.
* **Scope:**
  - In `BookingService.reserve_slot`, acquire immediate transaction write lock.
  - Atomically re-verify: status is Open, not archived, date in future, no duplicate active booking, capacity remains.
  - Insert booking and commit; rollback on failure.
* **Acceptance Criteria:**
  - [ ] Multi-threaded concurrent test for last seat results in exactly 1 booking and 0 overselling.
* **Dependencies:** #2, #21

### Issue #25: [TASK]: Trek Archiving and Soft-Delete Implementation
* **Milestone:** M5 — Reliability
* **Labels:** `type: task`, `priority: high`, `area: admin`
* **PRD References:** FR-013, BR-009, DEC-006
* **Objective:** Implement safe archiving for treks with booking histories.
* **Scope:**
  - Admin archive action sets `is_archived = 1`.
  - Filter out archived treks from public discovery while retaining them in admin audit logs and participant booking histories.
* **Acceptance Criteria:**
  - [ ] Deleting or archiving a booked trek does not corrupt foreign key relations or wipe user history.
* **Dependencies:** #11, #22

### Issue #26: [TASK]: Comprehensive Automated Test Suite
* **Milestone:** M5 — Reliability
* **Labels:** `type: task`, `priority: critical`, `area: testing`
* **PRD References:** T-01 through T-20
* **Objective:** Implement test suites covering unit logic, integration routes, RBAC, and concurrency.
* **Scope:**
  - `tests/test_auth.py`
  - `tests/test_admin.py`
  - `tests/test_staff.py`
  - `tests/test_booking.py`
  - `tests/test_concurrency.py`
* **Acceptance Criteria:**
  - [ ] All 20 functional test checklist scenarios pass automatically.
* **Dependencies:** #24, #25

### Issue #27: [TASK]: Realistic Himalayan Expedition Demo Data Seeder
* **Milestone:** M5 — Reliability
* **Labels:** `type: task`, `priority: medium`, `area: infrastructure`
* **PRD References:** AC-010, Section 13.3
* **Objective:** Create `flask seed-demo` command populating a realistic demonstration dataset.
* **Scope:**
  - 1 Admin account.
  - 2 Staff accounts (1 Approved guide with experience notes, 1 Pending).
  - 3 Trekkers.
  - 4 Himalayan treks (Kedarkantha, Valley of Flowers, Har Ki Dun, Roopkund) across Open, In Progress, and Completed states.
  - Pre-populated bookings with a nearly full expedition (1 seat remaining).
* **Acceptance Criteria:**
  - [ ] Evaluators can immediately test last-seat booking, approval workflows, and historical views out of the box.
* **Dependencies:** #24, #26

### Issue #28: [TASK]: Zero-JavaScript Usability and Cross-Browser Accessibility Audit
* **Milestone:** M5 — Reliability
* **Labels:** `type: task`, `priority: high`, `area: frontend`
* **PRD References:** NFR-001, NFR-002, T-20
* **Objective:** Verify and audit that all application workflows function with JavaScript completely disabled.
* **Scope:**
  - Audit all forms for native HTML5 validation and fallback server-side rendering.
  - Ensure Post/Redirect/Get pattern prevents duplicate submissions on refresh.
  - Verify semantic heading hierarchy and screen-reader form labels.
* **Acceptance Criteria:**
  - [ ] Full end-to-end demo passes in browser with JavaScript disabled.
* **Dependencies:** #26, #27
