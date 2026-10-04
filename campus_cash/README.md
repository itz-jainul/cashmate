# CampusCash 💵 ↔ 📱

> Peer-to-peer cash ↔ digital-money matching mobile application for college campuses.

CampusCash provides an elegant, safe platform that connects campus peers who have opposite cash and digital currency needs for the exact same amount.

---

## ⚡ Important Limitation & Invariants
- **No Financial Processing**: CampusCash **does not** hold, process, transfer, or escrow actual money.
- **Zero Credential Solicitation**: Never asks for UPI PINs, banking passwords, card numbers, or OTPs.
- **Matching Only**: Facilitates reciprocal intent discovery, handshake state coordination, and exchange history.

---

## 🚀 Tech Stack
- **Framework**: Flutter 3.44.4 (Dart 3.12.2)
- **UI System**: Material 3 Design
- **State Management**: Riverpod (`flutter_riverpod`)
- **Backend Services**: Firebase Authentication & Cloud Firestore
- **Security**: Firestore Security Rules (`firestore.rules`)

---

## 📁 Project Structure

```text
lib/
├── main.dart                       # Entry point & binding initialization
├── app/
│   ├── app.dart                    # MaterialApp & Root configuration
│   └── theme.dart                  # Material 3 Design System & Color Tokens
├── core/
│   ├── constants/                  # AppColors, AppStrings
│   └── widgets/                    # CustomButton, CustomTextField, StatusBadge, EmptyState
├── features/
│   ├── auth/                       # Firebase Auth, Login, Register, Forgot Password
│   ├── home/                       # Home Dashboard & Navigation
│   ├── exchange/                   # Request Creation, Atomic Matching Engine, Handshake, Meetup Chat
│   ├── history/                    # Previous Exchanges List
│   └── profile/                    # User Profile, Rating, & Settings
└── models/                         # UserModel, ExchangeRequestModel, ExchangeModel, ChatMessageModel
```

---

## 🛠️ Getting Started

### 1. Prerequisites
- Flutter SDK (3.44+)
- Android Studio / Android SDK

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Connect Firebase
1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com).
2. Enable **Authentication** (Email/Password provider).
3. Enable **Cloud Firestore** and deploy `firestore.rules`.
4. Add an Android app with package name `com.example.campus_cash` and download `google-services.json` into `android/app/`.

### 4. Run the App
```bash
flutter run
```

### 5. Run Automated Tests
```bash
flutter test
```

### 6. Build Release APK
```bash
flutter build apk --release
```
The resulting release binary will be generated at `build/app/outputs/flutter-apk/app-release.apk`.
