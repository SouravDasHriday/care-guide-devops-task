import os
from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/", methods=["GET"])
def index():
    """
    Root endpoint for DevOps Intern Task.
    Returns JSON response indicating service is running.
    """
    return jsonify({
        "message": "Hello from DevOps Intern Task!",
        "status": "running"
    }), 200


@app.route("/health", methods=["GET"])
def health():
    """
    Health check endpoint for Docker and monitoring tools.
    """
    return jsonify({
        "status": "healthy"
    }), 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
