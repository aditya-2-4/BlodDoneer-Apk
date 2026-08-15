# MediVerse — Smart Healthcare & Emergency Assistance Mobile Platform

An integrated cross-platform mobile application that combines blood donation matching, doctor discovery, and clinic scheduling. It features location-based routing searches, emergency SOS broadcasts, and biometric access.

---

## Technical Stack
- **Frontend App**: Flutter (Dart) — Material 3 Design
- **State Management**: Provider
- **Backend API**: Python + Flask REST API (Decoupled Blueprints)
- **Database**: MongoDB (using PyMongo, with automatic in-memory MockDatabase fallback)
- **Maps**: OpenStreetMap (via `flutter_map` Leaflet tiling)
- **Authentication**: JWT Bearer token headers + Secure storage (`flutter_secure_storage`)

---

## Directory Structure
- **`/mediverse_app`**: Flutter codebase. Contains models, services, state providers, and screens.
- **`/mediverse_backend`**: Flask REST backend. Serves JSON endpoints and connects database layers.

---

## Quick Start Instructions

### 1. Launch Backend REST API
Ensure you have Python installed. In your terminal, run:
```bash
cd mediverse_backend
pip install -r requirements.txt
python run.py
```
*Note: The Flask server automatically falls back to an in-memory database and seeds dummy entries if local MongoDB is offline, allowing you to test the app instantly.*

### 2. Launch Flutter Mobile App
Ensure you have Flutter SDK installed. Connect an Android emulator or iOS simulator, and run:
```bash
cd mediverse_app
flutter pub get
flutter run
```

---

## Pre-Loaded Demo Accounts
All seeded accounts utilize the login password **`password123`**:
- **Patient/User**: `patient@mediverse.com` (Search clinics, matching donors, send SOS).
- **Doctor**: `sarah@mediverse.com` (Accept appointments, toggle active calendar slots).
- **Blood Donor**: `michael@mediverse.com` (List active nearby SOS broadcasts, toggle availability).
- **Admin**: `admin@mediverse.com` (Fulfill active requests, register staff doctors, view fl_chart graphs).

*Use the quick demo buttons at the bottom of the Login Screen to instantly fill these credentials and log in.*

---

## Developer Emulation Features
- **Mock GPS Coords**: The app starts in simulation mode by default (centered in Bangalore, India). This avoids emulator location permission errors.
- **FCM Push Notification Simulation**: Bypasses Firebase developer keys setup by showing local Toast drop-downs whenever clinic slot updates or SOS broadcasts trigger.
