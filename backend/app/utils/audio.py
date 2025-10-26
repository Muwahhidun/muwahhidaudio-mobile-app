"""
Audio streaming utilities with Range request support.
"""
import os
from typing import Optional, Tuple
from pathlib import Path


def get_audio_file_path(audio_path: Optional[str] = None, lesson_id: Optional[int] = None, audio_dir: str = "audio_files") -> Optional[Path]:
    """
    Get the file path for a lesson's audio file.

    Args:
        audio_path: Audio path from lesson record (preferred)
        lesson_id: Lesson ID (fallback if audio_path not provided)
        audio_dir: Base directory containing audio files

    Returns:
        Path to audio file if it exists, None otherwise
    """
    # If audio_path is provided, use it (it's relative to audio_dir)
    if audio_path:
        # Check if path is already absolute or relative to audio_dir
        if audio_path.startswith('audio_files/'):
            file_path = Path(audio_path)
        else:
            file_path = Path(audio_dir) / audio_path

        if file_path.exists():
            return file_path

    # Fallback: try lesson_{id}.mp3 format
    if lesson_id:
        filename = f"lesson_{lesson_id}.mp3"
        file_path = Path(audio_dir) / filename

        if file_path.exists():
            return file_path

    return None


def parse_range_header(range_header: str, file_size: int) -> Optional[Tuple[int, int]]:
    """
    Parse HTTP Range header.

    Args:
        range_header: Range header value (e.g., "bytes=0-1023")
        file_size: Total file size in bytes

    Returns:
        Tuple of (start_byte, end_byte) or None if invalid
    """
    try:
        # Format: "bytes=start-end"
        if not range_header.startswith("bytes="):
            return None

        range_spec = range_header[6:]  # Remove "bytes="

        # Handle different range formats
        if "-" not in range_spec:
            return None

        parts = range_spec.split("-", 1)

        # Case 1: "bytes=start-end"
        if parts[0] and parts[1]:
            start = int(parts[0])
            end = int(parts[1])

        # Case 2: "bytes=start-" (from start to end of file)
        elif parts[0] and not parts[1]:
            start = int(parts[0])
            end = file_size - 1

        # Case 3: "bytes=-end" (last N bytes)
        elif not parts[0] and parts[1]:
            start = file_size - int(parts[1])
            end = file_size - 1

        else:
            return None

        # Validate range
        if start < 0 or start >= file_size:
            return None

        if end < start or end >= file_size:
            end = file_size - 1

        return (start, end)

    except (ValueError, IndexError):
        return None


def get_content_range_header(start: int, end: int, total: int) -> str:
    """
    Generate Content-Range header value.

    Args:
        start: Start byte position
        end: End byte position
        total: Total file size

    Returns:
        Content-Range header value
    """
    return f"bytes {start}-{end}/{total}"


def get_chunk_size() -> int:
    """
    Get the chunk size for streaming audio.

    Returns:
        Chunk size in bytes (default: 64KB)
    """
    return 64 * 1024  # 64 KB chunks
