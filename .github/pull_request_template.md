## Summary
A concise description of the purpose of this Pull Request and the changes introduced.

## Related Issue
Closes #(issue number)

## Changes Introduced
- Detail 1
- Detail 2
- Detail 3

## Architectural & Business Rule Verification
- [ ] Technology stack strictly adhered to (Python, Flask, Jinja2, Bootstrap, SQLite)
- [ ] Core operations remain 100% functional with JavaScript disabled
- [ ] No foreign keys bypassed; SQLite foreign key constraints enforced
- [ ] Booking and capacity changes execute within atomic database transactions (`BEGIN IMMEDIATE`)
- [ ] Role-based access control enforced server-side on all endpoints

## Testing Checklist
- [ ] Unit tests added / updated
- [ ] Integration tests covering role permission boundaries verified
- [ ] Manual test verification performed against acceptance checklist

## Security Checklist
- [ ] Password hashes generated via secure algorithms (Werkzeug/bcrypt), never logged
- [ ] All POST endpoints protected against CSRF
- [ ] All SQL queries parameterized (no raw string interpolation)
- [ ] Output safely escaped by Jinja2 autoescaping
- [ ] Blacklisted or unapproved accounts blocked at request entry

## Review Checklist
- [ ] Code follows project conventions (PEP 8, clean template hierarchy)
- [ ] Documentation updated (PRD, Architecture, or API tables if applicable)
- [ ] No temporary files, credentials, or SQLite binary databases committed
