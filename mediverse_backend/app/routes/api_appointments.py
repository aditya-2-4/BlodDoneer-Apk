import datetime
from flask import Blueprint, request, jsonify, g
from bson.objectid import ObjectId
from app.utils.db import db
from app.utils.jwt_helper import token_required, role_required
from app.models.models import serialize_doc, get_doctor_details

appointments_bp = Blueprint('api_appointments', __name__)

@appointments_bp.route('', methods=['POST'])
@token_required
@role_required('patient')
def book_appointment():
    data = request.get_json() or {}
    doctor_id = data.get('doctor_id')
    date = data.get('date')
    time = data.get('time')
    reason = data.get('reason', 'Routine checkup')

    if not doctor_id or not date or not time:
        return jsonify({"error": "Missing required fields (doctor_id, date, time)."}), 400

    appointment_doc = {
        "patient_id": ObjectId(g.user_id),
        "doctor_id": ObjectId(doctor_id),
        "date": date,
        "time": time,
        "status": "pending",
        "reason": reason,
        "created_at": datetime.datetime.now()
    }
    
    result = db['appointments'].insert_one(appointment_doc)

    # In-app notifications setup
    notification = {
        "user_id": ObjectId(doctor_id),
        "title": "New Appointment Booking",
        "message": f"New appointment requested on {date} at {time}.",
        "read": False,
        "created_at": datetime.datetime.now()
    }
    db['notifications'].insert_one(notification)

    appointment_doc['id'] = str(result.inserted_id)
    return jsonify({
        "success": True,
        "message": "Appointment booked successfully.",
        "appointment": serialize_doc(appointment_doc)
    }), 201

@appointments_bp.route('', methods=['GET'])
@token_required
def get_appointments():
    role = g.role
    uid = ObjectId(g.user_id)
    
    if role == 'patient':
        appts = list(db['appointments'].find({"patient_id": uid}).sort("date", -1))
    elif role == 'doctor':
        appts = list(db['appointments'].find({"doctor_id": uid}).sort("date", -1))
    else:
        appts = list(db['appointments'].find({}).sort("date", -1)) # Admin backup

    detailed_appts = []
    for appt in appts:
        details = serialize_doc(appt)
        
        # Pull patient data
        patient = db['users'].find_one({"_id": appt['patient_id']})
        if patient:
            details['patient_name'] = patient['name']
            details['patient_phone'] = patient.get('phone', '')
            details['patient_email'] = patient['email']
            
        # Pull doctor data
        doc = get_doctor_details(db, appt['doctor_id'])
        if doc:
            details['doctor_name'] = doc['name']
            details['specialization'] = doc['specialization']
            details['hospital_name'] = doc['hospital_name']
            
        detailed_appts.append(details)
        
    return jsonify(detailed_appts)

@appointments_bp.route('/<id>/status', methods=['POST'])
@token_required
def update_appointment_status(id):
    data = request.get_json() or {}
    status = data.get('status') # confirmed, cancelled

    if status not in ['confirmed', 'cancelled']:
        return jsonify({"error": "Invalid status. Must be 'confirmed' or 'cancelled'."}), 400

    appt = db['appointments'].find_one({"_id": ObjectId(id)})
    if not appt:
        return jsonify({"error": "Appointment not found."}), 404

    # Doctor or Admin authorization check
    if g.role == 'doctor' and str(appt['doctor_id']) != g.user_id:
        return jsonify({"error": "Unauthorized action."}), 403

    db['appointments'].update_one(
        {"_id": ObjectId(id)},
        {"$set": {"status": status}}
    )

    # Notify patient
    notification = {
        "user_id": appt['patient_id'],
        "title": f"Appointment {status.capitalize()}",
        "message": f"Your visit on {appt['date']} at {appt['time']} was {status}.",
        "read": False,
        "created_at": datetime.datetime.now()
    }
    db['notifications'].insert_one(notification)

    return jsonify({"success": True, "message": f"Appointment successfully {status}."})
