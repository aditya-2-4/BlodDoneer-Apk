from flask import Blueprint, request, jsonify, g
from bson.objectid import ObjectId
from app.utils.db import db, calculate_distance
from app.utils.jwt_helper import token_required, role_required
from app.models.models import serialize_doc, get_donor_details

donors_bp = Blueprint('api_donors', __name__)

@donors_bp.route('', methods=['GET'])
def get_donors():
    bg = request.args.get('blood_group')
    lat = request.args.get('lat')
    lng = request.args.get('lng')
    radius = request.args.get('radius', 10.0) # Default 10km

    query = {"availability_status": "available"}
    if bg and bg != 'All':
        query['blood_group'] = bg

    donors_profile = list(db['donors'].find(query))
    matching_donors = []

    for donor in donors_profile:
        details = get_donor_details(db, donor['user_id'])
        if not details:
            continue
            
        user = db['users'].find_one({"_id": ObjectId(donor['user_id'])})
        if not user or 'location' not in user:
            continue
            
        details['location'] = user['location']
        
        if lat and lng:
            dist = calculate_distance(lat, lng, user['location']['lat'], user['location']['lng'])
            if dist > float(radius):
                continue
            details['distance'] = round(dist, 2)
        else:
            details['distance'] = None
            
        matching_donors.append(details)

    if lat and lng:
        matching_donors.sort(key=lambda x: x.get('distance', float('inf')))

    return jsonify(matching_donors)

@donors_bp.route('/profile', methods=['POST'])
@token_required
@role_required('donor')
def update_donor_profile():
    data = request.get_json() or {}
    blood_group = data.get('blood_group')
    last_donated = data.get('last_donated', '')
    availability_status = data.get('availability_status', 'available')
    lat = data.get('lat')
    lng = data.get('lng')

    update_fields = {}
    if blood_group:
        update_fields['blood_group'] = blood_group
    if last_donated is not None:
        update_fields['last_donated'] = last_donated
    if availability_status:
        update_fields['availability_status'] = availability_status
    if lat and lng:
        update_fields['location'] = {"lat": float(lat), "lng": float(lng)}

    # Update donor details
    db['donors'].update_one(
        {"user_id": ObjectId(g.user_id)},
        {"$set": update_fields}
    )

    # Sync coordinates in user profile
    if lat and lng:
        db['users'].update_one(
            {"_id": ObjectId(g.user_id)},
            {"$set": {"location": {"lat": float(lat), "lng": float(lng)}}}
        )

    return jsonify({"success": True, "message": "Donor profile updated successfully."})

@donors_bp.route('/requests', methods=['GET'])
@token_required
@role_required('donor')
def get_donor_requests():
    donor = db['donors'].find_one({"user_id": ObjectId(g.user_id)})
    if not donor:
        return jsonify({"error": "Donor profile not found"}), 404
        
    blood_group = donor['blood_group']
    
    # Get user location
    user = db['users'].find_one({"_id": ObjectId(g.user_id)})
    donor_location = user.get('location', {"lat": 12.9716, "lng": 77.5946})

    # Fetch matching open requests
    requests = list(db['blood_requests'].find({"blood_group": blood_group, "status": "open"}).sort("created_at", -1))
    
    matching_requests = []
    for req in requests:
        req_details = serialize_doc(req)
        
        req_loc = req.get('location', donor_location)
        dist = calculate_distance(donor_location['lat'], donor_location['lng'], req_loc['lat'], req_loc['lng'])
        req_details['distance'] = round(dist, 2)
        
        # Pull requester details
        patient = db['users'].find_one({"_id": req['requester_id']})
        if patient:
            req_details['requester_name'] = patient['name']
            req_details['requester_phone'] = patient.get('phone', '')
            
        matching_requests.append(req_details)

    return jsonify(matching_requests)
