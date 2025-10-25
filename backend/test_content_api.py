"""
Test script for content API endpoints.
Run: python test_content_api.py
"""
import requests
import json

BASE_URL = "http://localhost:8000/api"


def print_json(data):
    """Pretty print JSON."""
    print(json.dumps(data, indent=2, ensure_ascii=False))


def test_themes():
    """Test themes endpoints."""
    print("\n" + "=" * 60)
    print("  Testing Themes")
    print("=" * 60)

    # Get all themes
    print("\n1. GET /themes")
    response = requests.get(f"{BASE_URL}/themes")
    print(f"Status: {response.status_code}")
    themes = response.json()
    print_json(themes)

    if themes:
        theme_id = themes[0]["id"]

        # Get specific theme
        print(f"\n2. GET /themes/{theme_id}")
        response = requests.get(f"{BASE_URL}/themes/{theme_id}")
        print(f"Status: {response.status_code}")
        print_json(response.json())


def test_teachers():
    """Test teachers endpoints."""
    print("\n" + "=" * 60)
    print("  Testing Teachers")
    print("=" * 60)

    # Get all teachers
    print("\n1. GET /teachers")
    response = requests.get(f"{BASE_URL}/teachers")
    print(f"Status: {response.status_code}")
    teachers = response.json()
    print_json(teachers)

    if teachers:
        teacher_id = teachers[0]["id"]

        # Get specific teacher
        print(f"\n2. GET /teachers/{teacher_id}")
        response = requests.get(f"{BASE_URL}/teachers/{teacher_id}")
        print(f"Status: {response.status_code}")
        print_json(response.json())

        # Get teacher series
        print(f"\n3. GET /teachers/{teacher_id}/series")
        response = requests.get(f"{BASE_URL}/teachers/{teacher_id}/series")
        print(f"Status: {response.status_code}")
        series_list = response.json()
        print_json(series_list)

        return series_list if series_list else None


def test_series(series_list):
    """Test series endpoints."""
    if not series_list:
        print("\nSkipping series tests - no series found")
        return None

    print("\n" + "=" * 60)
    print("  Testing Series")
    print("=" * 60)

    series_id = series_list[0]["id"]

    # Get specific series
    print(f"\n1. GET /series/{series_id}")
    response = requests.get(f"{BASE_URL}/series/{series_id}")
    print(f"Status: {response.status_code}")
    print_json(response.json())

    # Get series lessons
    print(f"\n2. GET /series/{series_id}/lessons")
    response = requests.get(f"{BASE_URL}/series/{series_id}/lessons")
    print(f"Status: {response.status_code}")
    lessons = response.json()
    print_json(lessons)

    return lessons if lessons else None


def test_lessons(lessons):
    """Test lessons endpoints."""
    if not lessons:
        print("\nSkipping lessons tests - no lessons found")
        return

    print("\n" + "=" * 60)
    print("  Testing Lessons")
    print("=" * 60)

    lesson_id = lessons[0]["id"]

    # Get specific lesson
    print(f"\n1. GET /lessons/{lesson_id}")
    response = requests.get(f"{BASE_URL}/lessons/{lesson_id}")
    print(f"Status: {response.status_code}")
    print_json(response.json())


def main():
    print("=" * 60)
    print("  Islamic Audio Lessons API - Content Test")
    print("=" * 60)

    try:
        # Test themes
        test_themes()

        # Test teachers and get series
        series_list = test_teachers()

        # Test series and get lessons
        lessons = test_series(series_list)

        # Test lessons
        test_lessons(lessons)

        print("\n" + "=" * 60)
        print("  All tests completed!")
        print("=" * 60)

    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
