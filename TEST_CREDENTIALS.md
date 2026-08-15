# EventEase — Test Accounts & Credentials Specification

**Document Version**: 1.0.0  
**Specification Basis**: SRS Section 1.9 & `04_TEST_DATA_SEED_PROMPT.md`

---

## 1. Demo User Accounts (9 Total)

| Role | Name | Email | Password | Status | Notes |
|---|---|---|---|---|---|
| **Admin** | System Administrator | `admin@eventease.com` | `AdminPass123!` | Active | **Administrative Access**: Direct console/admin SDK provisioning. Full system oversight, approval queue, user activation. |
| **Organizer (Active 1)** | Sarah Jenkins | `organizer1@eventease.com` | `EventPass123!` | Active | **Host Access**: Verified host for TechSummit Global. Organizes tech conferences & sports marathons. |
| **Organizer (Active 2)** | Marcus Vance | `organizer2@eventease.com` | `EventPass123!` | Active | **Host Access**: Verified host for Creative Workshops Inc. Organizes music festivals & design masterclasses. |
| **Organizer (Pending)** | Liam Chen | `organizer_pending@eventease.com` | `EventPass123!` | Pending Approval | **Applicant Access**: Used for demonstrating admin organizer approval workflow. Cannot publish events until approved. |
| **Attendee 1** | Alex Rivera | `attendee1@eventease.com` | `UserPass123!` | Active | **Standard Attendee**: Has active registrations for tech summit, completed attendance records, and reviews. |
| **Attendee 2** | Maya Patel | `attendee2@eventease.com` | `UserPass123!` | Active | **Standard Attendee**: Has registered events, favorite bookmarks, and notifications history. |
| **Attendee 3** | Jordan Lee | `attendee3@eventease.com` | `UserPass123!` | Active | **Standard Attendee**: Active participant with completed festival attendance. |
| **Attendee 4** | Chloe Bennett | `attendee4@eventease.com` | `UserPass123!` | Active | **Standard Attendee**: Completed feedback reviews on past events. |
| **Attendee 5** | David Kim | `attendee5@eventease.com` | `UserPass123!` | Active | **Fresh Attendee**: Clean slate for performing live registration during recording. |

---

## 2. Seeded Event Dataset (10 Events Across 6 Categories)

1. **`evt_001_flutter` (Approved • Technology)**: *Flutter & AI Mobile Dev Summit 2026* — 42/100 seats filled.
2. **`evt_002_music` (Approved • Music)**: *Acoustic Sunset Music Festival* — 88/200 seats filled.
3. **`evt_003_workshop` (Approved • Workshop)**: *Mastering Modern UI/UX Prototyping* — 29/30 seats filled (Near capacity).
4. **`evt_004_sports` (Approved • Sports)**: *City Marathon & 5K Charity Fun Run* — 14/500 seats filled.
5. **`evt_005_upcoming_soon` (Approved • Conference)**: *Web3 & Cloud Architecture Briefing* — Starting tomorrow (Tests countdown and reminder logic).
6. **`evt_006_pending_1` (Pending Approval • Education)**: *Global Robotics & Drone Olympiad* — Under admin review.
7. **`evt_007_pending_2` (Pending Approval • Community)**: *Green Urban Forestry Volunteer Drive* — Under admin review.
8. **`evt_008_rejected` (Rejected • Business)**: *Cryptocurrency High-Yield Trading Seminar* — Rejection Reason: *"Event does not comply with campus commercial solicitation guidelines."*
9. **`evt_009_cancelled` (Cancelled • Workshop)**: *Outdoor Oil Painting & Watercolor Workshop* — Cancelled due to inclement weather.
10. **`evt_010_completed` (Completed • Technology)**: *Full-Stack App Architecture Showcase* — Completed in the past with 4 registered, 4 checked-in, 3 feedback reviews, and 2 gallery photos.

---

## 3. Demonstration Checklist Cross-Check (SRS Section 1.9)

| Step | Demonstration Action | Status in Seed Dataset | Screen / Workflow |
|---|---|---|---|
| **8** | Launch application and show splash/login | Fully Supported | `/splash` $\rightarrow$ `/login` |
| **9** | Create or use an attendee account | Fully Supported | Log in as `attendee1@eventease.com` or register new |
| **10** | Browse and search events | Fully Supported | 4 active approved events in Discovery feed |
| **11** | Open event details | Fully Supported | Rich banner, seat counter, location, rules |
| **12** | Register for an event | Live Action Supported | Use `attendee5@eventease.com` to register on `evt_001_flutter` |
| **13** | Open My Events and show the QR pass | Fully Supported | View live `QRPassCard` with ticket notches & QR code |
| **14** | Login as organizer and create an event | Live Action Supported | Log in as `organizer1@eventease.com` $\rightarrow$ `/organizer/create-event` |
| **15** | Login as admin and approve the event | Fully Supported | Log in as `admin@eventease.com` $\rightarrow$ `/admin/approvals` |
| **16** | Return to organizer and demonstrate attendance | Fully Supported | Open camera QR scanner on `/organizer/scanner` |
| **17** | Submit event feedback | Fully Supported | Submit 1-5 star review on completed event `evt_010_completed` |
| **18** | Show notifications and event gallery | Fully Supported | Notifications list & fullscreen event gallery |
| **19** | Show admin statistics and user/event management | Fully Supported | KPI cards, rating averages, user toggle, event directory |
