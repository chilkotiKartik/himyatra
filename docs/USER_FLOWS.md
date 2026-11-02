# End-to-End User Flows & Operational Scenarios

**Product Name:** HimYatra  
**Category:** Himalayan Trekking & Expedition Operations Management System  

---

## 1. Flow A: Staff Registration, Administrative Vetting & Approval

```mermaid
sequenceDiagram
    autonumber
    actor Guide as Trek Staff / Guide
    actor Admin as System Administrator
    participant Web as HimYatra Web Server
    participant DB as SQLite DB

    Guide->>Web: POST /register/staff (name, email, phone, experience, password)
    Web->>DB: INSERT INTO accounts (role='staff', account_status='Active')
    Web->>DB: INSERT INTO staff_profiles (approval_status='Pending')
    Web-->>Guide: Flash "Registration received. Approval pending."

    Guide->>Web: POST /login (credentials)
    Web->>DB: Check approval_status
    DB-->>Web: 'Pending'
    Web-->>Guide: Render pending_notice.html ("Awaiting administrator vetting")
    Note over Guide,Web: Guide cannot access /staff/*

    Admin->>Web: GET /admin/staff
    Web->>DB: SELECT * FROM staff_profiles WHERE approval_status = 'Pending'
    DB-->>Web: pending applications list
    Web-->>Admin: Render staff approval queue

    Admin->>Web: POST /admin/staff/42/approve
    Web->>DB: UPDATE staff_profiles SET approval_status='Approved', approved_at=NOW(), approved_by=admin_id WHERE staff_id=42
    Web-->>Admin: Flash "Staff approved successfully."

    Guide->>Web: GET /staff
    Web->>DB: Check approval_status
    DB-->>Web: 'Approved'
    Web-->>Guide: Render staff dashboard (shows "No treks assigned yet" if unassigned)
```

---

## 2. Flow B: Trek Creation, Guide Assignment & Public Launch

```mermaid
sequenceDiagram
    autonumber
    actor Admin as System Administrator
    actor Guide as Approved Staff
    actor Trekker as Public Trekker
    participant Web as HimYatra Web Server
    participant DB as SQLite DB

    Admin->>Web: GET /admin/treks/new
    Web->>DB: SELECT * FROM accounts a JOIN staff_profiles s ON a.id = s.account_id WHERE s.approval_status = 'Approved'
    DB-->>Web: List of eligible guides
    Web-->>Admin: Render Trek Creation Form with guide dropdown

    Admin->>Web: POST /admin/treks/new (Name: "Kedarkantha Winter Expedition", location="Sankri", slots=15, dates, guide_id=42, status="Approved")
    Web->>DB: INSERT INTO treks (...) VALUES (...)
    Web-->>Admin: Flash "Trek created with Approved status."

    Note over Guide,Web: Guide sees expedition in their /staff dashboard
    Guide->>Web: POST /staff/treks/10/open
    Web->>DB: UPDATE treks SET status = 'Open' WHERE id = 10 AND assigned_staff_id = 42
    Web-->>Guide: Flash "Expedition is now Open for public reservations."

    Trekker->>Web: GET /treks?difficulty=Moderate&location=Sankri
    Web->>DB: SELECT * FROM treks WHERE status = 'Open' AND is_archived = 0
    DB-->>Web: Kedarkantha Winter Expedition (15 slots available)
    Web-->>Trekker: Render trek discovery card
```

---

## 3. Flow C: Trekker Reservation & Concurrency Contention

```mermaid
sequenceDiagram
    autonumber
    actor Trekker1 as Trekker 1
    actor Trekker2 as Trekker 2
    participant Web as HimYatra App
    participant DB as SQLite DB (Exclusive Lock)

    Note over DB: Trek 10 has total_slots = 15, Booked count = 14 (1 slot remaining)
    
    Trekker1->>Web: POST /treks/10/book
    Trekker2->>Web: POST /treks/10/book (Fraction of a second later)
    
    Web->>DB: BEGIN IMMEDIATE; (Acquired by Trekker 1)
    Web->>DB: Check duplicate booking (None)
    Web->>DB: Check capacity: 15 - 14 = 1 seat available
    Web->>DB: INSERT INTO bookings (user_id=8, trek_id=10, status='Booked')
    Web->>DB: COMMIT;
    Web-->>Trekker1: Flash "Booking Confirmed! Reservation #105"

    Note over Web,DB: Trekker 2 transaction executes immediately after lock release
    Web->>DB: BEGIN IMMEDIATE; (Acquired by Trekker 2)
    Web->>DB: Check duplicate booking (None)
    Web->>DB: Check capacity: 15 - 15 = 0 seats available
    Web->>DB: ROLLBACK;
    Web-->>Trekker2: Flash "Trek is fully booked. No remaining seats."
```

---

## 4. Flow D: Self-Service Cancellation & Slot Reallocation

```mermaid
sequenceDiagram
    autonumber
    actor Trekker as Authenticated Trekker
    participant Web as HimYatra Web Server
    participant DB as SQLite DB

    Trekker->>Web: GET /user/bookings
    Web->>DB: SELECT * FROM bookings WHERE user_id = ?
    DB-->>Web: Booking #105 (Kedarkantha, start_date = 2026-12-15, status='Booked')
    Web-->>Trekker: Render booking row with active "Cancel Booking" button

    Trekker->>Web: POST /user/bookings/105/cancel
    Web->>DB: Check start_date > CURRENT_DATE (Eligible)
    Web->>DB: UPDATE bookings SET status = 'Cancelled', cancelled_at = NOW() WHERE id = 105
    Web-->>Trekker: Flash "Booking #105 has been cancelled."

    Note over Web,DB: Slot math dynamically restores available seat
    Trekker->>Web: GET /treks/10
    Web->>DB: Recalculate: total_slots (15) - Booked (14) = 1 available
    Web-->>Trekker: Renders "1 seat available"
```

---

## 5. Flow E: Expedition Dispatch (In Progress) & Completion Workflow

```mermaid
sequenceDiagram
    autonumber
    actor Guide as Assigned Guide
    participant Web as HimYatra Web Server
    participant DB as SQLite DB

    Note over Guide: Expedition departure date arrives
    Guide->>Web: POST /staff/treks/10/start
    Web->>DB: UPDATE treks SET status = 'In Progress' WHERE id = 10 AND assigned_staff_id = user_id
    Web-->>Guide: Flash "Trek is marked In Progress. Booking window is now closed."

    Note over Guide: Multi-day trek concludes successfully
    Guide->>Web: POST /staff/treks/10/complete
    Web->>DB: BEGIN TRANSACTION;
    Web->>DB: UPDATE treks SET status = 'Completed', updated_at = NOW() WHERE id = 10
    Web->>DB: UPDATE bookings SET status = 'Completed', completed_at = NOW() WHERE trek_id = 10 AND status = 'Booked'
    Web->>DB: COMMIT;
    Web-->>Guide: Flash "Expedition completed. Participant records archived to history."
```

---

## 6. Flow F: Account Blacklisting & Session Termination

```mermaid
sequenceDiagram
    autonumber
    actor Admin as System Administrator
    actor RogueUser as Blacklisted User / Guide
    participant Web as HimYatra Web Server
    participant DB as SQLite DB

    Admin->>Web: POST /admin/accounts/23/blacklist
    Web->>DB: UPDATE accounts SET account_status = 'Blacklisted' WHERE id = 23
    Web-->>Admin: Flash "Account #23 blacklisted."

    Note over RogueUser: Rogue user attempts to submit a request using prior active session
    RogueUser->>Web: POST /treks/12/book (Session cookie present)
    Web->>DB: SELECT account_status FROM accounts WHERE id = 23
    DB-->>Web: 'Blacklisted'
    Web->>Web: Clear session cookie
    Web-->>RogueUser: HTTP 403 Forbidden ("Your account has been deactivated. Contact administration.")
```
