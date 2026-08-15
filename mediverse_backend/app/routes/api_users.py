from flask import Blueprint, request, jsonify, g
from bson.objectid import ObjectId
from app.utils.db import db
from app.utils.jwt_helper import token_required
from app.models.models import serialize_doc, get_doctor_details, get_donor_details

users_bp = Blueprint('api_users', __name__)

@users_bp.route('/profile', methods=['GET'])
@token_required
def get_profile():
    user = db['users'].find_one({"_id": ObjectId(g.user_id)})
    if not user:
        return jsonify({"error": "User not found"}), 404
        
    user_data = serialize_doc(user)
    user_data.pop('password_hash', None)
    
    role = g.role
    if role == 'doctor':
        doc_details = get_doctor_details(db, g.user_id)
        if doc_details:
            user_data['doctor_profile'] = doc_details
    elif role == 'donor':
        donor_details = get_donor_details(db, g.user_id)
        if donor_details:
            user_data['donor_profile'] = donor_details
            
    return jsonify(user_data)

@users_bp.route('/profile', methods=['PUT'])
@token_required
def update_profile():
    data = request.get_json() or {}
    name = data.get('name')
    phone = data.get('phone')
    location = data.get('location')
    
    update_fields = {}
    if name:
        update_fields['name'] = name
    if phone:
        update_fields['phone'] = phone
    if location:
        update_fields['location'] = {
            "lat": float(location.get('lat', 12.9716)),
            "lng": float(location.get('lng', 77.5946))
        }
        
    if not update_fields:
        return jsonify({"error": "No update fields provided."}), 400
        
    db['users'].update_one(
        {"_id": ObjectId(g.user_id)},
        {"$set": update_fields}
    )
    
    # Also update child structures (donors location or user location inside donors)
    if location:
        if g.role == 'donor':
            db['donors'].update_one(
                {"user_id": ObjectId(g.user_id)},
                {"$set": {"location": update_fields['location']}}
            )
            
    return jsonify({"success": True, "message": "Profile updated successfully."})
