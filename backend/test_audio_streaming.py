"""
Test script for audio streaming endpoint with Range requests.
"""
import requests
import os


BASE_URL = "http://localhost:8000/api"


def test_full_file_download():
    """Test downloading full file without Range header."""
    print("\n" + "=" * 60)
    print("  Test 1: Full File Download (No Range)")
    print("=" * 60)

    lesson_id = 1
    url = f"{BASE_URL}/lessons/{lesson_id}/audio"

    response = requests.get(url)
    print(f"Status: {response.status_code}")
    print(f"Content-Type: {response.headers.get('Content-Type')}")
    print(f"Content-Length: {response.headers.get('Content-Length')} bytes")
    print(f"Accept-Ranges: {response.headers.get('Accept-Ranges')}")
    print(f"Content-Range: {response.headers.get('Content-Range', 'N/A')}")
    print(f"Actual content size: {len(response.content)} bytes")

    assert response.status_code == 200, "Expected 200 OK"
    assert response.headers.get('Content-Type') == 'audio/mpeg', "Wrong content type"
    assert 'Accept-Ranges' in response.headers, "Missing Accept-Ranges header"

    print("OK: Full file download works!")


def test_range_request_partial():
    """Test Range request for partial content."""
    print("\n" + "=" * 60)
    print("  Test 2: Range Request (Partial Content)")
    print("=" * 60)

    lesson_id = 1
    url = f"{BASE_URL}/lessons/{lesson_id}/audio"

    # Request first 10KB
    headers = {"Range": "bytes=0-10239"}
    response = requests.get(url, headers=headers)

    print(f"Status: {response.status_code}")
    print(f"Content-Type: {response.headers.get('Content-Type')}")
    print(f"Content-Length: {response.headers.get('Content-Length')} bytes")
    print(f"Content-Range: {response.headers.get('Content-Range')}")
    print(f"Actual content size: {len(response.content)} bytes")

    assert response.status_code == 206, "Expected 206 Partial Content"
    assert response.headers.get('Content-Type') == 'audio/mpeg', "Wrong content type"
    assert 'Content-Range' in response.headers, "Missing Content-Range header"
    assert len(response.content) == 10240, f"Expected 10240 bytes, got {len(response.content)}"

    print("OK: Range request works!")


def test_range_request_middle():
    """Test Range request for middle chunk."""
    print("\n" + "=" * 60)
    print("  Test 3: Range Request (Middle Chunk)")
    print("=" * 60)

    lesson_id = 2
    url = f"{BASE_URL}/lessons/{lesson_id}/audio"

    # Request bytes 50000-60000
    headers = {"Range": "bytes=50000-60000"}
    response = requests.get(url, headers=headers)

    print(f"Status: {response.status_code}")
    print(f"Content-Range: {response.headers.get('Content-Range')}")
    print(f"Content-Length: {response.headers.get('Content-Length')} bytes")
    print(f"Actual content size: {len(response.content)} bytes")

    assert response.status_code == 206, "Expected 206 Partial Content"
    assert len(response.content) == 10001, f"Expected 10001 bytes, got {len(response.content)}"

    print("OK: Middle chunk range request works!")


def test_range_request_from_offset():
    """Test Range request from offset to end."""
    print("\n" + "=" * 60)
    print("  Test 4: Range Request (From Offset to End)")
    print("=" * 60)

    lesson_id = 3
    url = f"{BASE_URL}/lessons/{lesson_id}/audio"

    # Get full file size first
    response_full = requests.get(url)
    full_size = int(response_full.headers.get('Content-Length'))

    # Request from byte 100000 to end
    headers = {"Range": "bytes=100000-"}
    response = requests.get(url, headers=headers)

    print(f"Status: {response.status_code}")
    print(f"Content-Range: {response.headers.get('Content-Range')}")
    print(f"Full file size: {full_size} bytes")
    print(f"Requested from: 100000 to end")
    print(f"Content-Length: {response.headers.get('Content-Length')} bytes")
    print(f"Actual content size: {len(response.content)} bytes")

    expected_size = full_size - 100000
    assert response.status_code == 206, "Expected 206 Partial Content"
    assert len(response.content) == expected_size, f"Expected {expected_size} bytes"

    print("OK: From-offset range request works!")


def test_invalid_lesson():
    """Test request for non-existent lesson."""
    print("\n" + "=" * 60)
    print("  Test 5: Non-existent Lesson")
    print("=" * 60)

    lesson_id = 999
    url = f"{BASE_URL}/lessons/{lesson_id}/audio"

    response = requests.get(url)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")

    assert response.status_code == 404, "Expected 404 Not Found"

    print("OK: Handles non-existent lesson correctly!")


def test_lesson_without_audio():
    """Test request for lesson without audio file."""
    print("\n" + "=" * 60)
    print("  Test 6: Lesson Without Audio File")
    print("=" * 60)

    # Create a lesson in DB but don't create audio file
    # For now, just test with a lesson ID that has no file
    lesson_id = 50  # Assuming this lesson might exist but has no audio

    url = f"{BASE_URL}/lessons/{lesson_id}/audio"
    response = requests.get(url)

    print(f"Status: {response.status_code}")
    if response.status_code != 200:
        print(f"Response: {response.json()}")

    # Should be 404 (either lesson not found or audio not found)
    assert response.status_code == 404, "Expected 404 Not Found"

    print("OK: Handles missing audio file correctly!")


def test_multiple_ranges_simulation():
    """Simulate mobile player seeking (multiple range requests)."""
    print("\n" + "=" * 60)
    print("  Test 7: Simulate Mobile Player Seeking")
    print("=" * 60)

    lesson_id = 4
    url = f"{BASE_URL}/lessons/{lesson_id}/audio"

    # Simulate seeking: request different chunks
    ranges = [
        "bytes=0-32767",      # Initial buffering (32KB)
        "bytes=32768-65535",  # Next chunk
        "bytes=100000-132767" # User seeks forward
    ]

    for i, range_header in enumerate(ranges, 1):
        headers = {"Range": range_header}
        response = requests.get(url, headers=headers)

        print(f"\nSeek {i}: {range_header}")
        print(f"  Status: {response.status_code}")
        print(f"  Content-Range: {response.headers.get('Content-Range')}")
        print(f"  Received: {len(response.content)} bytes")

        assert response.status_code == 206, f"Seek {i} failed"

    print("\nOK: Multiple seek operations work!")


def main():
    """Run all tests."""
    print("=" * 60)
    print("  Audio Streaming API - Range Request Tests")
    print("=" * 60)

    try:
        test_full_file_download()
        test_range_request_partial()
        test_range_request_middle()
        test_range_request_from_offset()
        test_invalid_lesson()
        test_lesson_without_audio()
        test_multiple_ranges_simulation()

        print("\n" + "=" * 60)
        print("  All tests passed!")
        print("=" * 60)

    except AssertionError as e:
        print(f"\nFAILED: Test failed: {e}")
        import traceback
        traceback.print_exc()
    except Exception as e:
        print(f"\nERROR: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
