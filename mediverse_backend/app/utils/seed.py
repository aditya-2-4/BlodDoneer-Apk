import datetime
from werkzeug.security import generate_password_hash
from bson.objectid import ObjectId

def seed_database(db):
    if db['users'].count_documents({}) > 0:
        print("Database already seeded. Skipping...")
        return

    print("Seeding database with sample data...")
    password_hash = generate_password_hash('password123')

    # 1. Create Users
    users_data = [
        # Patients
        {
            "_id": ObjectId("60d5ec4a0000000000000001"),
            "role": "patient",
            "name": "John Doe",
            "email": "patient@mediverse.com",
            "password_hash": password_hash,
            "phone": "+1 555-0199",
            "location": {"lat": 12.9716, "lng": 77.5946},
            "created_at": datetime.datetime.now()
        },
        {
            "_id": ObjectId("60d5ec4a0000000000000002"),
            "role": "patient",
            "name": "Alice Smith",
            "email": "alice@mediverse.com",
            "password_hash": password_hash,
            "phone": "+1 555-0188",
            "location": {"lat": 12.9700, "lng": 77.5850},
            "created_at": datetime.datetime.now()
        },
        # Doctors
        {
            "_id": ObjectId("60d5ec4a0000000000000003"),
            "role": "doctor",
            "name": "Dr. Sarah Jenkins",
            "email": "sarah@mediverse.com",
            "password_hash": password_hash,
            "phone": "+1 555-0122",
            "location": {"lat": 12.9780, "lng": 77.5900},
            "created_at": datetime.datetime.now()
        },
        {
            "_id": ObjectId("60d5ec4a0000000000000004"),
            "role": "doctor",
            "name": "Dr. Robert Chen",
            "email": "robert@mediverse.com",
            "password_hash": password_hash,
            "phone": "+1 555-0133",
            "location": {"lat": 12.9650, "lng": 77.6000},
            "created_at": datetime.datetime.now()
        },
        {
            "_id": ObjectId("60d5ec4a0000000000000005"),
            "role": "doctor",
            "name": "Dr. Emily Taylor",
            "email": "emily@mediverse.com",
            "password_hash": password_hash,
            "phone": "+1 555-0144",
            "location": {"lat": 12.9800, "lng": 77.6100},
            "created_at": datetime.datetime.now()
        },
        # Donors
        {
            "_id": ObjectId("60d5ec4a0000000000000006"),
            "role": "donor",
            "name": "Michael Brown",
            "email": "michael@mediverse.com",
            "password_hash": password_hash,
            "phone": "+1 555-0155",
            "location": {"lat": 12.9730, "lng": 77.5970},
            "created_at": datetime.datetime.now()
        },
        {
            "_id": ObjectId("60d5ec4a0000000000000007"),
            "role": "donor",
            "name": "Jane Garcia",
            "email": "jane@mediverse.com",
            "password_hash": password_hash,
            "phone": "+1 555-0166",
            "location": {"lat": 12.9690, "lng": 77.5910},
            "created_at": datetime.datetime.now()
        },
        {
            "_id": ObjectId("60d5ec4a0000000000000008"),
            "role": "donor",
            "name": "David Wilson",
            "email": "david@mediverse.com",
            "password_hash": password_hash,
            "phone": "+1 555-0177",
            "location": {"lat": 12.9760, "lng": 77.6020},
            "created_at": datetime.datetime.now()
        },
        # Hospital Admin
        {
            "_id": ObjectId("60d5ec4a0000000000000009"),
            "role": "admin",
            "name": "Metro Admin",
            "email": "admin@mediverse.com",
            "password_hash": password_hash,
            "phone": "+1 555-0100",
            "location": {"lat": 12.9750, "lng": 77.5950},
            "created_at": datetime.datetime.now()
        }
    ]

    for user in users_data:
        db['users'].insert_one(user)

    # 2. Create Hospitals
    hospitals_data = [
        {
            "_id": ObjectId("60d5ed4a0000000000000001"),
            "name": "City Central Hospital",
            "location": {"lat": 12.9780, "lng": 77.5900},
            "contact": "+1 555-9001",
            "doctor_ids": [ObjectId("60d5ec4a0000000000000003")] # Jenkins
        },
        {
            "_id": ObjectId("60d5ed4a0000000000000002"),
            "name": "Metro Emergency Clinic",
            "location": {"lat": 12.9650, "lng": 77.6000},
            "contact": "+1 555-9002",
            "doctor_ids": [ObjectId("60d5ec4a0000000000000004")] # Chen
        },
        {
            "_id": ObjectId("60d5ed4a0000000000000003"),
            "name": "St. Jude Wellness Center",
            "location": {"lat": 12.9800, "lng": 77.6100},
            "contact": "+1 555-9003",
            "doctor_ids": [ObjectId("60d5ec4a0000000000000005")] # Taylor
        }
    ]

    for hospital in hospitals_data:
        db['hospitals'].insert_one(hospital)

    # 3. Create Doctors
    doctors_data = [
        {
            "user_id": ObjectId("60d5ec4a0000000000000003"),
            "specialization": "Cardiologist",
            "qualifications": "MD, DM (Cardiology), FACC",
            "experience": 12,
            "hospital_id": ObjectId("60d5ed4a0000000000000001"),
            "available_slots": ["09:00 AM", "10:30 AM", "02:00 PM", "04:30 PM"],
            "license_number": "MCI-78912-CARD",
            "consult_fee": "$50",
            "rating": 4.9,
            "reviews_count": 142,
            "bio": "Senior cardiologist specializing in interventional cardiology and preventative heart care. Ex-Resident at Mayo Clinic.",
            "documents": [
                {
                    "id": "doc_1",
                    "title": "Medical Practitioner License Certificate",
                    "type": "State Medical Council License",
                    "doc_number": "MCI-78912-CARD",
                    "issued_by": "Medical Council of India",
                    "issue_date": "2014-06-15",
                    "status": "Verified & Active",
                    "icon": "fa-certificate"
                },
                {
                    "id": "doc_2",
                    "title": "DM Interventional Cardiology Diploma",
                    "type": "Post-Doctoral Degree",
                    "doc_number": "JHM-2018-8812",
                    "issued_by": "Johns Hopkins School of Medicine",
                    "issue_date": "2018-05-20",
                    "status": "Verified",
                    "icon": "fa-graduation-cap"
                },
                {
                    "id": "doc_3",
                    "title": "Clinical Practice & Experience Letter",
                    "type": "Hospital Experience Endorsement",
                    "doc_number": "EXP-MAYO-2022",
                    "issued_by": "Mayo Clinic Cardiology Department",
                    "issue_date": "2022-11-10",
                    "status": "Verified",
                    "icon": "fa-file-signature"
                },
                {
                    "id": "doc_4",
                    "title": "Healthcare Quality & Patient Safety Accreditation",
                    "type": "Quality & Safety Board Certification",
                    "doc_number": "NABH-2025-441",
                    "issued_by": "National Board of Medical Examiners",
                    "issue_date": "2025-01-10",
                    "status": "Verified",
                    "icon": "fa-shield-halved"
                }
            ]
        },
        {
            "user_id": ObjectId("60d5ec4a0000000000000004"),
            "specialization": "Neurologist",
            "qualifications": "MD, DNB (Neurology)",
            "experience": 8,
            "hospital_id": ObjectId("60d5ed4a0000000000000002"),
            "available_slots": ["09:30 AM", "11:00 AM", "01:30 PM", "03:00 PM"],
            "license_number": "MCI-45621-NEUR",
            "consult_fee": "$60",
            "rating": 4.8,
            "reviews_count": 98,
            "bio": "Consultant Neurologist. Expert in diagnosis and management of stroke, epilepsy, and neuromuscular conditions.",
            "documents": [
                {
                    "id": "doc_1",
                    "title": "Neurology Practice Board License",
                    "type": "State Medical Council License",
                    "doc_number": "MCI-45621-NEUR",
                    "issued_by": "State Medical Council",
                    "issue_date": "2016-08-10",
                    "status": "Verified & Active",
                    "icon": "fa-certificate"
                },
                {
                    "id": "doc_2",
                    "title": "DNB Neurology Specialist Diploma",
                    "type": "Specialization Degree",
                    "doc_number": "DNB-2019-5510",
                    "issued_by": "National Board of Examinations",
                    "issue_date": "2019-03-12",
                    "status": "Verified",
                    "icon": "fa-graduation-cap"
                },
                {
                    "id": "doc_3",
                    "title": "Senior Residency Experience Certificate",
                    "type": "Hospital Experience Endorsement",
                    "doc_number": "EXP-METRO-2021",
                    "issued_by": "Metro Medical Center",
                    "issue_date": "2021-09-01",
                    "status": "Verified",
                    "icon": "fa-file-signature"
                },
                {
                    "id": "doc_4",
                    "title": "Neuro-Imaging & Stroke Care Certification",
                    "type": "Advanced Clinical Certification",
                    "doc_number": "STROKE-2024-118",
                    "issued_by": "World Stroke Organization",
                    "issue_date": "2024-04-18",
                    "status": "Verified",
                    "icon": "fa-shield-halved"
                }
            ]
        },
        {
            "user_id": ObjectId("60d5ec4a0000000000000005"),
            "specialization": "General Physician",
            "qualifications": "MBBS, MD (Medicine)",
            "experience": 15,
            "hospital_id": ObjectId("60d5ed4a0000000000000003"),
            "available_slots": ["08:00 AM", "10:00 AM", "12:00 PM", "05:00 PM"],
            "license_number": "MCI-12340-PHYS",
            "consult_fee": "$30",
            "rating": 4.7,
            "reviews_count": 215,
            "bio": "Experienced primary care provider focus on comprehensive health evaluations, geriatric care, and metabolic health management.",
            "documents": [
                {
                    "id": "doc_1",
                    "title": "General Medical Council Registration",
                    "type": "Primary Medical Council License",
                    "doc_number": "MCI-12340-PHYS",
                    "issued_by": "Medical Council",
                    "issue_date": "2011-04-05",
                    "status": "Verified & Active",
                    "icon": "fa-certificate"
                },
                {
                    "id": "doc_2",
                    "title": "MD Internal Medicine Degree",
                    "type": "Post-Graduate Degree",
                    "doc_number": "MD-2014-9901",
                    "issued_by": "University of Health Sciences",
                    "issue_date": "2014-06-25",
                    "status": "Verified",
                    "icon": "fa-graduation-cap"
                },
                {
                    "id": "doc_3",
                    "title": "Primary Care & Geriatric Experience Letter",
                    "type": "Hospital Experience Endorsement",
                    "doc_number": "EXP-STJUDE-2020",
                    "issued_by": "St. Jude Wellness Center",
                    "issue_date": "2020-01-15",
                    "status": "Verified",
                    "icon": "fa-file-signature"
                },
                {
                    "id": "doc_4",
                    "title": "Comprehensive Clinical Protocols Accreditation",
                    "type": "Quality Board Certification",
                    "doc_number": "NABH-2023-772",
                    "issued_by": "National Health Board",
                    "issue_date": "2023-08-30",
                    "status": "Verified",
                    "icon": "fa-shield-halved"
                }
            ]
        }
    ]


    for doc in doctors_data:
        db['doctors'].insert_one(doc)

    # 4. Create Donors
    donors_data = [
        {
            "user_id": ObjectId("60d5ec4a0000000000000006"),
            "blood_group": "O+",
            "last_donated": "2026-05-15",
            "availability_status": "available",
            "location": {"lat": 12.9730, "lng": 77.5970}
        },
        {
            "user_id": ObjectId("60d5ec4a0000000000000007"),
            "blood_group": "A-",
            "last_donated": "2026-04-10",
            "availability_status": "available",
            "location": {"lat": 12.9690, "lng": 77.5910}
        },
        {
            "user_id": ObjectId("60d5ec4a0000000000000008"),
            "blood_group": "B+",
            "last_donated": "2026-06-01",
            "availability_status": "busy",
            "location": {"lat": 12.9760, "lng": 77.6020}
        }
    ]

    for donor in donors_data:
        db['donors'].insert_one(donor)

    # 5. Create Appointments
    appointments_data = [
        {
            "patient_id": ObjectId("60d5ec4a0000000000000001"), # John Doe
            "doctor_id": ObjectId("60d5ec4a0000000000000003"), # Dr. Jenkins
            "date": (datetime.datetime.now() + datetime.timedelta(days=2)).strftime('%Y-%m-%d'),
            "time": "10:30 AM",
            "status": "pending",
            "reason": "Routine cholesterol check and blood pressure evaluation.",
            "created_at": datetime.datetime.now()
        },
        {
            "patient_id": ObjectId("60d5ec4a0000000000000001"), # John Doe
            "doctor_id": ObjectId("60d5ec4a0000000000000004"), # Dr. Chen
            "date": (datetime.datetime.now() - datetime.timedelta(days=5)).strftime('%Y-%m-%d'),
            "time": "01:30 PM",
            "status": "confirmed",
            "reason": "Follow-up consultation for migraine management.",
            "created_at": datetime.datetime.now() - datetime.timedelta(days=6)
        },
        {
            "patient_id": ObjectId("60d5ec4a0000000000000002"), # Alice Smith
            "doctor_id": ObjectId("60d5ec4a0000000000000003"), # Dr. Sarah Jenkins
            "date": (datetime.datetime.now() + datetime.timedelta(days=1)).strftime('%Y-%m-%d'),
            "time": "02:00 PM",
            "status": "confirmed",
            "reason": "General heart checkup and fatigue reports.",
            "created_at": datetime.datetime.now()
        }
    ]

    for appt in appointments_data:
        db['appointments'].insert_one(appt)

    # 6. Create Blood Requests
    blood_requests_data = [
        {
            "requester_id": ObjectId("60d5ec4a0000000000000001"), # John Doe
            "blood_group": "A-",
            "urgency": "critical",
            "location": {"lat": 12.9716, "lng": 77.5946},
            "status": "open",
            "created_at": datetime.datetime.now() - datetime.timedelta(hours=2)
        },
        {
            "requester_id": ObjectId("60d5ec4a0000000000000002"), # Alice Smith
            "blood_group": "O+",
            "urgency": "moderate",
            "location": {"lat": 12.9700, "lng": 77.5850},
            "status": "fulfilled",
            "created_at": datetime.datetime.now() - datetime.timedelta(days=3)
        }
    ]

    for req in blood_requests_data:
        db['blood_requests'].insert_one(req)

    print("Seeding completed successfully.")
