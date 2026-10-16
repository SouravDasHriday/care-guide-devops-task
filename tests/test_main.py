import pytest
from app.main import app


@pytest.fixture
def client():
    """Create a test client for the Flask app."""
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_root_endpoint_status_code(client):
    """Test that the root endpoint returns HTTP 200."""
    response = client.get("/")
    assert response.status_code == 200


def test_root_endpoint_json_payload(client):
    """Test that the root endpoint returns expected JSON payload."""
    response = client.get("/")
    data = response.get_json()
    assert data is not None
    assert data.get("message") == "Hello from DevOps Intern Task!"
    assert data.get("status") == "running"


def test_health_endpoint(client):
    """Test that the health endpoint returns healthy status."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.get_json()
    assert data.get("status") == "healthy"
