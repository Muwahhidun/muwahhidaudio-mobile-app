"""Audio processing utilities for converting and normalizing audio files."""

import os
import subprocess
from pathlib import Path
from typing import Tuple
import logging

logger = logging.getLogger(__name__)

# Audio processing settings
TARGET_FORMAT = "mp3"
TARGET_BITRATE = "64k"
TARGET_CHANNELS = 1  # Mono
AUDIO_CODEC = "libmp3lame"

# Directory paths
AUDIO_BASE_DIR = Path("/app/audio_files")
ORIGINAL_DIR = AUDIO_BASE_DIR / "original"
PROCESSED_DIR = AUDIO_BASE_DIR / "processed"


def ensure_directories():
    """Ensure audio directories exist."""
    ORIGINAL_DIR.mkdir(parents=True, exist_ok=True)
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)


def get_audio_duration(file_path: str) -> int:
    """
    Get duration of audio file in seconds using ffprobe.

    Args:
        file_path: Path to the audio file

    Returns:
        Duration in seconds (rounded to nearest integer)
    """
    try:
        cmd = [
            "ffprobe",
            "-v", "error",
            "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1",
            file_path
        ]

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True
        )

        duration = float(result.stdout.strip())
        return int(round(duration))

    except subprocess.CalledProcessError as e:
        logger.error(f"Error getting duration for {file_path}: {e}")
        raise Exception(f"Failed to get audio duration: {e}")
    except ValueError as e:
        logger.error(f"Invalid duration value for {file_path}: {e}")
        raise Exception(f"Invalid audio duration: {e}")


def convert_to_mp3_mono(
    input_path: str,
    output_path: str,
    normalize: bool = True
) -> None:
    """
    Convert audio file to MP3 mono format at 64 kbps.

    Args:
        input_path: Path to input audio file
        output_path: Path to output MP3 file
        normalize: Whether to normalize audio volume (default: True)

    Raises:
        Exception: If conversion fails
    """
    try:
        # Base ffmpeg command
        cmd = [
            "ffmpeg",
            "-i", input_path,
            "-vn",  # Disable video
            "-ac", str(TARGET_CHANNELS),  # Mono
            "-b:a", TARGET_BITRATE,  # Bitrate 64k
            "-codec:a", AUDIO_CODEC,  # MP3 codec
        ]

        # Add normalization filter if requested
        if normalize:
            # loudnorm filter normalizes audio to -23 LUFS (standard for speech)
            cmd.extend([
                "-af", "loudnorm=I=-23:TP=-2:LRA=7"
            ])

        # Output file
        cmd.extend([
            "-y",  # Overwrite output file if exists
            output_path
        ])

        # Run ffmpeg
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True
        )

        logger.info(f"Successfully converted {input_path} to {output_path}")

    except subprocess.CalledProcessError as e:
        logger.error(f"FFmpeg conversion failed: {e.stderr}")
        raise Exception(f"Audio conversion failed: {e.stderr}")


def process_audio_file(
    input_file_path: str,
    original_filename: str
) -> Tuple[str, str, int]:
    """
    Process uploaded audio file: save original, convert to MP3 mono, get duration.

    Args:
        input_file_path: Path to the uploaded temporary file
        original_filename: Original name of the uploaded file

    Returns:
        Tuple of (original_path, processed_path, duration_seconds)
        - original_path: Relative path to original file (e.g., "original/file.wav")
        - processed_path: Relative path to processed file (e.g., "processed/file.mp3")
        - duration_seconds: Duration in seconds

    Raises:
        Exception: If processing fails
    """
    try:
        ensure_directories()

        # Generate safe filename (remove spaces, special chars, keep extension)
        base_name = Path(original_filename).stem
        safe_name = "".join(c for c in base_name if c.isalnum() or c in "._- ")
        safe_name = safe_name.replace(" ", "_")

        # Original file extension
        original_ext = Path(original_filename).suffix or ".unknown"

        # Paths for original and processed files
        original_filename_safe = f"{safe_name}{original_ext}"
        processed_filename_safe = f"{safe_name}.mp3"

        original_full_path = ORIGINAL_DIR / original_filename_safe
        processed_full_path = PROCESSED_DIR / processed_filename_safe

        # Save original file
        import shutil
        shutil.copy2(input_file_path, original_full_path)
        logger.info(f"Original file saved: {original_full_path}")

        # Convert to MP3 mono with normalization
        convert_to_mp3_mono(
            str(original_full_path),
            str(processed_full_path),
            normalize=True
        )
        logger.info(f"Processed file created: {processed_full_path}")

        # Get duration from processed file
        duration = get_audio_duration(str(processed_full_path))
        logger.info(f"Audio duration: {duration} seconds")

        # Return relative paths (without /app/audio_files/ prefix)
        original_rel_path = f"original/{original_filename_safe}"
        processed_rel_path = f"processed/{processed_filename_safe}"

        return original_rel_path, processed_rel_path, duration

    except Exception as e:
        logger.error(f"Audio processing failed: {e}")
        # Clean up partial files if processing failed
        if original_full_path.exists():
            original_full_path.unlink()
        if processed_full_path.exists():
            processed_full_path.unlink()
        raise


def delete_audio_files(original_path: str | None, processed_path: str | None) -> None:
    """
    Delete audio files (both original and processed).

    Args:
        original_path: Relative path to original file (e.g., "original/file.wav")
        processed_path: Relative path to processed file (e.g., "processed/file.mp3")
    """
    try:
        if original_path:
            original_full_path = AUDIO_BASE_DIR / original_path
            if original_full_path.exists():
                original_full_path.unlink()
                logger.info(f"Deleted original file: {original_full_path}")

        if processed_path:
            processed_full_path = AUDIO_BASE_DIR / processed_path
            if processed_full_path.exists():
                processed_full_path.unlink()
                logger.info(f"Deleted processed file: {processed_full_path}")

    except Exception as e:
        logger.error(f"Error deleting audio files: {e}")
        raise
