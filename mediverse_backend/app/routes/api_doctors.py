from flask import Blueprint, request, jsonify, g
from bson.objectid import ObjectId
from app.utils.db import db, calculate_distance
from app.utils.jwt_helper import token_required, role_required
from app.models.models import serialize_doc, get_doctor_details

doctors_bp = Blueprint('api_doctors', __name__)

@doctors_bp.route('', methods=['GET'])
def get_doctors():
    spec = request.args.get('specialization')
    lat = request.args.get('lat')
    lng = request.args.get('lng')
    radius = request.args.get('radius') # in km

    query = {}
    if spec and spec != 'All':
        query['specialization'] = spec

    docs_profile = list(db['doctors'].find(query))
    matching_doctors = []

    for doc in docs_profile:
        details = get_doctor_details(db, doc['user_id'])
        if not details:
            continue
            
        # Geolocation distance filters
        if lat and lng and radius:
            try:
                doc_lat = details['location']['lat']
                doc_lng = details['location']['lng']
                dist = calculate_distance(lat, lng, doc_lat, doc_lng)
                if dist > float(radius):
                    continue
                details['distance'] = round(dist, 2)
            except Exception:
                details['distance'] = None
        else:
            details['distance'] = None
            
        matching_doctors.append(details)

    if lat and lng and radius:
        matching_doctors.sort(key=lambda x: x.get('distance', float('inf')))

    return jsonify(matching_doctors)

@doctors_bp.route('/<doc_id>', methods=['GET'])
def get_doctor_by_id(doc_id):
    try:
        doc = db['doctors'].find_one({"_id": ObjectId(doc_id)})
        if not doc:
            # Try searching by user_id
            doc = db['doctors'].find_one({"user_id": ObjectId(doc_id)})
        if not doc:
            return jsonify({"error": "Doctor not found"}), 404
        
        details = get_doctor_details(db, doc['user_id'])
        return jsonify(details)
    except Exception as e:
        return jsonify({"error": "Invalid doctor ID format"}), 400


@doctors_bp.route('/schedule', methods=['POST'])
@token_required
@role_required('doctor')
def save_schedule():
    data = request.get_json() or {}
    slots = data.get('available_slots') # Array of time slot strings

    if slots is None:
        return jsonify({"error": "Missing available_slots field."}), 400

    db['doctors'].update_one(
        {"user_id": ObjectId(g.user_id)},
        {"$set": {"available_slots": slots}}
    )

    return jsonify({"success": True, "message": "Doctor slots updated successfully."})
