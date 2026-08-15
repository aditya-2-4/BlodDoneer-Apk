from bson.objectid import ObjectId

def serialize_doc(doc):
    if not doc:
        return None
    new_doc = doc.copy()
    if '_id' in new_doc:
        new_doc['id'] = str(new_doc.pop('_id'))
    
    for k, v in list(new_doc.items()):
        if isinstance(v, ObjectId):
            new_doc[k] = str(v)
        elif hasattr(v, 'isoformat'):
            new_doc[k] = v.isoformat()
        elif isinstance(v, dict):
            new_doc[k] = serialize_doc(v)
        elif isinstance(v, list):
            new_doc[k] = [serialize_doc(i) if isinstance(i, dict) else (str(i) if isinstance(i, ObjectId) else i) for i in v]
    return new_doc

def get_user_by_id(db, user_id):
    try:
        oid = ObjectId(user_id) if isinstance(user_id, str) else user_id
        return db['users'].find_one({"_id": oid})
    except Exception:
        return None

def get_doctor_details(db, doc_user_id):
    try:
        oid = ObjectId(doc_user_id) if isinstance(doc_user_id, str) else doc_user_id
        doc_profile = db['doctors'].find_one({"user_id": oid})
        if not doc_profile:
            return None
        
        user = db['users'].find_one({"_id": oid})
        hospital = None
        if doc_profile.get("hospital_id"):
            hospital = db['hospitals'].find_one({"_id": ObjectId(doc_profile["hospital_id"])})
            
        details = serialize_doc(doc_profile)
        if user:
            details['name'] = user['name']
            details['email'] = user['email']
            details['phone'] = user.get('phone', '')
            details['location'] = user.get('location', {"lat": 0.0, "lng": 0.0})
        if hospital:
            details['hospital_name'] = hospital['name']
            details['hospital_location'] = hospital.get('location')
        return details
    except Exception as e:
        print(f"Error getting doctor details: {e}")
        return None

def get_donor_details(db, donor_user_id):
    try:
        oid = ObjectId(donor_user_id) if isinstance(donor_user_id, str) else donor_user_id
        donor_profile = db['donors'].find_one({"user_id": oid})
        if not donor_profile:
            return None
            
        user = db['users'].find_one({"_id": oid})
        details = serialize_doc(donor_profile)
        if user:
            details['name'] = user['name']
            details['email'] = user['email']
            details['phone'] = user.get('phone', '')
        return details
    except Exception:
        return None
