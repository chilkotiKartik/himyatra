# HimYatra

> **Your Mountains. Your Journey. One Connected Expedition.**

[![Python](https://img.shields.io/badge/Python-3.10%2B-blue.svg)](https://www.python.org/)
[![Flask](https://img.shields.io/badge/Flask-3.0%2B-black.svg)](https://flask.palletsprojects.com/)
[![SQLite](https://img.shields.io/badge/SQLite-3-lightgrey.svg)](https://www.sqlite.org/)
[![Bootstrap](https://img.shields.io/badge/Bootstrap-5.3-purple.svg)](https://getbootstrap.com/)
[![Project Status](https://img.shields.io/badge/Status-Foundation%20Phase-orange.svg)](#project-status)

HimYatra is a centralized Himalayan trekking and expedition operations management platform inspired by the rugged trails and expedition culture of Uttarakhand (Roopkund, Kedarkantha, Valley of Flowers, Har Ki Dun, Kuari Pass). 

It is engineered as an operational management system—not a generic commercial travel aggregator—delivering strict capacity controls, verified guide dispatch, multi-role governance, and immutable expedition audit trails.

---

## Project Status

> [!IMPORTANT]
> **Current Phase: Foundation & Specification.**  
> The project architecture, authoritative PRD, SQLite schema design, security controls, and development backlog are fully established. No application code has been implemented in this phase, preserving a clean boundary for disciplined development.

---

## Problem & Solution

### The Operational Challenge
Trekking organizations traditionally manage expedition schedules, slots, and field guides across ad-hoc spreadsheets and messaging threads. This creates acute operational risks:
* **Overbooking & Capacity Overselling:** Concurrent inquiries lead to more registrations than permitted camping or environmental quotas allow.
* **Unvetted Staff Dispatch:** Guides leading expeditions without prior administrative vetting, verification of mountain safety credentials, or clear operational assignment.
* **Data Desynchronization & Lost History:** Cancellations and completed treks are often overwritten or deleted, destroying participant safety records and historical records.
* **Insecure Role Isolation:** Staff altering expeditions managed by other guides, or trekkers accessing administrative registers.

### The HimYatra Solution
HimYatra consolidates expedition operations into a secure, server-rendered web application with:
1. **Dynamic Capacity Integrity:** Slot availability is derived in real time (`total_slots - active_booked_reservations`), protected against overselling down to the last seat via serialized SQLite write transactions.
2. **Three-Tier Role-Based Access Control (RBAC):** Distinct operational interfaces for Administrators, Approved Guides, and Trekkers.
3. **Staff Vetting Workflow:** Guide registrations enter a `Pending` state and are quarantined from operational dashboards until vetted and approved by an administrator.
4. **Permanent Audit Trail:** Historical reservations, cancellations, and completed expeditions are retained permanently for reporting and safety compliance.
5. **Zero-Client Fragility:** 100% of core operational workflows function seamlessly with client-side JavaScript disabled.

---

## Technology Stack

HimYatra strictly adheres to a robust, self-contained technology stack requiring zero external database installations or paid cloud services:

| Layer | Technology | Specification Mandate |
| :--- | :--- | :--- |
| **Backend** | Python 3.10+ | Core language |
| **Web Framework** | Flask 3.0+ | Server-side routing, request handling, session management |
| **Templating** | Jinja2 + HTML5 | Server-rendered dynamic pages and modular components |
| **Frontend Styling**| Vanilla CSS + Bootstrap 5 | Mountain-inspired responsive design system |
| **Database** | SQLite 3 | Embedded SQL engine with foreign keys and serialized transactions |
| **Client Scripting**| Optional Enhancement | Core operations **must work without JavaScript** |

*Note: Client-side SPA frameworks (React, Next.js, Vue), external database servers (PostgreSQL, MySQL, MongoDB), and background workers (Redis, Celery) are explicitly excluded from the core architecture.*

---

## System Architecture

```mermaid
flowchart TD
    Client[Browser / User Agent] -->|HTTP GET / POST| Flask[Flask Application]
    Flask --> CSRF[CSRF Protection]
    CSRF --> Session[Session Manager]
    Session --> RBAC[Role-Based Access Control]
    
    subgraph Modular Blueprints
        RBAC --> AuthBP[Auth Controller]
        RBAC --> AdminBP[Admin Controller]
        RBAC --> StaffBP[Staff Controller]
        RBAC --> TrekkerBP[Trekker Controller]
        RBAC --> PublicBP[Public Controller]
    end

    subgraph Domain Services
        AdminBP --> AdminService[Admin Service]
        StaffBP --> StaffService[Staff Service]
        TrekkerBP --> BookingService[Booking & Capacity Service]
        TrekkerBP --> DiscoveryService[Discovery Service]
    end

    subgraph Storage Layer
        AdminService --> DB[(SQLite Embedded Database)]
        StaffService --> DB
        BookingService -->|BEGIN IMMEDIATE Write Lock| DB
        DiscoveryService --> DB
    end
```

---

## Role Permissions Matrix

| Capability / Action | Administrator (`admin`) | Approved Staff (`staff`) | Pending Staff | Trekker (`user`) |
| :--- | :---: | :---: | :---: | :---: |
| Self-Registration | ❌ (Pre-seeded only) | ❌ | ✅ Application form | ✅ User form |
| Login / Dashboard Access | ✅ `/admin` | ✅ `/staff` | ❌ Pending notice | ✅ `/user` |
| Create & Archive Treks | ✅ | ❌ | ❌ | ❌ |
| Edit Trek Core Details (Dates, Location) | ✅ | ❌ | ❌ | ❌ |
| Assign / Reassign Guides | ✅ | ❌ | ❌ | ❌ |
| Approve / Blacklist Staff | ✅ | ❌ | ❌ | ❌ |
| Blacklist Users | ✅ | ❌ | ❌ | ❌ |
| View System-Wide Booking Ledger | ✅ Global | ❌ | ❌ | ❌ |
| View Participant Roster | ✅ Global | ✅ Assigned trek only | ❌ | ❌ |
| Adjust Trek Slot Capacity | ✅ | ✅ (Floor: $\ge$ Booked) | ❌ | ❌ |
| Open / Close Trek Bookings | ✅ | ✅ Assigned trek only | ❌ | ❌ |
| Mark Trek `In Progress` / `Completed` | ✅ | ✅ Assigned trek only | ❌ | ❌ |
| Search & Filter Open Treks | ✅ | ✅ | ✅ | ✅ `/treks` |
| Book Open Expedition | ❌ | ❌ | ❌ | ✅ If slots available |
| Cancel Active Reservation | ❌ | ❌ | ❌ | ✅ Before start date |
| View Personal Booking History | ❌ (Admin ledger) | ❌ | ❌ | ✅ Own records only |
| Edit Profile Details | Optional | Recommended | ❌ | ✅ |

---

## Database Design

The system runs on a locally managed SQLite database with foreign key enforcement (`PRAGMA foreign_keys = ON;`).

```mermaid
erDiagram
    ACCOUNTS ||--o| STAFF_PROFILES : "has profile (if staff)"
    ACCOUNTS ||--o{ TREKS : "guides (assigned staff)"
    ACCOUNTS ||--o{ BOOKINGS : "reserves (trekker)"
    TREKS ||--o{ BOOKINGS : "contains"
    ACCOUNTS ||--o{ STAFF_PROFILES : "approves (admin)"

    ACCOUNTS {
        INTEGER id PK
        TEXT full_name
        TEXT email UK
        TEXT password_hash
        TEXT phone
        TEXT role "admin | staff | user"
        TEXT account_status "Active | Blacklisted"
        TEXT created_at
    }

    STAFF_PROFILES {
        INTEGER staff_id PK
        INTEGER account_id FK, UK
        TEXT approval_status "Pending | Approved | Blacklisted"
        TEXT experience_notes
        TEXT approved_at
        INTEGER approved_by FK
    }

    TREKS {
        INTEGER id PK
        TEXT name
        TEXT description
        TEXT location
        TEXT difficulty "Easy | Moderate | Hard"
        INTEGER duration_days
        INTEGER total_slots
        INTEGER assigned_staff_id FK
        TEXT status "Pending | Approved | Open | Closed | In Progress | Completed"
        TEXT start_date
        TEXT end_date
        INTEGER is_archived
        TEXT created_at
        TEXT updated_at
    }

    BOOKINGS {
        INTEGER id PK
        INTEGER user_id FK
        INTEGER trek_id FK
        TEXT booking_date
        TEXT status "Booked | Cancelled | Completed"
        TEXT cancelled_at
        TEXT completed_at
    }
```

### Core Integrity Constraints
1. **Dynamic Capacity Formula:**  
   $$\text{Available Slots} = \max\left(0, \text{total\_slots} - \text{COUNT}(\text{Bookings where } status = \text{'Booked'})\right)$$
2. **Duplicate Booking Prevention:** Enforced at both service level and database level via partial unique index:
   ```sql
   CREATE UNIQUE INDEX uq_active_booking_user_trek 
   ON bookings (user_id, trek_id) 
   WHERE status = 'Booked';
   ```
3. **Safe Capacity Floor:** Updates to `total_slots` must satisfy $\text{total\_slots} \ge \text{active Booked count}$.

---

## Trek Lifecycle

Treks progress through six distinct operational states:

```mermaid
stateDiagram-v2
    [*] --> Pending: Admin creates draft trek
    Pending --> Approved: Admin reviews and schedules
    Approved --> Open: Admin or Guide opens bookings
    Open --> Closed: Bookings paused (manual or cutoff)
    Closed --> Open: Bookings resumed before start date
    Open --> InProgress: Guide marks expedition started
    Closed --> InProgress: Guide marks expedition started
    InProgress --> Completed: Guide marks expedition concluded
    Completed --> [*]: Permanently archived to history
```

* **Pending / Approved:** In preparation; not visible for public reservation.
* **Open:** Accepting reservations while seats remain and `start_date > CURRENT_DATE`.
* **Closed:** Pauses new reservations; existing reservations remain valid.
* **In Progress:** Expedition currently on the mountain. Booking window permanently closed.
* **Completed:** Concluded expedition. Active bookings marked `Completed`. History preserved.

---

## Booking & Concurrency Workflow

```mermaid
sequenceDiagram
    autonumber
    actor Trekker as Trekker
    participant Web as Flask Route (POST /treks/id/book)
    participant Svc as BookingService
    participant DB as SQLite DB

    Trekker->>Web: Submit booking request
    Web->>Svc: reserve_slot(user_id, trek_id)
    Svc->>DB: BEGIN IMMEDIATE; (Acquires exclusive write lock)
    Svc->>DB: Verify trek is Open, unarchived, and start_date > today
    Svc->>DB: Verify active Booked count < total_slots
    Svc->>DB: Verify user has no active Booked reservation
    alt Any check fails
        Svc->>DB: ROLLBACK;
        Svc-->>Web: Error (Fully booked / Ineligible)
        Web-->>Trekker: Render error notification
    else All checks pass
        Svc->>DB: INSERT INTO bookings (user_id, trek_id, status='Booked')
        Svc->>DB: COMMIT; (Releases lock)
        Svc-->>Web: Booking confirmed
        Web-->>Trekker: Redirect to /user/bookings with success banner
    end
```

---

## Proposed Project Structure

```
himyatra/
├── .github/                      # GitHub repository workflows and templates
│   └── pull_request_template.md  # PR verification checklist
├── docs/                         # Authoritative engineering documentation
│   ├── PRD.md                    # Authoritative Product Requirements Document
│   ├── ARCHITECTURE.md           # System architecture and request flow
│   ├── DATABASE_DESIGN.md        # Relational schema, DDL, and constraints
│   ├── USER_FLOWS.md             # End-to-end operational scenarios
│   ├── TESTING_STRATEGY.md       # Test matrix and concurrency test harness
│   ├── DECISIONS.md              # Architectural decisions and defaults
│   └── ISSUES_BACKLOG.md         # 28-issue development backlog across M0-M5
├── instance/                     # Local SQLite database (git-ignored)
├── CONTRIBUTING.md               # Branch and commit conventions
├── TODO.md                       # Project execution checklist
├── .editorconfig                 # Multi-editor formatting standards
├── .gitattributes               # Line ending normalization
├── .gitignore                    # Python and SQLite exclusion rules
└── README.md                     # Public project documentation
```

*(Application implementation files such as `app/`, `wsgi.py`, and `requirements.txt` are scheduled for Phase 1 under Milestone M0).*

---

## Local Setup & Development Instructions

### Prerequisites
* Python 3.10 or higher
* Git

### Step-by-Step Setup (For Upcoming Implementation Phase)

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/chilkotiKartik/himyatra.git
   cd himyatra
   ```

2. **Create and Activate Virtual Environment:**
   ```bash
   python -m venv .venv
   # Windows PowerShell:
   .venv\Scripts\Activate.ps1
   # Linux / macOS:
   source .venv/bin/activate
   ```

3. **Install Dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Initialize Database & Seed Administrator:**
   ```bash
   flask init-db
   flask seed-admin
   ```

5. **Start Local Development Server:**
   ```bash
   flask run --port=5000
   ```
   Open your browser and navigate to `http://127.0.0.1:5000`.

---

## Project Execution Board & Live Issues

HimYatra uses GitHub Issues and Milestones as an operational kanban board. Every feature and task is mapped to specific PRD requirements, prioritized, and linked below:

| Milestone | Target Objective | Live GitHub Issues | Status |
| :--- | :--- | :--- | :---: |
| [**M0 — Foundation**](https://github.com/chilkotiKartik/himyatra/milestone/1) | Architecture, Flask factory, SQLite schema, design system | [#1](https://github.com/chilkotiKartik/himyatra/issues/1), [#2](https://github.com/chilkotiKartik/himyatra/issues/2), [#3](https://github.com/chilkotiKartik/himyatra/issues/3), [#4](https://github.com/chilkotiKartik/himyatra/issues/4) | `Ready` |
| [**M1 — Authentication**](https://github.com/chilkotiKartik/himyatra/milestone/2) | Dual registration, login, admin seed, RBAC decorators | [#5](https://github.com/chilkotiKartik/himyatra/issues/5), [#6](https://github.com/chilkotiKartik/himyatra/issues/6), [#7](https://github.com/chilkotiKartik/himyatra/issues/7), [#8](https://github.com/chilkotiKartik/himyatra/issues/8), [#9](https://github.com/chilkotiKartik/himyatra/issues/9) | `Planned` |
| [**M2 — Administrator**](https://github.com/chilkotiKartik/himyatra/milestone/3) | Live metrics dashboard, trek CRUD, staff vetting queue, accounts | [#10](https://github.com/chilkotiKartik/himyatra/issues/10), [#11](https://github.com/chilkotiKartik/himyatra/issues/11), [#12](https://github.com/chilkotiKartik/himyatra/issues/12), [#13](https://github.com/chilkotiKartik/himyatra/issues/13), [#14](https://github.com/chilkotiKartik/himyatra/issues/14) | `Planned` |
| [**M3 — Trek Staff**](https://github.com/chilkotiKartik/himyatra/milestone/4) | Assigned expedition workspace, participant roster, capacity & progress | [#15](https://github.com/chilkotiKartik/himyatra/issues/15), [#16](https://github.com/chilkotiKartik/himyatra/issues/16), [#17](https://github.com/chilkotiKartik/himyatra/issues/17), [#18](https://github.com/chilkotiKartik/himyatra/issues/18) | `Planned` |
| [**M4 — Trekker & Bookings**](https://github.com/chilkotiKartik/himyatra/milestone/5) | Discovery catalog, live availability, booking ledger, cancellations | [#19](https://github.com/chilkotiKartik/himyatra/issues/19), [#20](https://github.com/chilkotiKartik/himyatra/issues/20), [#21](https://github.com/chilkotiKartik/himyatra/issues/21), [#22](https://github.com/chilkotiKartik/himyatra/issues/22), [#23](https://github.com/chilkotiKartik/himyatra/issues/23) | `Planned` |
| [**M5 — Reliability**](https://github.com/chilkotiKartik/himyatra/milestone/6) | Atomic write locking, test harness, demo dataset, zero-JS audit | [#24](https://github.com/chilkotiKartik/himyatra/issues/24), [#25](https://github.com/chilkotiKartik/himyatra/issues/25), [#26](https://github.com/chilkotiKartik/himyatra/issues/26), [#27](https://github.com/chilkotiKartik/himyatra/issues/27), [#28](https://github.com/chilkotiKartik/himyatra/issues/28) | `Planned` |

🔗 **Quick Links:**
* [View All 28 GitHub Issues](https://github.com/chilkotiKartik/himyatra/issues)
* [View Milestones & Progress](https://github.com/chilkotiKartik/himyatra/milestones)
* [View Backlog Specifications (Markdown)](docs/ISSUES_BACKLOG.md)

---

## Development Roadmap & Milestones

The development backlog is structured into 6 sequential milestones:

```mermaid
gantt
    title HimYatra Implementation Milestones
    dateFormat  YYYY-MM-DD
    section Milestones
    M0 - Foundation & Infrastructure     :m0, 2026-11-03, 3d
    M1 - Authentication & RBAC          :m1, after m0, 4d
    M2 - Administrator Operations       :m2, after m1, 4d
    M3 - Trek Staff Operations          :m3, after m2, 3d
    M4 - Trekker Discovery & Bookings   :m4, after m3, 4d
    M5 - Reliability, Concurrency & Release :m5, after m4, 4d
```

---

## Verification & Testing Strategy

Testing is structured to validate all 20 acceptance scenarios defined in the project specification:
* **Role Isolation:** Direct URL tampering for unauthorized roles returns HTTP 403.
* **Concurrency Verification:** Multi-threaded simulation of concurrent requests for the final available seat (`tests/test_concurrency.py`).
* **Zero-JavaScript Usability:** Verification that all routes, filters, and forms execute cleanly via standard HTTP POST/GET.

---

## Security Architecture

* **Cryptographic Password Hashing:** Werkzeug `generate_password_hash` using `scrypt` / `pbkdf2`. Plaintext passwords are never stored or logged.
* **CSRF Protection:** Server-side verification on all state-modifying POST requests.
* **SQL Injection Immunity:** Strict use of parameterized queries (`?`) across all SQLite interactions. Direct string concatenation is forbidden.
* **XSS Defense:** Automatic Jinja2 contextual HTML escaping. Untrusted user inputs are never marked `safe`.
* **Session Invalidation:** Deactivating or blacklisting an account immediately revokes access across active sessions on subsequent requests.

---

## Contributing

Please review [CONTRIBUTING.md](file:///c:/Users/chilk/Downloads/himyatra/himyatra/CONTRIBUTING.md) for branch naming conventions (`feature/`, `fix/`, `docs/`, `test/`), conventional commit guidelines, and pull request requirements.

---

## License

*License pending confirmation by repository owner.*
