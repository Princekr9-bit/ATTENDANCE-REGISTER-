# Nirman Manager — Flutter App

SK Sangam Enterprises ka pura mobile app: **Gmail login, Mobile OTP login, Attendance (Hazri) Register, Workers, aur Payments (Cash / UPI / Bank)** — sab kuchh ek app mein.

## Features

- 🔐 **Google (Gmail) Login** — one-tap sign in
- 📱 **Mobile Number Login** — OTP ke saath (Firebase Phone Auth)
- 🏠 **Dashboard** — aaj ki hazri summary, worker count, recent payments
- ✅ **Attendance Register** — har worker ke liye Present / Half Day / Absent, kisi bhi date ke liye
- 👷 **Workers** — naam, mobile, role (Mistri/Labour/Helper...), daily wage
- 💰 **Payments** — Wage (mazdoori) ya Advance (kharchi) record karein
  - Payment methods: **Cash / UPI / Bank Transfer**
  - UPI chunne par worker ki UPI ID daal kar seedha **GPay / PhonePe / Paytm** app khol kar pay kar sakte hain
- ☁️ Saara data **Firebase (Firestore)** mein — har account ka data alag aur private

## Setup (ek baar karna hai)

### 1. Flutter install karein
[flutter.dev/docs/get-started/install](https://docs.flutter.dev/get-started/install) — Flutter 3.19+ chahiye.

### 2. Firebase project banayein
1. [console.firebase.google.com](https://console.firebase.google.com) par project banayein.
2. **Authentication → Sign-in method** mein enable karein:
   - **Google**
   - **Phone**
3. **Firestore Database** create karein (production mode), phir Rules mein ye lagayein:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{uid}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == uid;
       }
     }
   }
   ```
4. Android app add karein — package name: `com.sksangam.nirmanmanager`
   - Apni **SHA-1** aur **SHA-256** keys add karein (Google Sign-In aur Phone Auth ke liye zaroori):
     ```
     cd android && ./gradlew signingReport
     ```
   - `google-services.json` download karke `android/app/` mein rakhein.

### 3. Firebase config generate karein
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
(Ye `lib/firebase_options.dart` ko aapke project ki asli values se bhar dega.)

### 4. Run karein
```bash
flutter pub get
flutter run
```

## Project structure

```
lib/
  main.dart                  # App entry, Firebase init
  firebase_options.dart      # Firebase config (flutterfire configure se banega)
  src/
    app.dart                 # Auth gate (login ↔ home)
    theme.dart               # Brand colours (navy/orange)
    models/                  # Worker, Attendance, Payment
    services/
      auth_service.dart      # Google + Phone OTP login
      firestore_service.dart # Saara data CRUD
      upi_service.dart       # UPI app launcher (upi://pay)
    screens/
      auth/                  # Login, phone, OTP screens
      home/                  # Dashboard + bottom navigation
      workers/               # Worker list + add/delete
      attendance/            # Daily hazri register
      payments/              # Payment list + new payment sheet
```

## Notes

- UPI payment app ke through hota hai — app sirf payment launch karta hai aur record save karta hai; bank-level confirmation UPI app mein hi hota hai.
- Release build Play Store par daalne se pehle `android/app/build.gradle` mein apni signing key configure karein.
