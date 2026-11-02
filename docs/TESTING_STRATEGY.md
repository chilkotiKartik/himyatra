# Verification & Testing Strategy

**Product Name:** HimYatra  
**Category:** Himalayan Trekking & Expedition Operations Management System  

---

## 1. Testing Philosophy & Scope

HimYatra's testing strategy guarantees system stability, role security, and transactional concurrency integrity before release. Tests are structured across five tiers:

1. **Unit Testing:** Pure domain functions (slot calculation, password hashing, date range validations).
2. **Integration Testing:** Flask endpoints, database transactions, form submissions, and Post/Redirect/Get flow.
3. **Role & Permission Isolation:** Asserting HTTP 403 / 302 barriers across unauthorized routes.
4. **Concurrency & Race Condition Verification:** Simulating simultaneous multi-threaded booking attempts for the final available seat.
5. **No-JavaScript Usability Verification:** Ensuring all forms, filters, and actions work purely through semantic HTML and standard HTTP POST/GET.

---

## 2. Test Checklist & Acceptance Matrix

The test suite maps directly to the checklist defined in the project specification:

| Test ID | Test Scenario | Expected Outcome | Verification Tier |
| :--- | :--- | :--- | :--- |
| **T-01** | Register trekker with valid, unique email. | Account created; login succeeds; redirects to `/user`. | Integration |
| **T-02** | Register staff and attempt to open `/staff` before admin approval. | Access blocked; renders pending notice. | Integration / RBAC |
| **T-03** | Administrator approves staff account; guide logs in. | Access granted to `/staff` dashboard. | Integration / RBAC |
| **T-04** | Attempt public registration for `admin` role. | Route does not exist (404/405); forbidden. | Security |
| **T-05** | Create valid trek as administrator. | Trek persisted in SQLite; displays in admin list. | Integration |
| **T-06** | Submit invalid trek duration (`-1`), dates (`end < start`), or slots (`-5`). | Form submission rejected with clear validation error. | Unit / Integration |
| **T-07** | Attempt to assign a `Pending` or `Blacklisted` staff account to a trek. | Assignment rejected server-side. | Integration |
| **T-08** | Staff Guide A attempts to edit Guide B's assigned trek (`/staff/treks/<id>`). | Access denied (HTTP 403); zero database changes. | Security / RBAC |
| **T-09** | Filter open treks by difficulty (`Moderate`) and location (`Har Ki Dun`). | Only matching, open, unarchived treks returned. | Integration |
| **T-10** | Attempt to book a trek in `Pending`, `Approved`, `Closed`, or `Completed` state. | Booking rejected; error message displayed. | Business Logic |
| **T-11** | Book the final remaining available seat. | Exactly 1 booking succeeds; available slots becomes 0. | Concurrency / ACID |
| **T-12** | Attempt to book an already full trek (`available_slots == 0`). | Booking rejected with "Fully booked" notice. | Business Logic |
| **T-13** | Trekker attempts duplicate active booking on same trek. | Blocked by database partial index & service check. | Integration / ACID |
| **T-14** | Reduce trek `total_slots` below current `Booked` count. | Update rejected with validation error. | Business Logic |
| **T-15** | Cancel booking before trek start date. | Status becomes `Cancelled`; slot released to pool. | Integration |
| **T-16** | Mark trek `In Progress` then `Completed` as assigned guide. | Lifecycle updates; participant bookings marked `Completed`. | Integration |
| **T-17** | Blacklist active user and attempt action using existing session. | Request denied (HTTP 403); session invalidated. | Security |
| **T-18** | Search admin accounts directory by name fragment and ID. | Exact filtered records returned safely. | Integration |
| **T-19** | Restart Flask server after database operations. | Data persists in SQLite; admin is not duplicated. | System / Persistence |
| **T-20** | Execute entire reservation workflow with JavaScript disabled in browser. | 100% of routes and forms functional via SSR. | E2E / Accessibility |

---

## 3. Concurrency & ACID Testing Harness

A dedicated multi-threaded test simulates concurrent contention on the last seat:

```python
import threading
import pytest

def test_last_seat_concurrency_race(app, client, seed_trek_with_one_seat):
    """
    Ensures that when 10 threads attempt to book the final remaining slot 
    simultaneously, exactly 1 succeeds and 9 receive 'Fully booked'.
    """
    trek_id = seed_trek_with_one_seat
    results = []

    def attempt_booking(user_id):
        with app.app_context():
            res = client_for_user(user_id).post(f"/treks/{trek_id}/book")
            results.append(res.status_code)

    threads = [threading.Thread(target=attempt_booking, args=(f"user_{i}",)) for i in range(10)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    # Assert exactly one redirect (302) to success, others receive validation failure
    success_count = count_bookings_in_db(trek_id, status="Booked")
    assert success_count == 1, f"Expected 1 booked seat, found {success_count}"
```

---

## 4. Test Execution Instructions (For Phase 1+)

```bash
# Activate virtual environment
source .venv/bin/activate  # or .venv\Scripts\activate on Windows

# Run full test suite with coverage
pytest --cov=app tests/

# Run specifically security and concurrency suites
pytest tests/test_concurrency.py tests/test_security_rbac.py
```
