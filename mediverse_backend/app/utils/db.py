import logging
import math
from bson.objectid import ObjectId
import pymongo
from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError

logger = logging.getLogger(__name__)

# Haversine distance calculation in kilometers
def calculate_distance(lat1, lon1, lat2, lon2):
    try:
        lat1, lon1, lat2, lon2 = float(lat1), float(lon1), float(lat2), float(lon2)
    except (ValueError, TypeError):
        return float('inf')
        
    R = 6371.0  # Earth's radius in km
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    
    a = (math.sin(d_lat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(d_lon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

class MockCursor:
    def __init__(self, data):
        self.data = list(data)
        
    def __iter__(self):
        return iter(self.data)
        
    def sort(self, key_or_list, direction=None):
        if isinstance(key_or_list, list):
            sort_key = key_or_list[0][0]
            reverse = key_or_list[0][1] == -1
        else:
            sort_key = key_or_list
            reverse = direction == -1
            
        try:
            self.data.sort(key=lambda x: x.get(sort_key), reverse=reverse)
        except Exception:
            pass
        return self

    def limit(self, count):
        self.data = self.data[:count]
        return self

class MockCollection:
    def __init__(self, name):
        self.name = name
        self.documents = []

    def _match(self, doc, query):
        if not query:
            return True
        for key, val in query.items():
            if key == '_id':
                if isinstance(val, dict) and '$in' in val:
                    ids = [str(i) for i in val['$in']]
                    if str(doc.get('_id')) not in ids:
                        return False
                    continue
                elif str(doc.get('_id')) != str(val):
                    return False
            elif key.startswith('$') or '.' in key:
                continue
            else:
                doc_val = doc.get(key)
                if isinstance(val, dict):
                    if '$ne' in val and doc_val == val['$ne']:
                        return False
                    if '$in' in val and doc_val not in val['$in']:
                        return False
                elif doc_val != val:
                    return False
        return True

    def find_one(self, query=None):
        query = query or {}
        for doc in self.documents:
            if self._match(doc, query):
                return doc
        return None

    def find(self, query=None):
        query = query or {}
        matches = []
        for doc in self.documents:
            if self._match(doc, query):
                matches.append(doc)
        return MockCursor(matches)

    def insert_one(self, document):
        if '_id' not in document:
            document['_id'] = ObjectId()
        self.documents.append(document)
        class InsertResult:
            def __init__(self, inserted_id):
                self.inserted_id = inserted_id
        return InsertResult(document['_id'])

    def update_one(self, query, update):
        doc = self.find_one(query)
        if doc and '$set' in update:
            for k, v in update['$set'].items():
                doc[k] = v
            class UpdateResult:
                modified_count = 1
            return UpdateResult()
        class UpdateResult:
            modified_count = 0
        return UpdateResult()

    def delete_one(self, query):
        doc = self.find_one(query)
        if doc:
            self.documents.remove(doc)
            class DeleteResult:
                deleted_count = 1
            return DeleteResult()
        class DeleteResult:
            deleted_count = 0
        return DeleteResult()

    def count_documents(self, query=None):
        query = query or {}
        count = 0
        for doc in self.documents:
            if self._match(doc, query):
                count += 1
        return count

class MockDatabase:
    def __init__(self):
        self.collections = {}

    def __getitem__(self, name):
        if name not in self.collections:
            self.collections[name] = MockCollection(name)
        return self.collections[name]

class DatabaseWrapper:
    def __init__(self):
        self.client = None
        self.db = None
        self.is_mock = False

    def connect(self, uri, db_name):
        try:
            self.client = pymongo.MongoClient(uri, serverSelectionTimeoutMS=2000)
            self.client.server_info()
            self.db = self.client[db_name]
            self.is_mock = False
            logger.info("Connected to MongoDB successfully.")
            print("Connected to MongoDB successfully.")
        except (ConnectionFailure, ServerSelectionTimeoutError, Exception) as e:
            logger.warning(f"Could not connect to MongoDB: {e}. Falling back to in-memory MockDatabase.")
            print(f"MongoDB not detected on {uri}. Falling back to in-memory MockDatabase.")
            self.db = MockDatabase()
            self.is_mock = True

    def __getitem__(self, name):
        return self.db[name]

db = DatabaseWrapper()
