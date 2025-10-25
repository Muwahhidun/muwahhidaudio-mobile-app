"""
Quick test script for API endpoints.
Run: python test_api.py
"""
import requests
import json

BASE_URL = "http://localhost:8000/api"


def test_register():
    """Test user registration."""
    print("\n1. Testing registration...")
    response = requests.post(
        f"{BASE_URL}/auth/register",
        json={
            "email": "newuser@example.com",
            "password": "password123",
            "first_name": "New",
            "last_name": "User"
        }
    )
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    return response.json()


def test_login():
    """Test user login."""
    print("\n2. Testing login with test@example.com...")
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={
            "email": "test@example.com",
            "password": "password123"
        }
    )
    print(f"Status: {response.status_code}")
    data = response.json()
    print(f"Response: {json.dumps(data, indent=2)}")
    return data.get("access_token")


def test_get_me(token):
    """Test getting current user profile."""
    print("\n3. Testing /me endpoint...")
    response = requests.get(
        f"{BASE_URL}/auth/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")


def main():
    print("=" * 60)
    print("  Islamic Audio Lessons API - Test Script")
    print("=" * 60)

    try:
        # Test 1: Register (may fail if user exists)
        try:
            test_register()
        except Exception as e:
            print(f"Registration skipped (user may exist): {e}")

        # Test 2: Login
        token = test_login()

        # Test 3: Get profile
        if token:
            test_get_me(token)

        print("\n" + "=" * 60)
        print("  ✅ All tests completed!")
        print("=" * 60)

    except Exception as e:
        print(f"\n❌ Error: {e}")


if __name__ == "__main__":
    main()
