# CampusCash --- Phase-Wise Project Development Plan

## 1. Project Overview

**CampusCash** is a simple peer-to-peer cash ↔ digital-money matching
mobile application for a college mini project.

### Core scenario

-   Student A has ₹500 cash and wants ₹500 digitally.
-   Student B has ₹500 digitally and wants ₹500 cash.
-   CampusCash finds the compatible requests.
-   The app connects the two users.
-   They exchange the money outside the app.
-   Both users confirm the exchange in the app.
-   The completed exchange appears in history.

### Important limitation

CampusCash **does not process, hold, transfer, or store actual money**.

It only:

1.  Creates exchange requests.
2.  Finds compatible users.
3.  Connects users.
4.  Tracks exchange status.
5.  Records exchange history.

------------------------------------------------------------------------

# 2. Technology Stack

  Area             Technology
  ---------------- --------------------------
  Mobile app       Flutter
  Language         Dart
  UI               Material 3
  Backend          Firebase
  Authentication   Firebase Authentication
  Database         Cloud Firestore
  Notifications    Firebase Cloud Messaging
  Source control   Git + GitHub
  UI/UX design     Stitch
  Target           Android first

Recommended state management: **Riverpod**.

The project should remain simple. Do not introduce a separate Node.js
backend unless there is a specific requirement.

------------------------------------------------------------------------

# 3. Overall Architecture

``` text
                    ┌──────────────────────┐
                    │      Flutter App     │
                    │       Android        │
                    └──────────┬───────────┘
                               │
             ┌─────────────────┼─────────────────┐
             │                 │                 │
             ▼                 ▼                 ▼
      Firebase Auth       Firestore          FCM
             │                 │                 │
             │                 ▼                 │
             │         Matching Requests         │
             │                 │                 │
             └─────────────────┼─────────────────┘
                               ▼
                     Match Two Students
                               │
                               ▼
                    Offline Money Exchange
                               │
                               ▼
                     Both Users Confirm
                               │
                               ▼
                          History
```

------------------------------------------------------------------------

# 4. Development Principles

Follow these rules throughout the project:

-   Build incrementally.
-   Keep the UI simple.
-   Keep business logic outside UI widgets.
-   Do not over-engineer the backend.
-   Test every phase before moving to the next.
-   Never store passwords in Firestore.
-   Never ask users for UPI PINs, banking passwords, or OTPs.
-   Never claim that the app transferred money.
-   Use Firestore Security Rules, not only client-side checks.
-   Use exact amount matching in version 1.
-   Allow only one active request per user in version 1.

------------------------------------------------------------------------

# PHASE 0 --- Project Planning

## Goal

Define the project before writing code.

## Tasks

-   Finalize project name: **CampusCash**
-   Define the problem statement.
-   Define project objectives.
-   Define the core user flow.
-   Define the technology stack.
-   Create a GitHub repository.
-   Create a Firebase project.
-   Create a Stitch design workspace/project.

## Problem Statement

In a college environment, some students may have physical cash while
needing digital money, while other students may have digital money while
needing physical cash.

Students currently need to find a suitable person manually.

CampusCash provides a simple platform that matches users with opposite
cash/digital requirements and the same amount.

## Project Objective

Create a mobile application that allows users to:

1.  Register and log in.
2.  Create cash/digital exchange requests.
3.  Find compatible requests.
4.  Accept a match.
5.  Confirm an offline exchange.
6.  View exchange history.

## Success Criteria

The following flow must work:

``` text
Register
    ↓
Login
    ↓
Create ₹500 Cash → Digital request
    ↓
Second user creates ₹500 Digital → Cash request
    ↓
Match found
    ↓
Both accept
    ↓
Exchange money outside app
    ↓
Both confirm
    ↓
Completed
    ↓
History
```

------------------------------------------------------------------------

# PHASE 1 --- Development Environment Setup

## Goal

Prepare the Flutter and Firebase development environment.

## Tasks

### Install

-   Flutter SDK
-   Android Studio
-   Android SDK
-   Android emulator or connect an Android phone
-   VS Code or Android Studio
-   Git
-   GitHub account

## Verify Flutter

Run:

``` bash
flutter doctor
```

Fix all important errors.

Then:

``` bash
flutter --version
```

## Create project

``` bash
flutter create campus_cash
cd campus_cash
```

Run:

``` bash
flutter run
```

Verify that the default Flutter application launches.

## Git setup

``` bash
git init
git add .
git commit -m "Initial Flutter project"
```

Create a GitHub repository and push the project.

## Deliverable

A clean Flutter project that runs successfully on Android.

------------------------------------------------------------------------

# PHASE 2 --- Firebase Setup

## Goal

Connect Flutter to Firebase.

## Firebase services

Enable:

-   Firebase Authentication
-   Cloud Firestore
-   Firebase Cloud Messaging

Storage can be added later if profile images are implemented.

## Firebase Authentication

Enable:

``` text
Email/Password
```

Users may use any valid email address.

Do not require a college email domain.

Enable email verification.

## Firestore

Create a Firestore database.

Start with appropriate development settings, then apply proper Security
Rules before the project is considered complete.

## Firebase Flutter integration

Use FlutterFire.

Typical setup:

``` bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Add the required Firebase Flutter packages.

Typical packages:

``` yaml
firebase_core
firebase_auth
cloud_firestore
firebase_messaging
```

Add Riverpod:

``` yaml
flutter_riverpod
```

Other packages should be added only when needed.

## Deliverable

Flutter successfully connects to Firebase.

------------------------------------------------------------------------

# PHASE 3 --- Stitch UI/UX Design

## Goal

Design the complete mobile experience in Stitch before implementing the
final UI in Flutter.

## Design principles

The design should be:

-   Modern
-   Minimal
-   Friendly
-   Trustworthy
-   Student-oriented
-   Clean
-   Mobile-first
-   Easy to understand

Avoid making it look like a complicated banking app.

CampusCash is a **matching application**, not a bank.

## Design system

Define:

-   Primary color
-   Secondary color
-   Background colors
-   Text colors
-   Typography
-   Button styles
-   Card styles
-   Input styles
-   Icons
-   Status indicators
-   Spacing
-   Corner radius
-   Shadows

Use a restrained color palette and strong contrast.

## Stitch screens

Create designs for:

1.  Splash screen
2.  Onboarding
3.  Login
4.  Register
5.  Forgot password
6.  Email verification
7.  Home
8.  Create exchange
9.  Amount entry
10. Searching for match
11. Match found
12. Match details
13. Exchange confirmation
14. Requests
15. History
16. Profile
17. Edit profile
18. Notifications
19. Empty states
20. Loading states
21. Error states
22. Cancel confirmation dialog
23. Safety reminder

## Important UX

The home screen should communicate the main action immediately.

Example:

``` text
What do you need?

[ I Have Cash ]
[ I Have Digital Money ]
```

The main flow should require as few steps as possible.

## Deliverable

A complete Stitch mobile UI/UX design system and all major screens.

------------------------------------------------------------------------

# PHASE 4 --- Flutter Project Architecture

## Goal

Create a maintainable project structure before implementing features.

Recommended structure:

``` text
lib/
│
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── routes.dart
│   └── theme.dart
│
├── core/
│   ├── constants/
│   ├── utils/
│   ├── services/
│   └── widgets/
│
├── features/
│   ├── auth/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── services/
│   │
│   ├── home/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── exchange/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── services/
│   │
│   ├── history/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── notifications/
│   │   ├── screens/
│   │   └── services/
│   │
│   └── profile/
│       ├── screens/
│       └── widgets/
│
└── models/
```

## Rules

-   Keep UI widgets focused on presentation.
-   Put Firebase operations in services/repositories.
-   Put state in Riverpod providers.
-   Keep matching logic separate from screens.
-   Reuse common UI components.

## Deliverable

Flutter project structure is ready for feature development.

------------------------------------------------------------------------

# PHASE 5 --- Theme and Reusable UI Components

## Goal

Implement the design system from Stitch.

## Create

-   App theme
-   Typography
-   Buttons
-   Text fields
-   Cards
-   Chips
-   Status badges
-   Loading indicators
-   Dialogs
-   Empty-state widgets
-   Error widgets
-   Bottom navigation
-   App bars

## Important

The Flutter implementation should visually follow the Stitch designs.

Do not redesign every screen independently.

## Deliverable

A reusable UI component library matching the Stitch design.

------------------------------------------------------------------------

# PHASE 6 --- Authentication

## Goal

Implement user registration and login.

## Screens

### Splash

Check Firebase authentication state.

### Login

Fields:

``` text
Email
Password
```

Actions:

``` text
Login
Forgot password
Create account
```

### Register

Fields:

``` text
Full name
Email
Password
Confirm password
```

### Email verification

After registration:

1.  Create Firebase Auth account.
2.  Send verification email.
3.  Create user document.
4.  Ask the user to verify email.

## Validation

-   Name cannot be empty.
-   Email must be valid.
-   Password must meet minimum requirements.
-   Password confirmation must match.

## Forgot password

Use Firebase password reset email.

## Logout

Sign out using Firebase Authentication.

## Deliverable

A user can:

-   Register.
-   Verify email.
-   Login.
-   Logout.
-   Reset password.
-   Stay logged in between app sessions.

------------------------------------------------------------------------

# PHASE 7 --- User Profile

## Goal

Create the user profile system.

## Firestore collection

``` text
users/{userId}
```

Schema:

``` json
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

## Profile screen

Show:

``` text
Profile Photo

Arun Kumar
arun@gmail.com

Completed Exchanges: 0
Rating: 5.0 ★

Edit Profile
Notifications
Privacy
Help
Logout
```

## Deliverable

Users can view and edit their basic profile.

------------------------------------------------------------------------

# PHASE 8 --- Home Screen

## Goal

Create the main application experience.

## Header

``` text
Hi, Arun 👋

Exchange money easily with another student.
```

## Main actions

``` text
What do you need?

[ 💵 I Have Cash ]
[ 📱 I Have Digital Money ]
```

## Active request

If the user has an active request:

``` text
Your Active Request

₹500
Cash → Digital

Searching for a match...
```

If there is no request:

``` text
No active request.

[ Create Request ]
```

## Deliverable

Home screen connected to real Firebase data.

------------------------------------------------------------------------

# PHASE 9 --- Exchange Request Creation

## Goal

Allow a user to create an exchange request.

## Step 1

Ask:

``` text
What do you have?

[ Cash ]
[ Digital Money ]
```

## Step 2

Automatically determine the desired type.

If:

``` text
Has = Cash
```

then:

``` text
Wants = Digital
```

If:

``` text
Has = Digital
```

then:

``` text
Wants = Cash
```

Do not allow:

``` text
Cash → Cash
Digital → Digital
```

## Step 3

Enter amount.

Examples:

``` text
₹100
₹200
₹500
₹1000
Custom amount
```

## Validation

-   Amount \> 0
-   Numeric
-   INR
-   Reasonable configurable maximum
-   One active request per user

## Firestore

Create:

``` text
exchangeRequests/{requestId}
```

Schema:

``` json
{
  "userId": "uid",
  "userName": "Arun",
  "has": "cash",
  "wants": "digital",
  "amount": 500,
  "status": "searching",
  "matchedUserId": null,
  "matchedRequestId": null,
  "userAccepted": false,
  "matchedUserAccepted": false,
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "expiresAt": "timestamp"
}
```

## Deliverable

A user can create an active exchange request.

------------------------------------------------------------------------

# PHASE 10 --- Matching Algorithm

## Goal

Implement the core CampusCash matching system.

## Matching rule

Two requests match when:

``` text
Request A:
has = cash
wants = digital
amount = 500
status = searching
```

and:

``` text
Request B:
has = digital
wants = cash
amount = 500
status = searching
```

The result is:

``` text
MATCH
```

## Generic rule

``` text
A.has == B.wants
AND
A.wants == B.has
AND
A.amount == B.amount
AND
A.userId != B.userId
AND
A.status == searching
AND
B.status == searching
```

## Query

For example, if the current request is:

``` text
has = cash
wants = digital
amount = 500
```

search for:

``` text
has = digital
wants = cash
amount = 500
status = searching
```

## Race condition protection

Use Firestore transactions where necessary.

Before finalizing a match, verify both requests are still:

``` text
status = searching
```

Then atomically update both.

This prevents two users from claiming the same request simultaneously.

## After match

Update both requests:

``` text
status = matched
```

Store:

``` text
matchedUserId
matchedRequestId
```

## Deliverable

Two compatible requests reliably match.

------------------------------------------------------------------------

# PHASE 11 --- Searching for Match UI

## Goal

Provide a clear waiting state.

Example:

``` text
Looking for a match...

₹500

You have:
Cash

You want:
Digital Money

We are looking for another user
with the opposite requirement.

[ Cancel Request ]
```

Use a subtle animation or progress indicator.

Do not continuously poll Firestore every second.

Use Firestore realtime listeners where appropriate.

## No match state

``` text
No match found yet.

We'll keep looking for another user.

[ Cancel Request ]
```

## Deliverable

A user can create a request and see its live status.

------------------------------------------------------------------------

# PHASE 12 --- Match Found

## Goal

Display a clear match notification and details.

Example:

``` text
🎉 Match Found!

Rahul Kumar

₹500

You give:
Digital Money

You receive:
Cash

[ View Match ]
```

Show only necessary user information.

Do not expose sensitive financial information.

## Deliverable

Both users can see that a match has been found.

------------------------------------------------------------------------

# PHASE 13 --- Match Acceptance

## Goal

Require both users to accept.

Initial:

``` text
status = matched
```

User A accepts:

``` text
userAccepted = true
```

User B accepts:

``` text
matchedUserAccepted = true
```

Only when both accept:

``` text
status = accepted
```

## UI

``` text
Exchange with Rahul

₹500

Your side:
Digital → Cash

Waiting for both users to accept.

[ Accept Exchange ]
[ Cancel ]
```

## Deliverable

A match becomes accepted only when both users agree.

------------------------------------------------------------------------

# PHASE 14 --- Exchange Details and Safety

## Goal

Provide instructions before the physical exchange.

Display:

``` text
Exchange Ready

Amount: ₹500
Partner: Rahul Kumar

1. Meet in a safe public location.
2. Verify the other person's identity.
3. Exchange the money.
4. Confirm only after receiving the money.

[ Confirm Exchange ]
```

## Safety reminder

Never ask for:

-   UPI PIN
-   Bank password
-   OTP
-   Card PIN
-   Banking credentials

The application does not process the payment.

## Deliverable

Users understand that the actual exchange happens outside the app.

------------------------------------------------------------------------

# PHASE 15 --- Exchange Confirmation

## Goal

Ensure both participants confirm the exchange.

User A sees:

``` text
I have received the money
```

User B sees:

``` text
I have received the money
```

Store:

``` text
userAConfirmed
userBConfirmed
```

Only when both are true:

``` text
status = completed
```

Set:

``` text
completedAt = timestamp
```

## Deliverable

An exchange is completed only after both users confirm.

------------------------------------------------------------------------

# PHASE 16 --- Cancellation

## Goal

Allow cancellation before completion.

Confirmation dialog:

``` text
Cancel Exchange?

Are you sure?

[ Keep Exchange ]
[ Cancel ]
```

Set:

``` text
status = cancelled
```

Do not allow cancelled requests to be matched.

## Deliverable

Users can safely cancel active exchanges.

------------------------------------------------------------------------

# PHASE 17 --- Exchange History

## Goal

Show previous exchanges.

Create:

``` text
exchanges/{exchangeId}
```

Schema:

``` json
{
  "userAId": "uidA",
  "userBId": "uidB",
  "userAName": "Arun",
  "userBName": "Rahul",
  "amount": 500,
  "userAHas": "cash",
  "userBHas": "digital",
  "status": "completed",
  "userAConfirmed": true,
  "userBConfirmed": true,
  "createdAt": "timestamp",
  "completedAt": "timestamp"
}
```

## History UI

``` text
Exchange History

₹500
Cash → Digital
Rahul Kumar
Completed

₹200
Digital → Cash
Karthik
Completed
```

Use clear status badges.

## Deliverable

Users can view completed and cancelled exchanges.

------------------------------------------------------------------------

# PHASE 18 --- Requests Screen

## Goal

Give users a central place to manage current requests.

Show:

### Searching

``` text
₹500
Cash → Digital
Searching...
```

### Matched

``` text
₹500
Cash → Digital
Matched with Rahul
```

### Accepted

``` text
₹500
Cash → Digital
Exchange ready
```

Allow appropriate actions:

-   View
-   Accept
-   Cancel
-   Confirm

## Deliverable

Users can manage their active exchange lifecycle.

------------------------------------------------------------------------

# PHASE 19 --- Notifications

## Goal

Notify users when important events happen.

Use Firebase Cloud Messaging where practical.

## Notification events

### Match found

``` text
🎉 Match Found

You have been matched with Rahul for ₹500.
```

### Match accepted

``` text
Exchange Accepted

Both users accepted the exchange.
```

### Exchange completed

``` text
Exchange Completed

Your ₹500 exchange has been completed.
```

Create:

``` text
notifications/{notificationId}
```

Schema:

``` json
{
  "userId": "uid",
  "title": "Match Found",
  "message": "You have been matched...",
  "type": "match_found",
  "isRead": false,
  "createdAt": "timestamp"
}
```

## Deliverable

Users receive useful notifications without excessive notifications.

------------------------------------------------------------------------

# PHASE 20 --- Request Expiration

## Goal

Prevent old requests from remaining active forever.

Default:

``` text
30 minutes
```

Make this configurable.

Set:

``` text
expiresAt
```

When expired:

``` text
status = expired
```

Expired requests must not participate in matching.

## UI

Show:

``` text
This request has expired.

[ Create New Request ]
```

## Deliverable

Old requests cannot remain indefinitely active.

------------------------------------------------------------------------

# PHASE 21 --- Firestore Security Rules

## Goal

Protect user and exchange data.

Users should be able to:

-   Read their own profile.
-   Update their own profile.
-   Create their own requests.
-   Modify their own requests.
-   View exchanges where they are participants.
-   View their own notifications.

Users must not be able to:

-   Edit another user's profile.
-   Edit another user's request.
-   Mark another user's exchange as completed.
-   Read unrelated private information.

Use Firestore Security Rules.

Do not rely only on Flutter-side validation.

## Deliverable

Secure Firestore access rules.

------------------------------------------------------------------------

# PHASE 22 --- Loading, Empty, and Error States

## Goal

Make the application feel polished.

## Loading

Use:

-   Progress indicators
-   Skeletons where appropriate

Do not freeze the UI.

## Empty state

``` text
No exchange requests yet.

Create a request to find someone.

[ Create Request ]
```

## No match

``` text
No match found yet.

We'll keep looking.
```

## Error

Convert raw Firebase errors into friendly messages.

Examples:

``` text
Unable to connect.
Please check your internet connection.
```

``` text
Your session has expired.
Please log in again.
```

## Deliverable

Every important screen handles loading, empty, success, and error
states.

------------------------------------------------------------------------

# PHASE 23 --- Validation and Edge Cases

## Authentication

Test:

-   Empty email
-   Invalid email
-   Wrong password
-   Existing account
-   Weak password
-   Password mismatch
-   Unverified email

## Exchange

Test:

-   Amount = 0
-   Negative amount
-   Invalid amount
-   Same has/wants value
-   Duplicate active request
-   Request cancellation
-   Expired request

## Matching

Test:

``` text
₹500 cash → digital
₹500 digital → cash
=> MATCH
```

``` text
₹500 cash → digital
₹300 digital → cash
=> NO MATCH
```

``` text
₹500 cash → digital
₹500 cash → digital
=> NO MATCH
```

``` text
₹500 cash → digital
same user's own request
=> NO MATCH
```

## Race conditions

Test two users trying to claim the same request.

Only one match should succeed.

------------------------------------------------------------------------

# PHASE 24 --- Unit and Widget Testing

## Goal

Create basic automated tests.

## Unit tests

Test:

-   Matching logic
-   Amount validation
-   Request state transitions

Example:

``` text
match(
  cash,
  digital,
  500,
  digital,
  cash,
  500
)
=> true
```

## Widget tests

Test:

-   Login form
-   Registration form
-   Create request form
-   Home screen
-   Match screen

## Deliverable

A basic test suite for the most important functionality.

------------------------------------------------------------------------

# PHASE 25 --- UI Polish

## Goal

Make Flutter match Stitch designs closely.

Check:

-   Font sizes
-   Font weights
-   Spacing
-   Colors
-   Button sizes
-   Card radius
-   Icons
-   Bottom navigation
-   Empty states
-   Loading states
-   Error states

## Accessibility

Ensure:

-   Good text contrast
-   Touch targets are large enough
-   Text is readable
-   Important actions are obvious
-   Do not rely only on color to communicate status

## Deliverable

Polished UI matching Stitch.

------------------------------------------------------------------------

# PHASE 26 --- Performance Optimization

## Goal

Make the app responsive and efficient.

## Rules

-   Avoid unnecessary Firestore reads.
-   Use realtime listeners only where needed.
-   Avoid querying every second.
-   Use pagination for large history lists if needed.
-   Dispose controllers/listeners properly.
-   Avoid rebuilding large widget trees unnecessarily.
-   Use cached images if profile images are added.

## Deliverable

Smooth app performance.

------------------------------------------------------------------------

# PHASE 27 --- Security Review

Before final submission, verify:

-   Passwords are never stored in Firestore.
-   UPI PINs are never requested.
-   Banking passwords are never requested.
-   OTPs are never requested.
-   Firestore rules are enabled.
-   Users cannot edit other users' data.
-   Users cannot complete another user's exchange.
-   Sensitive information is not exposed in logs.
-   Firebase configuration is handled appropriately.
-   Debug logging is removed or minimized for release.

------------------------------------------------------------------------

# PHASE 28 --- Final End-to-End Test

Run the complete scenario with two test accounts.

## User A

``` text
Email: usera@test.com

Has: Cash
Wants: Digital
Amount: ₹500
```

## User B

``` text
Email: userb@test.com

Has: Digital
Wants: Cash
Amount: ₹500
```

## Test flow

``` text
User A registers
        ↓
User B registers
        ↓
User A creates ₹500 request
        ↓
User B creates opposite ₹500 request
        ↓
Match found
        ↓
Both accept
        ↓
Exchange ready
        ↓
User A confirms
        ↓
User B confirms
        ↓
Exchange completed
        ↓
History updated
```

Verify every Firestore document and status transition.

------------------------------------------------------------------------

# PHASE 29 --- Release Build

## Goal

Create a production-like Android build.

Run:

``` bash
flutter analyze
```

Then:

``` bash
flutter test
```

Then:

``` bash
flutter build apk --release
```

Test the release APK on a real Android device.

## Deliverable

A working release APK.

------------------------------------------------------------------------

# PHASE 30 --- Documentation

Create project documentation containing:

## 1. Title

**CampusCash --- Peer-to-Peer Cash and Digital Money Matching
Application**

## 2. Abstract

Explain the problem and solution.

## 3. Problem Statement

Explain why students need an easy way to find compatible cash/digital
exchange partners.

## 4. Objectives

List the project goals.

## 5. Existing System

Explain the manual process.

## 6. Proposed System

Explain CampusCash.

## 7. Technologies Used

``` text
Flutter
Dart
Firebase Authentication
Cloud Firestore
Firebase Cloud Messaging
Riverpod
Stitch
Git/GitHub
```

## 8. System Architecture

Include the architecture diagram.

## 9. Database Design

Explain:

-   users
-   exchangeRequests
-   exchanges
-   notifications

## 10. Matching Algorithm

Explain the opposite requirement + exact amount rule.

## 11. UI/UX

Include Stitch screenshots.

## 12. Implementation

Include Flutter screenshots.

## 13. Testing

Explain test cases.

## 14. Security

Explain Firebase Authentication and Firestore Security Rules.

## 15. Limitations

Mention that:

-   The application does not process actual payments.
-   Matching is exact amount in version 1.
-   Users must complete the physical exchange themselves.
-   The application is intended as a college mini-project.

## 16. Future Enhancements

Possible future features:

-   Partial amount matching
-   QR-based user matching
-   Nearby matching
-   Better reputation system
-   Dispute reporting
-   More advanced notifications
-   Admin dashboard
-   Transaction analytics

Do not implement these unless required.

------------------------------------------------------------------------

# PHASE 31 --- Presentation Preparation

## Recommended presentation structure

### Slide 1 --- Title

CampusCash

Peer-to-Peer Cash ↔ Digital Money Matching

### Slide 2 --- Problem

Students often need to convert cash to digital money or digital money to
cash but have difficulty finding someone with the opposite requirement.

### Slide 3 --- Proposed Solution

CampusCash connects users with compatible requirements.

### Slide 4 --- Technology Stack

``` text
Flutter
Dart
Firebase
Firestore
Firebase Auth
FCM
Stitch
```

### Slide 5 --- Architecture

Show the system architecture.

### Slide 6 --- User Flow

``` text
Register
↓
Create Request
↓
Find Match
↓
Accept
↓
Exchange
↓
Confirm
↓
History
```

### Slide 7 --- Matching Algorithm

Explain exact amount + opposite requirement.

### Slide 8 --- UI/UX

Show Stitch designs.

### Slide 9 --- Working Application

Show actual Flutter screens.

### Slide 10 --- Database

Show Firestore structure.

### Slide 11 --- Security

Explain authentication and Firestore rules.

### Slide 12 --- Future Enhancements

Show possible future improvements.

------------------------------------------------------------------------

# PHASE 32 --- Viva Preparation

Be ready to answer:

## Why Flutter?

Because Flutter allows a single codebase for mobile development and
provides fast UI development.

## Why Firebase?

Firebase removes the need to build and host a custom backend for a small
project and provides authentication, database, and notifications.

## Why Firestore?

Firestore is a cloud NoSQL database with realtime listeners, which is
useful for exchange-request status updates.

## Why not build a payment gateway?

The project focuses on matching users, not processing payments.
Integrating actual financial infrastructure would add unnecessary
complexity and security requirements.

## How does matching work?

Two users match when their required money types are opposite and their
requested amounts are equal.

## How do you prevent duplicate matching?

Use Firestore transactions/atomic updates and verify both requests are
still in the `searching` state before creating a match.

## How is authentication handled?

Firebase Authentication handles email/password authentication. Passwords
are not stored in Firestore.

## How is data protected?

Firebase Authentication identifies users, while Firestore Security Rules
restrict access to authorized documents and operations.

## What happens if there is no match?

The request remains in the `searching` state until it is matched,
cancelled, or expires.

## Does the app transfer money?

No. The app only facilitates the connection. Users exchange money
outside the app.

------------------------------------------------------------------------

# Final Feature List

The completed mini-project should contain:

-   [x] Email/password registration
-   [x] Any valid email address
-   [x] Email verification
-   [x] Login
-   [x] Logout
-   [x] Password reset
-   [x] User profile
-   [x] Home screen
-   [x] Cash/digital selection
-   [x] Amount entry
-   [x] Exchange request
-   [x] Exact amount matching
-   [x] Opposite requirement matching
-   [x] Match notification
-   [x] Match acceptance
-   [x] Exchange confirmation
-   [x] Cancellation
-   [x] Request expiration
-   [x] Exchange history
-   [x] Firebase Security Rules
-   [x] Loading states
-   [x] Empty states
-   [x] Error handling
-   [x] Basic notifications
-   [x] Unit/widget tests
-   [x] Stitch UI/UX
-   [x] Android release APK
-   [x] Project documentation

------------------------------------------------------------------------

# Final Core Flow

The most important thing to get working is:

``` text
                  USER A
                    │
                    ▼
              Create Request
              ₹500 Cash → Digital
                    │
                    │
                    ▼
               Firestore
                    │
                    ▼
              Matching Engine
                    ▲
                    │
                    │
              Firestore
                    │
                    ▲
              Create Request
              ₹500 Digital → Cash
                    │
                    ▼
                  USER B


              MATCH FOUND
                    │
                    ▼
              Both Accept
                    │
                    ▼
           Exchange Offline
                    │
                    ▼
           Both Confirm
                    │
                    ▼
              COMPLETED
                    │
                    ▼
                HISTORY
```

This core flow should be completely stable before implementing optional
features.

------------------------------------------------------------------------

# Recommended Development Sequence

Use this exact sequence:

``` text
PHASE 0   Planning
   ↓
PHASE 1   Flutter Setup
   ↓
PHASE 2   Firebase Setup
   ↓
PHASE 3   Stitch UI/UX
   ↓
PHASE 4   Flutter Architecture
   ↓
PHASE 5   Theme + Components
   ↓
PHASE 6   Authentication
   ↓
PHASE 7   Profile
   ↓
PHASE 8   Home
   ↓
PHASE 9   Exchange Request
   ↓
PHASE 10  Matching Algorithm
   ↓
PHASE 11  Searching UI
   ↓
PHASE 12  Match Found
   ↓
PHASE 13  Match Acceptance
   ↓
PHASE 14  Exchange Details
   ↓
PHASE 15  Confirmation
   ↓
PHASE 16  Cancellation
   ↓
PHASE 17  History
   ↓
PHASE 18  Requests
   ↓
PHASE 19  Notifications
   ↓
PHASE 20  Expiration
   ↓
PHASE 21  Security Rules
   ↓
PHASE 22  UI States
   ↓
PHASE 23  Edge Cases
   ↓
PHASE 24  Testing
   ↓
PHASE 25  UI Polish
   ↓
PHASE 26  Performance
   ↓
PHASE 27  Security Review
   ↓
PHASE 28  End-to-End Test
   ↓
PHASE 29  Release APK
   ↓
PHASE 30  Documentation
   ↓
PHASE 31  Presentation
   ↓
PHASE 32  Viva Preparation
```

# Definition of Done

The project is complete when:

-   The Flutter app runs on Android.
-   Firebase Authentication works.
-   Any valid email can register.
-   Users can create exchange requests.
-   Opposite requests with equal amounts match.
-   The same request cannot be matched twice.
-   Both users must accept.
-   Both users must confirm completion.
-   Completed exchanges appear in history.
-   Cancelled/expired requests cannot be matched.
-   Firestore Security Rules protect the data.
-   Stitch designs are reflected in the Flutter UI.
-   Tests pass.
-   Release APK works on a real Android device.
-   Documentation and presentation materials are ready.
