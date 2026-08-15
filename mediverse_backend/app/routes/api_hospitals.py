from flask import Blueprint, request, jsonify
from bson.objectid import ObjectId
from app.utils.db import db, calculate_distance
from app.utils.jwt_helper import token_required, role_required
from app.models.models import serialize_doc

hospitals_bp = Blueprint('api_hospitals', __name__)

@hospitals_bp.route('', methods=['GET'])
def get_hospitals():
    lat = request.args.get('lat')
    lng = request.args.get('lng')
    radius = request.args.get('radius', 15.0) # default 15km radius

    hospitals = list(db['hospitals'].find({}))
    matching_hospitals = []

    for hosp in hospitals:
        details = serialize_doc(hosp)
        if lat and lng and 'location' in details:
            dist = calculate_distance(lat, lng, details['location']['lat'], details['location']['lng'])
            if dist > float(radius):
                continue
            details['distance'] = round(dist, 2)
        else:
            details['distance'] = None
            
        matching_hospitals.append(details)

    if lat and lng:
        matching_hospitals.sort(key=lambda x: x.get('distance', float('inf')))

    return jsonify(matching_hospitals)

@hospitals_bp.route('', methods=['POST'])
@token_required
@role_required('admin')
def create_hospital():
    data = request.get_json() or {}
    name = data.get('name')
    contact = data.get('contact')
    location = data.get('location')

    if not name or not contact or not location:
        return jsonify({"error": "Missing required fields."}), 400

    hospital_doc = {
        "name": name,
        "contact": contact,
        "location": {
            "lat": float(location.get('lat')),
            "lng": float(location.get('lng'))
        },
        "doctor_ids": []
    }

    result = db['hospitals'].insert_one(hospital_doc)
    hospital_doc['id'] = str(result.inserted_id)

    return jsonify({"success": True, "hospital": serialize_doc(hospital_doc)}), 201
