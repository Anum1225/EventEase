# EventEase — My Own Testing Checklist (Before I Submit)

This one's for me, not for an AI agent. I'm going through the actual running app
myself — emulator or a real device, tapping every screen — and checking things off as
I genuinely confirm them. Nothing gets checked because it "should" work or because an
agent said it does. If I haven't tapped it myself and watched it happen, it stays
unchecked.

**How I'm using this alongside the other files:**
- If I ran `07_ANTIGRAVITY_SUBAGENT_VERIFICATION_CHECKLIST.md` first, I open
  `VERIFICATION_REPORT.md` before starting this pass and specifically re-test
  everything it listed under "Critical findings" and "Functional gaps" myself, right
  at the top — those are the known trouble spots, not a surprise.
- If I haven't run that yet, this file works fine standalone — it's a full pass either
  way, just without a head start on where the bugs probably are.
- I'm not just re-doing what an agent already checked for the sake of it. I'm doing
  this because a human tapping through the actual app catches a different category of
  problem than an agent does — does this feel confusing, does this look bad on a real
  phone screen in real light, does this take too many taps, is there a typo an agent
  wouldn't notice as a typo.

**Setup before I start:**
- [ ] App is installed and running on an actual device or emulator, not just "the code compiles"
- [ ] I have my seeded test credentials in front of me (from `TEST_CREDENTIALS.md` if that was generated, or wherever I wrote them down)
- [ ] I'm testing with both light mode and dark mode available — I'll do a first pass in one, then re-check the highlights in the other
- [ ] I have a stable internet connection, and I'll deliberately kill it at least once partway through (see Section 9)

---

## 1. First launch and account creation

- [ ] Splash screen shows and doesn't hang
- [ ] I registered a brand new attendee account start to finish, using a real-looking name/email/phone, and it actually landed me on the attendee home screen
- [ ] I tried registering with an email I already used — it told me clearly, didn't just silently fail or crash
- [ ] I logged out completely, then logged back in with that same account — it worked
- [ ] I tried logging in with the wrong password on purpose — the error message actually told me it was a password problem, not some generic "something went wrong"
- [ ] I tried logging in with an email that's never been registered — different error message than the wrong-password one
- [ ] I tapped "forgot password" and it didn't crash or hang — got some kind of confirmation that a reset was sent
- [ ] I registered a SECOND new account and chose "organizer" during signup — it did NOT drop me straight into an organizer dashboard, it showed me a pending/waiting state instead

---

## 2. Looking and feeling like a real app, not a prototype

I'm doing this pass slowly, actually looking at things, not just clicking through.

- [ ] Nothing anywhere looks like default unstyled Flutter — no default purple, no obviously-untouched Material widgets sitting next to designed ones
- [ ] Light mode: background doesn't look stark/harsh white, text is readable, nothing feels washed out
- [ ] Dark mode: I switched to it and walked through at least 8–10 different screens — nothing has a white flash, nothing has invisible dark-text-on-dark-background, nothing looks like light mode with the colors just inverted
- [ ] The QR Pass screen (see Section 4) is genuinely the best-looking screen in the app — if some other screen looks flashier than it, that's backwards and I'm noting it
- [ ] Every category tag (Technology, Education, Sports, Music, Business, Workshop, Conference, Community) has both a color AND an icon — not just a colored dot
- [ ] Every status badge (Pending/Approved/Rejected/Cancelled/Completed) is distinguishable from the others even if I squint — Rejected and Cancelled specifically don't look identical to me
- [ ] I resized text / checked with my phone's largest accessibility text setting on at least the home screen and one form — nothing overlaps or gets cut off badly
- [ ] Buttons and tappable things feel like a normal-sized tap target, not tiny

---

## 3. Browsing, searching, and event details — as attendee

- [ ] Home/Discover shows event cards with a picture, a real title, date, time, location, category tag, and how many seats are left — I can see all of that without tapping in
- [ ] I searched for something that exists — got a narrowed, correct result
- [ ] I searched for total gibberish that shouldn't match anything — got a proper "no results" screen, not a blank white area or a crash
- [ ] I applied a category filter — list actually changed
- [ ] I applied a date filter — list actually changed
- [ ] I stacked two filters at once — both applied together, not just the last one
- [ ] I tapped "clear filters" — got the full list back
- [ ] I opened a full event detail page and everything from the card is there PLUS description, rules, organizer name, and an actual seat count
- [ ] I opened an event I already registered for — it visibly shows I'm registered, doesn't offer to register me again

---

## 4. Registering for an event and the QR pass — this is the one I'm most careful about

- [ ] I registered for a real event start to finish and got a clear confirmation screen/message
- [ ] I immediately went back into that same event — the Register button now shows something different (disabled, "You're registered," whatever) — it does NOT still invite me to register again
- [ ] I opened My Events → found this registration → opened the QR pass
- [ ] The QR pass looks like an actual pass — not a bare QR code floating on a blank screen. Banner image, event name, some kind of ticket-stub visual treatment
- [ ] The QR code itself sits on a plain white patch, even though I'm in dark mode — I checked this specifically, since a QR code on a dark background can be genuinely unscannable
- [ ] I actually scanned this QR code with a second device's camera (or the app's own scanner logged in as organizer, see Section 5) and it read successfully — I didn't just assume it would because it looks like a QR code
- [ ] I tried to register for the exact same event a second time (different button, if there's more than one way in — like from Favorites vs. from Discover) and it was actually blocked both times, not just the first
- [ ] If there was a fully-booked event in the test data, I tried registering for it and got told it's full, rather than it letting me in anyway

---

## 5. My Events, Favorites, Notifications, Profile — as attendee

- [ ] My Events correctly splits into upcoming / completed / cancelled — I checked that an event I know is cancelled actually shows in the cancelled section, not still sitting in upcoming
- [ ] I added an event to Favorites, backed out, went to the Favorites screen — it's there
- [ ] I removed it from Favorites — it's actually gone, not just visually greyed out
- [ ] I have at least one notification and it's visually different unread vs. read — I tapped it and it switched to "read" and stayed that way after I left and came back
- [ ] I edited my profile (name, photo) and FULLY CLOSED AND REOPENED the app — the change was still there, wasn't just sitting in memory
- [ ] I changed my password through the app and successfully logged in with the new one afterward

---

## 6. Organizer side — creating and managing an event

- [ ] Logged in as one of the seeded organizer accounts
- [ ] Created a brand new event filling out every field — it did NOT show up as immediately live/approved, it went into a pending state
- [ ] I tried submitting the create-event form with something required left blank — it stopped me and told me specifically what was missing, not a vague error
- [ ] I edited one of my existing events and the change actually saved
- [ ] I looked at my list of registrations/participants for one event — real people, real statuses, not placeholder rows
- [ ] I sent an announcement for one event — then logged into an attendee account that's registered for it and confirmed the notification actually arrived there
- [ ] I requested cancellation on an event — its status changed, and when I checked as an attendee, it correctly shows as cancelled and won't let me register into it
- [ ] I uploaded a gallery photo with a caption for a completed event, and it shows up correctly when I view that event's gallery
- [ ] I looked at feedback left on one of my events — I can see it, I cannot edit or delete someone else's review from here

---

## 7. The QR scanner — organizer side, this is the flow I'm least willing to skip

- [ ] Camera permission prompt appeared and worked normally the first time
- [ ] I scanned the REAL QR pass from Section 4 (the one I actually registered for earlier as an attendee) — not a fake/typed-in code — and it correctly checked that person in
- [ ] I scanned that exact same QR code a second time on purpose — it told me clearly it was already checked in, with a time, and did NOT create a second attendance record or let me check them in twice
- [ ] I tried scanning something that isn't a valid EventEase QR at all (a random QR from anywhere) — it failed gracefully with a real error, didn't crash the app

---

## 8. Admin side

- [ ] Logged in as the seeded admin account
- [ ] I can see pending events waiting for approval
- [ ] I approved one — then checked from an attendee account that it's now actually visible/discoverable, not just marked "approved" on the admin screen
- [ ] I rejected a different pending event and gave a reason — logged in as that organizer and confirmed they can actually see why it was rejected
- [ ] I found a test user account and deactivated it — then tried logging in AS that user in a different session and confirmed I genuinely couldn't get in, not just that they vanished from a list
- [ ] I approved a pending organizer application — logged into that account and confirmed they now land on the organizer dashboard, not still stuck pending
- [ ] I opened Reports/Statistics — picked one number on screen (like total registrations) and manually counted it myself against what I know is in the test data, and it actually matched
- [ ] I scrolled through every admin screen specifically looking for anything that looks like a password or auth token being shown anywhere, even partially masked — found nothing
- [ ] I removed a gallery photo as admin, then checked as an attendee that it's genuinely gone from that event's gallery, not just hidden on the admin side

---

## 9. Breaking it on purpose

- [ ] I turned on airplane mode mid-app and tried to do something that needs the network (like registering) — got a real "you're offline" type message, the app didn't freeze or crash
- [ ] I turned the network back on and confirmed the app recovered normally without needing a full restart
- [ ] I found a screen with genuinely nothing to show (searched a category with zero events, or similar) — got a proper "nothing here" message, not a blank white screen that looks broken
- [ ] I tried a destructive action (cancelling an event, deactivating a user, rejecting something) and got asked to confirm before it actually happened — I didn't just tap once and have it immediately gone

---

## 10. The actual demo run-through

Right before I record anything or submit anything, I'm doing one uninterrupted walkthrough of the SRS's own 12-step demonstration checklist, back to back, with no skipping around:

- [ ] 1. Launch app, see splash/login
- [ ] 2. Use an attendee account
- [ ] 3. Browse and search events
- [ ] 4. Open event details
- [ ] 5. Register for an event
- [ ] 6. Open My Events, show the QR pass
- [ ] 7. Log in as organizer, create an event
- [ ] 8. Log in as admin, approve that event
- [ ] 9. Back to organizer, show participant/attendance management
- [ ] 10. Submit event feedback
- [ ] 11. Show notifications and event gallery
- [ ] 12. Show admin statistics and user/event management

If any single one of these 12 stumbles, stalls, or needs me to explain "it would work if..." — that's not ready yet. I'm fixing it and running this section again before I consider this checklist actually complete.

---

## Before I actually submit

- [ ] Everything above is checked, with nothing skipped or assumed
- [ ] If I ran the Antigravity subagent pass, I went back and specifically confirmed every item it flagged under "Critical findings" is now genuinely fixed — not just that I read the report
- [ ] I have my demo credentials (attendee/organizer/admin) written down somewhere I'll actually have on hand
- [ ] I did this entire pass at least once in dark mode and once in light mode, not just one or the other
