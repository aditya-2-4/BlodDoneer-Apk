import datetime
from flask import Blueprint, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from bson.objectid import ObjectId
from app.utils.db import db
from app.models.models import serialize_doc
from app.utils.jwt_helper import generate_token

auth_bp = Blueprint('api_auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json() or {}
    role = data.get('role')
    name = data.get('name')
    email = data.get('email')
    password = data.get('password')
    phone = data.get('phone', '')
    location = data.get('location', {"lat": 12.9716, "lng": 77.5946})  # Default to Bangalore

    if not role or not name or not email or not password:
        return jsonify({"error": "Missing required fields (role, name, email, password)."}), 400

    if role not in ['patient', 'doctor', 'donor', 'admin']:
        return jsonify({"error": "Invalid role specified."}), 400

    # Check if user already exists
    existing_user = db['users'].find_one({"email": email})
    if existing_user:
        return jsonify({"error": "User with this email already exists."}), 400

    password_hash = generate_password_hash(password)
    user_doc = {
        "role": role,
        "name": name,
        "email": email,
        "password_hash": password_hash,
        "phone": phone,
        "location": location,
        "created_at": datetime.datetime.now()
    }
    
    result = db['users'].insert_one(user_doc)
    user_id = result.inserted_id

    # Create role-specific documents
    if role == 'donor':
        blood_group = data.get('blood_group', 'O+')
        donor_doc = {
            "user_id": user_id,
            "blood_group": blood_group,
            "last_donated": data.get('last_donated', ''),
            "availability_status": "available",
            "location": location
        }
        db['donors'].insert_one(donor_doc)
        
    elif role == 'doctor':
        specialization = data.get('specialization', 'General Physician')
        qualifications = data.get('qualifications', 'MBBS')
        experience = int(data.get('experience', 1))
        # Select first hospital or default to empty
        hospitals = list(db['hospitals'].find({}))
        hospital_id = hospitals[0]['_id'] if hospitals else None
        
        doctor_doc = {
            "user_id": user_id,
            "specialization": specialization,
            "qualifications": qualifications,
            "experience": experience,
            "hospital_id": hospital_id,
            "available_slots": ["09:00 AM", "10:30 AM", "02:00 PM", "04:30 PM"],
            "license_number": data.get('license_number', 'MCI-00000-PHYS'),
            "consult_fee": data.get('consult_fee', '$30'),
            "rating": 4.8,
            "reviews_count": 50,
            "bio": data.get('bio', 'Verified medical practitioner.')
        }
        db['doctors'].insert_one(doctor_doc)

    token = generate_token(user_id, role)
    
    user_data = serialize_doc(user_doc)
    user_data['id'] = str(user_id)
    user_data.pop('password_hash', None)

    return jsonify({
        "success": True,
        "message": "Registration successful",
        "token": token,
        "user": user_data
    }), 201

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({"error": "Missing email or password."}), 400

    user = db['users'].find_one({"email": email})
    if not user or not check_password_hash(user['password_hash'], password):
        return jsonify({"error": "Invalid email or password."}), 401

    token = generate_token(user['_id'], user['role'])

    user_data = serialize_doc(user)
    user_data.pop('password_hash', None)

    return jsonify({
        "success": True,
        "message": "Login successful",
        "token": token,
        "user": user_data
    })

@auth_bp.route('/google', methods=['POST'])
def google_login():
    data = request.get_json() or {}
    email = data.get('email')
    name = data.get('name', 'Google User')
    google_id = data.get('google_id', '')
    avatar = data.get('avatar', '')
    role = data.get('role', 'patient')

    if not email:
        return jsonify({"error": "Google account email is required."}), 400

    user = db['users'].find_one({"email": email})
    if not user:
        # Create new user via Google
        user_doc = {
            "role": role,
            "name": name,
            "email": email,
            "google_id": google_id,
            "avatar": avatar,
            "google_auth": True,
            "phone": data.get('phone', ''),
            "location": data.get('location', {"lat": 12.9716, "lng": 77.5946}),
            "created_at": datetime.datetime.now()
        }
        result = db['users'].insert_one(user_doc)
        user_id = result.inserted_id
        user = db['users'].find_one({"_id": user_id})
    else:
        user_id = user['_id']
        # Update user with google metadata if missing
        update_dict = {"google_auth": True}
        if avatar:
            update_dict["avatar"] = avatar
        db['users'].update_one({"_id": user_id}, {"$set": update_dict})
        user = db['users'].find_one({"_id": user_id})

    token = generate_token(user['_id'], user['role'])
    user_data = serialize_doc(user)
    user_data.pop('password_hash', None)

    return jsonify({
        "success": True,
        "message": "Google login successful",
        "token": token,
        "user": user_data
    })

