import datetime
from flask import Blueprint, request, jsonify, g
from bson.objectid import ObjectId
from app.utils.db import db, calculate_distance
from app.utils.jwt_helper import token_required
from app.models.models import serialize_doc

blood_requests_bp = Blueprint('api_blood_requests', __name__)

@blood_requests_bp.route('', methods=['POST'])
@token_required
def create_request():
    data = request.get_json() or {}
    blood_group = data.get('blood_group')
    urgency = data.get('urgency', 'moderate')
    location = data.get('location')

    if not blood_group:
        return jsonify({"error": "Missing required fields (blood_group)."}), 400

    # Auto-detect location if not submitted
    if not location:
        user = db['users'].find_one({"_id": ObjectId(g.user_id)})
        location = user.get('location', {"lat": 12.9716, "lng": 77.5946})

    request_doc = {
        "requester_id": ObjectId(g.user_id),
        "blood_group": blood_group,
        "urgency": urgency,
        "location": {
            "lat": float(location.get('lat', 12.9716)),
            "lng": float(location.get('lng', 77.5946))
        },
        "status": "open",
        "created_at": datetime.datetime.now()
    }

    result = db['blood_requests'].insert_one(request_doc)
    request_id = result.inserted_id

    # Scan and alert nearby donors (within 15km)
    matching_donors = list(db['donors'].find({
        "blood_group": blood_group,
        "availability_status": "available"
    }))
    
    for donor in matching_donors:
        donor_user = db['users'].find_one({"_id": ObjectId(donor['user_id'])})
        if donor_user:
            dist = calculate_distance(
                location['lat'], location['lng'],
                donor_user['location']['lat'], donor_user['location']['lng']
            )
            if dist <= 15.0:
                notification = {
                    "user_id": donor_user['_id'],
                    "title": f"URGENT: Blood SOS ({blood_group})",
                    "message": f"Emergency blood needed nearby. Dist: {round(dist, 1)}km. Help immediately.",
                    "request_id": str(request_id),
                    "read": False,
                    "created_at": datetime.datetime.now()
                }
                db['notifications'].insert_one(notification)

    request_doc['id'] = str(request_id)
    return jsonify({
        "success": True,
        "message": "SOS Blood request broadcasted.",
        "request": serialize_doc(request_doc)
    }), 201

@blood_requests_bp.route('', methods=['GET'])
def list_requests():
    requests = list(db['blood_requests'].find({}).sort("created_at", -1))
    detailed_requests = []
    
    for req in requests:
        details = serialize_doc(req)
        requester = db['users'].find_one({"_id": req['requester_id']})
        if requester:
            details['requester_name'] = requester['name']
            details['requester_phone'] = requester.get('phone', '')
            
        detailed_requests.append(details)
        
    return jsonify(detailed_requests)

@blood_requests_bp.route('/<id>/status', methods=['POST'])
@token_required
def update_status(id):
    data = request.get_json() or {}
    status = data.get('status') # fulfilled, cancelled

    if status not in ['fulfilled', 'cancelled']:
        return jsonify({"error": "Invalid status."}), 400

    db['blood_requests'].update_one(
        {"_id": ObjectId(id)},
        {"$set": {"status": status}}
    )

    return jsonify({"success": True, "message": f"Request status marked as {status}."})
