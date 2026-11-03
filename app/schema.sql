-- HimYatra SQLite 3 Relational Schema
-- Enforces foreign keys, data constraints, and partial indexes

PRAGMA foreign_keys = ON;

-- 1. Accounts Table (Authentication & RBAC)
CREATE TABLE IF NOT EXISTS accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL CHECK(length(trim(full_name)) > 0),
    email TEXT NOT NULL UNIQUE CHECK(email LIKE '%_@_%._%'),
    password_hash TEXT NOT NULL,
    phone TEXT,
    role TEXT NOT NULL CHECK(role IN ('admin', 'staff', 'user')),
    account_status TEXT NOT NULL DEFAULT 'Active' CHECK(account_status IN ('Active', 'Blacklisted')),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_accounts_email ON accounts(email);
CREATE INDEX IF NOT EXISTS idx_accounts_role ON accounts(role);
CREATE INDEX IF NOT EXISTS idx_accounts_status ON accounts(account_status);

-- 2. Staff Profiles Table (Guide Vetting & Qualifications)
CREATE TABLE IF NOT EXISTS staff_profiles (
    staff_id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER NOT NULL UNIQUE,
    approval_status TEXT NOT NULL DEFAULT 'Pending' CHECK(approval_status IN ('Pending', 'Approved', 'Blacklisted')),
    experience_notes TEXT,
    approved_at TEXT,
    approved_by INTEGER,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES accounts(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_staff_profiles_approval ON staff_profiles(approval_status);

-- 3. Treks Table (Expedition Lifecycle & Parameters)
CREATE TABLE IF NOT EXISTS treks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL CHECK(length(trim(name)) > 0),
    description TEXT,
    location TEXT NOT NULL CHECK(length(trim(location)) > 0),
    difficulty TEXT NOT NULL CHECK(difficulty IN ('Easy', 'Moderate', 'Hard')),
    duration_days INTEGER NOT NULL CHECK(duration_days > 0),
    total_slots INTEGER NOT NULL CHECK(total_slots >= 0),
    assigned_staff_id INTEGER,
    status TEXT NOT NULL DEFAULT 'Pending' CHECK(status IN ('Pending', 'Approved', 'Open', 'Closed', 'In Progress', 'Completed')),
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL,
    is_archived INTEGER NOT NULL DEFAULT 0 CHECK(is_archived IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    CHECK(end_date >= start_date),
    FOREIGN KEY (assigned_staff_id) REFERENCES accounts(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_treks_status ON treks(status);
CREATE INDEX IF NOT EXISTS idx_treks_dates ON treks(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_treks_difficulty ON treks(difficulty);
CREATE INDEX IF NOT EXISTS idx_treks_location ON treks(location);
CREATE INDEX IF NOT EXISTS idx_treks_assigned_staff ON treks(assigned_staff_id);
CREATE INDEX IF NOT EXISTS idx_treks_archived ON treks(is_archived);

-- 4. Bookings Table (Reservations & Ledger)
CREATE TABLE IF NOT EXISTS bookings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    trek_id INTEGER NOT NULL,
    booking_date TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    status TEXT NOT NULL DEFAULT 'Booked' CHECK(status IN ('Booked', 'Cancelled', 'Completed')),
    cancelled_at TEXT,
    completed_at TEXT,
    FOREIGN KEY (user_id) REFERENCES accounts(id) ON DELETE RESTRICT,
    FOREIGN KEY (trek_id) REFERENCES treks(id) ON DELETE RESTRICT
);

-- Partial Unique Index: Only one active 'Booked' reservation per user per trek.
CREATE UNIQUE INDEX IF NOT EXISTS uq_active_booking_user_trek 
ON bookings (user_id, trek_id) 
WHERE status = 'Booked';

CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_trek_id ON bookings(trek_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);

-- 5. Audit Logs Table (Operational Auditing)
CREATE TABLE IF NOT EXISTS audit_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    actor_id INTEGER NOT NULL,
    action TEXT NOT NULL,
    target_entity TEXT NOT NULL,
    target_id INTEGER NOT NULL,
    details TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
    FOREIGN KEY (actor_id) REFERENCES accounts(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(target_entity, target_id);
