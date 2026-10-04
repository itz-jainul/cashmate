# CashMate — Existing Project Redesign Prompt

## IMPORTANT

This is an **existing Flutter + Firebase application**.

**Do not create a new project from scratch.**

First inspect the existing codebase thoroughly:

- Flutter architecture
- Firebase Authentication
- Firestore collections
- Models
- Providers
- Services
- Screens
- Navigation
- Matching logic
- Connection/exchange logic
- Firestore Security Rules
- Tests

Then refactor the existing application around the new CashMate concept below. Preserve working functionality wherever possible.

---

# 1. Product Concept

Rename/rebrand the application as:

# CashMate

**Tagline:** Find your cash exchange match.

CashMate is a simple peer-to-peer cash ↔ digital-money matching application.

Users post what they have, what they need, and the amount. All authenticated users can see active requests. When two users have exactly opposite requirements for the same amount, CashMate automatically detects the match and creates a connection.

The actual money exchange happens outside the application.

---

# 2. Core Example

### User A

```text
Has: Digital Money
Wants: Cash
Amount: ₹100
```

### User B

```text
Has: Cash
Wants: Digital Money
Amount: ₹100
```

Matching rule:

```text
A.has == B.wants
A.wants == B.has
A.amount == B.amount
A.userId != B.userId
```

Result:

```text
MATCH FOUND

User A ↔ User B
₹100
Digital ↔ Cash
```

Then create a connection.

---

# 3. Keep the System Simple

Do **not** implement:

- Partial matching
- ₹100 ↔ ₹80 matching
- Splitting requests
- Multiple contributors
- Offer marketplace
- Bidding
- Wallet
- Payment gateway
- UPI integration
- Bank integration
- Automatic money transfer
- Cryptocurrency
- AI matching
- Complex scoring/recommendation algorithms

The matching algorithm is:

> **Exact opposite requirement + exact same amount**

---

# 4. Main Features

## A. Public Requests

All authenticated users can see active exchange requests.

Example:

```text
Arun

Has: Digital
Wants: Cash
Amount: ₹100

Searching...
```

## B. Automatic Matching

When another user creates:

```text
Rahul

Has: Cash
Wants: Digital
Amount: ₹100
```

the system automatically detects the exact match.

Show:

```text
🎉 Match Found

Arun ↔ Rahul

₹100

Digital ↔ Cash
```

Then create a connection.

---

# 5. Matching Rules

A match occurs only when ALL are true:

```text
A.has == B.wants
AND
A.wants == B.has
AND
A.amount == B.amount
AND
A.userId != B.userId
AND
A.status == "searching"
AND
B.status == "searching"
```

### Match

```text
A: Cash → Digital ₹100
B: Digital → Cash ₹100
=> MATCH
```

### No match: different amount

```text
A: Cash → Digital ₹100
B: Digital → Cash ₹80
=> NO MATCH
```

### No match: same direction

```text
A: Cash → Digital ₹100
B: Cash → Digital ₹100
=> NO MATCH
```

### No match: same user

Never match a user with their own request.

---

# 6. Public Requests Screen

Create a dedicated Requests screen.

Example:

```text
Requests

[ Search ]

All     Cash     Digital

────────────────────────

Arun
₹100

Has:
💵 Cash

Wants:
📱 Digital

🟢 Searching

────────────────────────

Rahul
₹500

Has:
📱 Digital

Wants:
💵 Cash

🟢 Searching
```

Authenticated users can view active requests.

Do not expose:

- Passwords
- Banking information
- UPI credentials
- OTPs
- Private profile information
- Unnecessary contact information

Public cards should show only:

- Display name
- Amount
- Has
- Wants
- Creation time
- Status

---

# 7. Create Request

Screen:

```text
Create Exchange Request

What do you have?

[ 💵 Cash ]
[ 📱 Digital Money ]

What do you want?

[ 💵 Cash ]
[ 📱 Digital Money ]

Amount

₹ [ 100 ]

[ Post Request ]
```

Prevent:

```text
Cash → Cash
Digital → Digital
```

Allow only one active `searching` request per user.

If a user already has an active request, show:

```text
You already have an active request.

Please cancel your current request before creating another.
```

---

# 8. Request Status

Use only:

```text
searching
matched
cancelled
completed
expired
```

Lifecycle:

```text
searching
    ↓
matched
    ↓
completed
```

or:

```text
searching → cancelled
```

or:

```text
searching → expired
```

---

# 9. Automatic Matching

When a new request is created:

1. Save it to Firestore.
2. Search for the opposite `has/wants`.
3. Require exact amount equality.
4. Exclude the current user.
5. Only consider `searching` requests.
6. Ignore expired requests.
7. If a match exists, atomically update both requests.
8. Create a connection.
9. Notify both users.
10. Show the Match Found UI.

For example:

```text
User A creates:
Cash → Digital ₹100

        ↓

Search Firestore

        ↓

Find:
Digital → Cash ₹100

        ↓

MATCH FOUND

        ↓

Create Connection
```

---

# 10. Prevent Double Matching

Use a Firestore transaction.

Before finalizing a match, re-read both requests.

Verify:

```text
status == searching
```

for both.

Then atomically update:

```text
A.status = matched
B.status = matched
```

and:

```text
A.matchedUserId = B.userId
A.matchedRequestId = B.requestId

B.matchedUserId = A.userId
B.matchedRequestId = A.requestId
```

If another transaction already matched one request, fail gracefully:

```text
Request already matched.
```

---

# 11. Connection Model

Create:

```text
connections/{connectionId}
```

Example:

```json
{
  "userAId": "uidA",
  "userBId": "uidB",
  "requestAId": "requestA",
  "requestBId": "requestB",
  "amount": 100,
  "status": "pending",
  "userAAccepted": false,
  "userBAccepted": false,
  "userAConfirmed": false,
  "userBConfirmed": false,
  "createdAt": "timestamp",
  "completedAt": null
}
```

---

# 12. Connection Lifecycle

Use:

```text
pending
connected
completed
cancelled
```

Flow:

```text
Match Found
    ↓
Connection Pending
    ↓
Both users accept
    ↓
Connected
    ↓
Users exchange money outside app
    ↓
Both confirm
    ↓
Completed
```

---

# 13. Connection Screen

Example:

```text
Match Found 🎉

You are connected with

Rahul

₹100

You give:
💵 Cash

You receive:
📱 Digital

────────────────

Safety Reminder

Meet in a safe public place.
Never share OTPs or passwords.

────────────────

[ Accept Connection ]
[ Cancel ]
```

Both users must accept.

When both accept:

```text
status = connected
```

If only one accepts:

```text
Waiting for the other user...
```

---

# 14. Exchange Completion

After the real-world exchange, both users confirm.

Example:

```text
Exchange Complete?

₹100

I have received the money.

[ Confirm ]
```

Store:

```text
userAConfirmed
userBConfirmed
```

Only when both are true:

```text
status = completed
```

Then update both requests to completed and create/update history.

---

# 15. Financial Safety

The app must **not process, hold, or transfer money**.

Never ask for:

- UPI PIN
- Bank password
- ATM PIN
- OTP
- Card number
- Banking credentials

Display:

```text
CashMate does not transfer or hold money.
The actual exchange happens directly between users.
```

---

# 16. Home Screen

Redesign the Home screen around the simple matching concept.

```text
Good morning, Arun 👋

Find someone to exchange money with.

[ + Create Request ]

────────────────────────

Your Request

₹100

Cash → Digital

🟢 Searching

[ View Request ]

────────────────────────

Recent Matches

Rahul
₹100
Digital ↔ Cash

Connected ✓
```

Keep it minimal.

---

# 17. Requests Screen

Example:

```text
Requests

[ Search requests ]

[ All ] [ Cash ] [ Digital ]

──────────────────────

🎯 Exact Match

Rahul

Has Digital
Wants Cash

₹100

[ Connect ]

──────────────────────

Arun

Has Cash
Wants Digital

₹500

Searching
```

If the current user has:

```text
Has: Digital
Wants: Cash
Amount: ₹100
```

show the exact compatible request prominently.

Do not use a complex scoring algorithm.

---

# 18. Manual Connect

Even though automatic matching exists, allow a user to manually connect from the public request list.

When `Connect` is pressed, backend validation must check:

1. Request exists.
2. Request is still `searching`.
3. Request belongs to another user.
4. Direction is compatible.
5. Amount is exactly equal.

If valid:

```text
Connection request sent.
```

The backend, not only the UI, must enforce these rules.

---

# 19. My Connections

Create a Connections screen.

Example:

```text
My Connections

──────────────────────

Rahul

₹100

Cash ↔ Digital

🟢 Connected

[ View ]

──────────────────────

Karthik

₹500

Digital ↔ Cash

✓ Completed

[ View ]
```

Optional tabs:

```text
Active
Completed
Cancelled
```

Keep it simple.

---

# 20. History

Example:

```text
Exchange History

₹100
Cash ↔ Digital
Rahul
Completed

₹500
Digital ↔ Cash
Karthik
Completed
```

---

# 21. Profile

Preserve the existing profile implementation where possible.

Show:

```text
Profile

Arun Kumar
arun@gmail.com

Completed Exchanges: 8
Rating: 4.8 ★

Edit Profile
Notifications
Privacy
Help
Logout
```

Do not unnecessarily rewrite authentication/profile logic.

---

# 22. Firebase Collections

## users

```text
users/{userId}
```

```json
{
  "name": "Arun Kumar",
  "email": "arun@gmail.com",
  "phone": null,
  "photoUrl": null,
  "completedExchanges": 0,
  "rating": 5.0,
  "isActive": true,
  "createdAt": "timestamp"
}
```

## exchangeRequests

```text
exchangeRequests/{requestId}
```

```json
{
  "userId": "uidA",
  "userName": "Arun",
  "has": "cash",
  "wants": "digital",
  "amount": 100,
  "status": "searching",
  "matchedUserId": null,
  "matchedRequestId": null,
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "expiresAt": "timestamp"
}
```

## connections

```text
connections/{connectionId}
```

```json
{
  "userAId": "uidA",
  "userBId": "uidB",
  "requestAId": "requestA",
  "requestBId": "requestB",
  "amount": 100,
  "status": "pending",
  "userAAccepted": false,
  "userBAccepted": false,
  "userAConfirmed": false,
  "userBConfirmed": false,
  "createdAt": "timestamp",
  "completedAt": null
}
```

Keep the existing notifications collection if already implemented.

---

# 23. Firestore Security Rules

This is a high-priority requirement.

Inspect the existing rules and fix them rather than blindly replacing them.

## Users

Users can update only their own profile.

## Requests

Authenticated users can:

- Create their own requests.
- Read active public requests.
- Update/cancel only their own request.

Do not allow arbitrary client-side manipulation of:

```text
matchedUserId
matchedRequestId
status
```

Matching state must be protected.

## Connections

Users can read a connection only when:

```text
userAId == request.auth.uid
OR
userBId == request.auth.uid
```

Do not allow arbitrary creation of completed connections.

Protect state transitions.

## Notifications

Users should only read their own notifications.

Do not allow arbitrary users to create notifications for other users without appropriate backend validation.

---

# 24. Expiration

Keep the existing 30-minute expiration idea if already implemented.

A request can remain `searching` until:

- matched
- cancelled
- expired

Expired requests must not be eligible for matching.

Do not over-engineer expiration.

---

# 25. Notifications

Notify users for:

### Match found

```text
🎉 Match Found

You have a matching exchange request.
```

### Connection accepted

```text
Connection Accepted

You can now complete your exchange.
```

### Exchange completed

```text
Exchange Completed

Your ₹100 exchange is complete.
```

Preserve existing FCM if implemented.

If FCM is incomplete, first make Firestore notification records reliable, then implement FCM separately.

---

# 26. Stitch UI/UX Redesign

Use **Stitch** for the redesigned UI/UX.

Create:

1. Splash
2. Onboarding
3. Login
4. Register
5. Forgot password
6. Home
7. Create Request
8. Public Requests
9. Match Found
10. Connection Details
11. My Connections
12. Exchange Completion
13. History
14. Profile
15. Notifications
16. Empty states
17. Loading states
18. Error states

Design direction:

- Modern
- Minimal
- Friendly
- Clean
- Student-focused
- Rounded cards
- Clear icons
- Large primary actions
- Good whitespace
- Accessible typography
- Material 3 principles

Do not make it look like a complicated banking app.

---

# 27. Navigation

Use four main sections:

```text
Home
Requests
Connections
Profile
```

Bottom navigation:

```text
🏠 Home
📋 Requests
🤝 Connections
👤 Profile
```

---

# 28. Remove Unnecessary Complexity

Inspect the existing project and remove/refactor only what is no longer needed:

- Partial matching
- Multiple exchange participants
- Offer systems
- Complex matching scores
- Unnecessary states
- Unused fields
- Unused providers
- Unused services

Do not blindly delete working code.

First verify whether each component is still used.

---

# 29. Preserve Existing Good Code

Keep and improve:

- Firebase Authentication
- Email verification
- Password reset
- Riverpod
- Firestore services
- Compatible models
- Transaction-based matching
- Profile
- History
- Notifications
- Existing tests
- Reusable UI components

---

# 30. Matching Service

Refactor the matching service around a simple operation such as:

```dart
Future<MatchResult?> findMatch(
  ExchangeRequest request,
)
```

It should:

1. Query opposite `has/wants`.
2. Require exact amount.
3. Ignore the current user.
4. Ignore non-searching requests.
5. Ignore expired requests.
6. Use a Firestore transaction.
7. Atomically update both requests.
8. Create a connection.
9. Return the match result.

Keep the code readable.

---

# 31. Firestore Query

For:

```text
has = cash
wants = digital
amount = 100
```

search for:

```text
has = digital
wants = cash
amount = 100
status = searching
```

Do not implement partial matching.

---

# 32. Concurrency

If two users try to connect to the same request, only one connection may succeed.

Use Firestore transactions/atomic updates.

Before matching:

```text
status == searching
```

After matching:

```text
status == matched
```

A second attempt should fail gracefully with:

```text
Request already matched.
```

---

# 33. Testing

Update existing tests.

### Exact match

```text
A: Cash → Digital ₹100
B: Digital → Cash ₹100
=> MATCH
```

### Different amount

```text
A: Cash → Digital ₹100
B: Digital → Cash ₹80
=> NO MATCH
```

### Same direction

```text
A: Cash → Digital ₹100
B: Cash → Digital ₹100
=> NO MATCH
```

### Same user

```text
A: Cash → Digital ₹100
A: Digital → Cash ₹100
=> NO MATCH
```

### Already matched

```text
=> NO MATCH
```

### Cancelled

```text
=> NO MATCH
```

### Expired

```text
=> NO MATCH
```

Also test:

- Authentication
- Create request
- Public request visibility
- Connection acceptance
- Completion
- Cancellation

---

# 34. Manual End-to-End Test

Create two accounts.

## User A

```text
Has: Digital
Wants: Cash
Amount: ₹100
```

## User B

```text
Has: Cash
Wants: Digital
Amount: ₹100
```

Expected:

```text
A creates request
        ↓
B creates request
        ↓
Matching engine detects exact opposite
        ↓
A ↔ B connection created
        ↓
Both receive notification
        ↓
Both accept
        ↓
Exchange happens outside app
        ↓
Both confirm
        ↓
Completed
        ↓
History updated
```

Also verify that User B can see User A's active request in the public Requests screen.

---

# 35. Preserve Authentication

Do not break:

- Registration
- Login
- Logout
- Email verification
- Forgot password
- Persistent login

Do not rewrite authentication unless required.

---

# 36. Preserve Profile

Keep:

- Profile
- Edit profile
- Completed exchange count
- Rating, if already implemented

Only update UI where needed for the Stitch redesign.

---

# 37. Final User Experience

## Home

```text
CashMate

Find your cash exchange match.

[ + Create Request ]

Your current request
₹100 Cash → Digital

Searching...
```

## Requests

```text
Requests

Arun
₹100
Cash → Digital
🎯 Exact match

[ Connect ]
```

## Automatic Match

```text
🎉 Match Found!

You matched with Arun.

₹100

Cash ↔ Digital

[ View Connection ]
```

## Connection

```text
Connected with Arun

₹100

You give:
Cash

You receive:
Digital

[ Mark as Completed ]
```

## History

```text
Completed Exchanges

₹100
Arun
Cash ↔ Digital
Completed ✓
```

---

# 38. Final Architecture

```text
                  CASHMATE
                     │
          ┌──────────┴──────────┐
          │                     │
          ▼                     ▼
       REQUESTS             MATCHING
          │                     │
          │              Exact opposite
          │              + same amount
          │                     │
          └──────────┬──────────┘
                     ▼
                 CONNECTION
                     │
              Both Accept
                     │
                     ▼
              Offline Exchange
                     │
              Both Confirm
                     │
                     ▼
                 COMPLETED
                     │
                     ▼
                  HISTORY
```

---

# 39. Implementation Order

Do not implement everything simultaneously.

### Step 1
Inspect the current project.

### Step 2
Create a backup/Git branch:

```bash
git checkout -b cashmate-redesign
```

### Step 3
Refactor models and Firestore schema.

### Step 4
Refactor matching service.

### Step 5
Implement public Requests screen.

### Step 6
Implement automatic exact matching.

### Step 7
Implement Connections.

### Step 8
Implement acceptance and completion.

### Step 9
Fix Firestore Security Rules.

### Step 10
Redesign UI using Stitch.

### Step 11
Update tests.

### Step 12
Run complete two-user testing.

### Step 13
Build release APK.

---

# 40. Development Rule

After every major change:

```bash
flutter analyze
flutter test
flutter run
```

Fix errors before continuing.

Do not leave broken code for later.

Do not remove features merely to make compilation succeed.

---

# 41. Definition of Done

The redesign is complete when:

- [ ] Existing Flutter project is preserved and refactored.
- [ ] App is renamed/rebranded as CashMate.
- [ ] Users can register with any valid email.
- [ ] Users can log in.
- [ ] Users can create one active request.
- [ ] Requests are publicly visible to authenticated users.
- [ ] Users can see other active requests.
- [ ] Exact compatible requests are automatically matched.
- [ ] Matching requires opposite `has/wants`.
- [ ] Matching requires exactly equal amounts.
- [ ] Users cannot match themselves.
- [ ] Already matched requests cannot be reused.
- [ ] Users can manually connect to compatible requests.
- [ ] A connection is created between matched users.
- [ ] Both users can accept the connection.
- [ ] Both users can confirm completion.
- [ ] Completed exchanges appear in history.
- [ ] Cancelled/expired requests cannot match.
- [ ] Firestore Security Rules are properly enforced.
- [ ] Notifications work.
- [ ] Stitch UI/UX is implemented.
- [ ] Loading states work.
- [ ] Empty states work.
- [ ] Error states work.
- [ ] Matching tests pass.
- [ ] Authentication tests pass.
- [ ] Two-user end-to-end flow works.
- [ ] Release APK builds successfully.

---

# Final Product Definition

> **CashMate is a simple application where users post what type of money they have, what type they need, and the amount. Everyone can browse active requests. When two users have exactly opposite requirements for the same amount, CashMate automatically identifies the match and connects them.**

The actual money exchange happens outside the application.

Keep the product simple, reliable, and easy to demonstrate.

**Do not turn this into a complicated financial marketplace.**
