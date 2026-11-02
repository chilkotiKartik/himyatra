# Contributing to HimYatra

Thank you for contributing to **HimYatra** (Himalayan Trekking & Expedition Management System). To maintain technical rigor, consistent business logic, and security integrity across the project, please adhere to these guidelines.

---

## 1. Principles & Technology Guardrails

HimYatra is built with a strictly defined, lightweight technology stack:
* **Backend:** Python (Flask)
* **Frontend:** Jinja2 templates, semantic HTML5, Vanilla CSS, Bootstrap 5
* **Database:** SQLite (with explicit foreign key enforcement and immediate write transactions)
* **JavaScript:** Optional progressive enhancement only. All core flows (registration, login, trek discovery, reservation, capacity management, status transitions, staff approvals) **must function completely with JavaScript disabled**.

Do **not** introduce external client-side frameworks (React, Vue, Next.js), separate DB servers (PostgreSQL, MySQL, MongoDB), caching layers (Redis), or task queues (Celery) into the core architecture.

---

## 2. Branch Naming Conventions

All development must take place on dedicated branches created from `main`:

| Prefix | Usage | Example |
| :--- | :--- | :--- |
| `feature/` | New functional features or capabilities | `feature/trekker-booking-flow` |
| `fix/` | Bug fixes and defect corrections | `fix/capacity-lock-concurrency` |
| `docs/` | Documentation, PRD updates, guides | `docs/architecture-er-diagram` |
| `test/` | Adding test suites, edge case harnesses | `test/concurrency-booking-tests` |
| `refactor/` | Code structure improvements without behavior change | `refactor/auth-decorator-cleanup` |
| `chore/` | Tooling, configurations, CI workflows | `chore/gitattributes-setup` |

---

## 3. Commit Message Conventions

HimYatra follows the **Conventional Commits** specification:

```
<type>(<scope>): <short description>

[optional body]

[optional footer(s)]
```

### Types:
* `feat`: A new feature (e.g., `feat(booking): implement atomic reservation transaction`)
* `fix`: A bug fix (e.g., `fix(auth): invalidate sessions immediately on account blacklist`)
* `docs`: Documentation only changes (e.g., `docs(prd): add business rule identifiers`)
* `test`: Adding or correcting tests (e.g., `test(capacity): add last-seat race condition test`)
* `refactor`: A code change that neither fixes a bug nor adds a feature
* `chore`: Maintenance tasks, dependencies, gitignore updates

---

## 4. Development & Issue Workflow

1. **Pick an Issue:** Check open issues in the GitHub project backlog or `docs/ISSUES_BACKLOG.md`. Ensure the issue has clear scope and acceptance criteria.
2. **Branch Out:** Branch from `main` using standard naming (`feature/<issue-name>`).
3. **Local Testing:** Test changes locally with Python's `unittest` or `pytest`. Verify browser flows with JavaScript turned off.
4. **Follow Coding Standards:**
   - Follow PEP 8 for Python code.
   - Use parameterized SQL queries or ORM expressions—never string formatting.
   - Keep views thin and encapsulate business logic cleanly.
   - Guard every state-changing route with CSRF validation and RBAC checks.
5. **Open a Pull Request:** Use `.github/pull_request_template.md`. Link the issue (`Closes #12`), describe changes, and verify all checklist items.

---

## 5. Review & Merging Standards

* Pull requests must satisfy all acceptance criteria of the linked issue.
* Automated and manual verification checklists must be passed.
* Code must be reviewed for security and role isolation before merging into `main`.
