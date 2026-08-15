# MediVerse REST API Backend

Flask-based REST API backend for the MediVerse Smart Healthcare & Emergency Platform.

## Features & Endpoints
- `/api/auth/login` & `/api/auth/register`: Password-based JWT authentication.
- `/api/auth/google`: Google OAuth / Gmail sign-in endpoint issuing JWT tokens.
- `/api/doctors`: Get verified doctor listings, filter by specialization and distance.
- `/api/doctors/<doc_id>`: Get single doctor profile with **4 verified certificates & documents**.
- `/api/donors`: Real-time blood donor listing and blood group filters.
- `/api/blood-requests`: Post and broadcast emergency SOS blood alerts.
- `/api/appointments`: Schedule doctor consultation slots.
- `/api/hospitals`: Network hospitals and emergency trauma centers.

## Environment & Running Locally
```bash
pip install -r requirements.txt
python run.py
```
*Server launches on port 5000.*
