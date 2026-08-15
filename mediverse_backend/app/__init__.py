from flask import Flask, jsonify, request, render_template
from config import Config
from app.utils.db import db
from app.utils.seed import seed_database

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Initialize and connect database
    db.connect(app.config['MONGO_URI'], app.config['DB_NAME'])

    # Auto-seed database
    seed_database(db)

    # Register API Blueprints
    from app.routes.api_auth import auth_bp
    from app.routes.api_users import users_bp
    from app.routes.api_donors import donors_bp
    from app.routes.api_doctors import doctors_bp
    from app.routes.api_appointments import appointments_bp
    from app.routes.api_blood_requests import blood_requests_bp
    from app.routes.api_hospitals import hospitals_bp

    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(users_bp, url_prefix='/api/users')
    app.register_blueprint(donors_bp, url_prefix='/api/donors')
    app.register_blueprint(doctors_bp, url_prefix='/api/doctors')
    app.register_blueprint(appointments_bp, url_prefix='/api/appointments')
    app.register_blueprint(blood_requests_bp, url_prefix='/api/blood-requests')
    app.register_blueprint(hospitals_bp, url_prefix='/api/hospitals')

    # CORS Headers Handler (enables cross-origin mobile API calls)
    @app.after_request
    def after_request(response):
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
        response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
        return response

    @app.route('/', methods=['GET'])
    def index():
        return render_template('index.html')

    @app.route('/api', methods=['GET'])
    @app.route('/api/', methods=['GET'])
    def api_index():
        return jsonify({
            "status": "online",
            "name": "MediVerse REST API Platform",
            "version": "1.0.0",
            "database": "mock" if db.is_mock else "mongodb",
            "endpoints": {
                "doctors": "/api/doctors",
                "donors": "/api/donors",
                "hospitals": "/api/hospitals",
                "auth_google": "/api/auth/google",
                "auth_login": "/api/auth/login",
                "appointments": "/api/appointments",
                "blood_requests": "/api/blood-requests"
            }
        }), 200

    @app.route('/api/health', methods=['GET'])
    def health_check():
        return jsonify({
            "status": "healthy",
            "database": "mock" if db.is_mock else "mongodb",
            "message": "MediVerse REST API is active."
        })


    # Global Error Handling
    @app.errorhandler(404)
    def page_not_found(e):
        return jsonify({"error": "Resource not found."}), 404

    @app.errorhandler(500)
    def internal_server_error(e):
        return jsonify({"error": "Internal server error."}), 500

    return app
