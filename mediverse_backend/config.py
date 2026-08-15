import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'mediverse_secret_key_98234710293')
    JWT_SECRET = os.environ.get('JWT_SECRET', 'mediverse_jwt_token_secret_1092837198')
    MONGO_URI = os.environ.get('MONGO_URI', 'mongodb://localhost:27017/')
    DB_NAME = os.environ.get('DB_NAME', 'mediverse_mobile')
    DEBUG = True
