# CampusCash --- Project Documentation & Viva Reference

## 1. Title
**CampusCash: Peer-to-Peer Cash and Digital Money Matching Application**

## 2. Abstract
CampusCash is a mobile application developed in Flutter with Firebase backend designed to solve the college campus liquidity mismatch problem. It facilitates reciprocal matching between students who have physical cash and desire digital money (UPI/wallets) and students who have digital money and require cash for the exact same amount. CampusCash acts strictly as a discovery and state coordination platform; it does not process, escrow, or transmit money, ensuring zero financial liability and strict privacy compliance.

## 3. Problem Statement
In collegiate environments, students frequently encounter cash-flow friction:
- Campus cafeterias, print shops, or local vendors may only accept cash or occasionally experience UPI server outages.
- Conversely, students without bank branch access nearby often accumulate cash and need digital money to pay fees, rent, or online subscriptions.
- Currently, finding a counterparty requires informal word-of-mouth or broadcast messages across group chats, which is inefficient, disruptive, and unreliable.

## 4. Objectives
1. Provide a reliable, automated matching platform for opposite cash/digital requirements.
2. Enforce atomic exact-amount matching with race condition prevention.
3. Facilitate a structured mutual handshake (acceptance and confirmation).
4. Provide auditability through historical exchange tracking.
5. Guarantee security by never collecting or storing banking credentials, UPI PINs, or passwords.

## 5. Existing System vs. Proposed System
| Dimension | Existing System (Informal/Manual) | Proposed System (CampusCash) |
| :--- | :--- | :--- |
| **Discovery** | Asking peers or spamming WhatsApp/Telegram groups | Automated real-time Firestore query matching |
| **Privacy** | Broadcasting personal phone numbers publicly | Pseudonymous matching with in-app state coordination |
| **Reliability** | High chance of ghosting or mismatched amounts | Atomic locking, mutual acceptance, and confirmation |
| **Audit Trail** | None | Full exchange history and trust rating |

## 6. Technologies Used
- **Frontend**: Flutter 3.44.4, Dart 3.12.2, Material 3 Design
- **State Management**: Riverpod (`flutter_riverpod`)
- **Backend / Cloud**: Firebase Authentication, Cloud Firestore, Firebase Cloud Messaging
- **Testing**: `flutter_test` (Unit tests for matching algorithm & widget tests for components)
- **Design & Layout**: Stitch UI

## 7. System Architecture
```text
                    ┌────────────────────────┐
                    │  CampusCash Mobile App │
                    │     (Flutter / M3)     │
                    └───────────┬────────────┘
                                │
               ┌────────────────┼────────────────┐
               ▼                ▼                ▼
         Firebase Auth      Firestore           FCM
               │                │                │
               │                ▼                │
               │        Matching Engine          │
               │   (Atomic DB Transactions)      │
               │                │                │
               └────────────────┼────────────────┘
                                ▼
                     Mutual Student Handshake
                                │
                                ▼
                      Offline Cash Exchange
                                │
                                ▼
                     Dual Receipt Confirmation
                                │
                                ▼
                     Persistent History Audit
```

## 8. Database Design
- **`users/{userId}`**: Stores profile metadata (`name`, `email`, `completedExchanges`, `rating`, `createdAt`).
- **`exchangeRequests/{requestId}`**: Stores active exchange requests (`has`, `wants`, `amount`, `status`, `matchedUserId`, `matchedRequestId`, `userAccepted`, `expiresAt`).
- **`exchanges/{exchangeId}`**: Historical record of completed exchanges (`userAId`, `userBId`, `amount`, `userAHas`, `userBHas`, `status`, `completedAt`).
- **`notifications/{notificationId}`**: Realtime notifications for match found and completion alerts.

## 9. Matching Algorithm & Concurrency Model
A match occurs when:
$$\text{Req}_A.\text{has} == \text{Req}_B.\text{wants} \quad \land \quad \text{Req}_A.\text{wants} == \text{Req}_B.\text{has} \quad \land \quad \text{Req}_A.\text{amount} == \text{Req}_B.\text{amount} \quad \land \quad \text{Req}_A.\text{userId} \neq \text{Req}_B.\text{userId}$$

Concurrency safety is guaranteed through **Firestore Transactions** (`runTransaction`):
1. Both documents are read inside the transaction to verify `status == 'searching'`.
2. Both documents are atomically transitioned to `status == 'matched'`.
3. If another peer claims either request concurrently, the transaction fails and retries or cleanly aborts.

## 10. Security & Privacy
1. **Firestore Security Rules**: Role-based access ensures users can only read and mutate their authorized documents.
2. **Zero-Credential Architecture**: The app strictly prohibits asking for or storing UPI PINs, bank details, card CVVs, or OTPs.
3. **Transient Intent**: Requests expire automatically after 30 minutes to prevent stale matches.

## 11. Viva Voce Cheat Sheet
- **Q1: Why doesn't the app handle payment transactions directly?**
  *Ans*: Implementing a payment gateway requires financial licensing, escrow banking, and PCI-DSS compliance. For an academic mini-project, matching intent while students settle peer-to-peer via their existing UPI apps provides immediate utility without financial risk.
- **Q2: How do you prevent double-matching under high traffic?**
  *Ans*: Through Firestore atomic transactions. Before mutating status to `matched`, the transaction verifies that both documents are still in the `searching` state.
- **Q3: What happens if a student claims money was not received?**
  *Ans*: The system requires dual confirmation (`userAConfirmed` AND `userBConfirmed`). An exchange only transitions to `completed` when both parties confirm. Either user can cancel if agreement is not reached.
