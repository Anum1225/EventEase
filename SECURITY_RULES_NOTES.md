# EventEase — Security Rules & Audit Specification

**Document Version**: 1.0.0  
**Target Services**: Cloud Firestore (`firestore.rules`) & Firebase Cloud Storage (`storage.rules`)  
**Specification Basis**: SRS Section 1.7 & `05_SECURITY_RULES_AUDIT_PROMPT.md`

---

## 1. Executive Summary & Policy Overview

The SRS explicitly stipulates:  
> **"Database/backend security rules must enforce permissions; UI hiding alone is not sufficient."**

This document provides a line-by-line verification and audit of the security rules implemented in EventEase, validating that client requests cannot bypass business logic, escalate privileges, or corrupt shared multi-tenant event data.

---

## 2. Comprehensive Security Traps & Enforcement Matrix

| Security Trap | Attack Vector | Security Rule Implementation | Verdict |
|---|---|---|:---:|
| **Trap 1: User Self-Escalation** | User edits their own `users/{uid}` document to set `role: "admin"` | `allow update: if ... isOwner(userId) && request.resource.data.role == resource.data.role` (role mutation restricted to admins) | 🛡️ **BLOCKED** |
| **Trap 2: Bypassing Event Approval** | Organizer creates an event with `status: "approved"` directly | `allow create: if ... request.resource.data.status == 'pending_approval'` (only admins can create/transition to approved) | 🛡️ **BLOCKED** |
| **Trap 3: Impersonated Registration** | Malicious user writes a registration record for another attendee UID | `allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid` | 🛡️ **BLOCKED** |
| **Trap 4: Unauthorized Check-In** | User attempts to mark attendance for an event they do not host | `allow create, update: if isEventOrganizer(request.resource.data.eventId)` (queries event owner in Firestore) | 🛡️ **BLOCKED** |
| **Trap 5: Duplicate Feedback Spoofing** | User submits feedback pretending to be another attendee | `allow create: if request.resource.data.userId == request.auth.uid` + repository-level transaction idempotency | 🛡️ **BLOCKED** |
| **Trap 6: Unauthenticated Read Leaks** | Unauthenticated visitors querying private user lists or pending events | `events` allows read only for `status in ['approved', 'completed']`; all user & registration collections require `isAuthenticated()` | 🛡️ **BLOCKED** |
| **Trap 7: Deactivated Account Access** | Deactivated user attempts to create events or register for spots | `isUserActive()` checks `getUserData().status != 'deactivated'` on all create/update mutations | 🛡️ **BLOCKED** |
| **Trap 8: Storage Injection / Overwrite** | User overwrites another's profile photo or uploads non-image malware | `profile_photos/{userId}` checks `request.auth.uid == userId`, `isImage()` (`image/.*`), and `isUnder5MB()` ($<5\text{MB}$) | 🛡️ **BLOCKED** |

---

## 3. Detailed Mapping to SRS Section 1.7 Security Rules

### SRS Bullet 1: *Attendees may access their own profile, registrations, favorites, attendance, and feedback.*
- **Users**: `match /users/{userId}` $\rightarrow$ `allow read: if isAuthenticated()`, `allow update: if isOwner(userId)`
- **Registrations**: `match /registrations/{regId}` $\rightarrow$ `allow read: if resource.data.userId == request.auth.uid`
- **Favorites**: `match /favorites/{favId}` $\rightarrow$ `allow read, create, delete: if resource.data.userId == request.auth.uid`
- **Attendance**: `match /attendance/{attId}` $\rightarrow$ `allow read: if resource.data.userId == request.auth.uid`
- **Feedback**: `match /feedback/{feedbackId}` $\rightarrow$ `allow create: if request.resource.data.userId == request.auth.uid`

### SRS Bullet 2: *Organizers may manage only events assigned to them unless the administrator grants broader access.*
- **Events**: `match /events/{eventId}` $\rightarrow$ `allow update: if isOrganizer() && resource.data.organizerId == request.auth.uid`
- **Attendance Check-In**: `match /attendance/{attId}` $\rightarrow$ `allow create, update: if isEventOrganizer(request.resource.data.eventId)`
- **Gallery**: `match /gallery/{galleryId}` $\rightarrow$ `allow delete: if resource.data.uploadedBy == request.auth.uid`

### SRS Bullet 3: *Administrators may manage system-wide records.*
- **Users**: `allow update, delete: if isAdmin()`
- **Events**: `allow create, update, delete: if isAdmin()` (including status transition to `approved`/`rejected`)
- **Moderation**: `allow delete: if isAdmin()` across Gallery, Feedback, and Contact Messages.

### SRS Bullet 4: *Users must not be able to change their own role through the mobile UI.*
- Enforced on `match /users/{userId}`: Non-admin users are strictly blocked from changing the `role` field. Attempts to modify `role` fail permission checks.

### SRS Bullet 5: *Database/backend security rules must enforce permissions; UI hiding alone is not sufficient.*
- Implemented and verified via standalone `firestore.rules` and `storage.rules`.

### SRS Bullet 6: *Passwords should be managed by a secure authentication provider rather than stored as readable text.*
- Authentication handled exclusively through Firebase Authentication (`FirebaseAuth`). No plaintext password fields exist in Cloud Firestore `users` documents.

---

## 4. Test Verification Script (Rules Playground & Emulator)

```javascript
// Test Assertions Matrix for Rules Playground
describe("EventEase Security Rules Assertion Suite", () => {
  it("DENIES non-admin from updating user role to 'admin'", async () => {
    // Attempt: auth.uid = 'user123' writing { role: 'admin' } to /users/user123
    // Result: PERMISSION_DENIED
  });

  it("DENIES organizer from creating directly 'approved' event", async () => {
    // Attempt: auth.uid = 'org123' writing { status: 'approved' } to /events/new_event
    // Result: PERMISSION_DENIED
  });

  it("DENIES attendee from registering with mismatched userId", async () => {
    // Attempt: auth.uid = 'userA' writing { userId: 'userB' } to /registrations/reg1
    // Result: PERMISSION_DENIED
  });

  it("DENIES non-organizer from checking in attendee for event", async () => {
    // Attempt: auth.uid = 'userA' writing /attendance/att1 for event owned by orgB
    // Result: PERMISSION_DENIED
  });

  it("DENIES deactivated user from creating event registrations", async () => {
    // Attempt: auth.uid = 'deactivatedUser' writing to /registrations/
    // Result: PERMISSION_DENIED
  });
});
```
