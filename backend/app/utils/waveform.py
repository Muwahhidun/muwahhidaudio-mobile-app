"""
Waveform generation utilities for audio files.
"""
import json
from pathlib import Path
from typing import List, Optional
import numpy as np
from pydub import AudioSegment


def generate_waveform(
    audio_path: Path,
    samples: int = None,
    max_amplitude: int = 100,
    points_per_second: int = 4
) -> List[int]:
    """
    Generate waveform data from audio file.

    Args:
        audio_path: Path to audio file (MP3, WAV, etc.)
        samples: Number of waveform samples to generate (if None, calculated from duration)
        max_amplitude: Maximum amplitude value (default: 100)
        points_per_second: Number of waveform points per second (default: 3)

    Returns:
        List of amplitude values representing the waveform
    """
    try:
        # Load audio file
        audio = AudioSegment.from_file(str(audio_path))

        # Convert to mono for simpler processing
        if audio.channels > 1:
            audio = audio.set_channels(1)

        # Get raw audio data as numpy array
        samples_data = np.array(audio.get_array_of_samples())

        # Calculate samples based on duration if not provided
        if samples is None:
            duration_seconds = len(audio) / 1000.0  # pydub uses milliseconds
            samples = int(duration_seconds * points_per_second)
            # Minimum 10 points for very short audio
            samples = max(10, samples)

        # Calculate how many samples per waveform point
        chunk_size = len(samples_data) // samples

        if chunk_size == 0:
            chunk_size = 1

        # First pass: calculate all RMS values to find the maximum
        rms_values = []
        for i in range(samples):
            start = i * chunk_size
            end = min(start + chunk_size, len(samples_data))

            if start >= len(samples_data):
                break

            # Get chunk of audio
            chunk = samples_data[start:end]

            # Calculate RMS (Root Mean Square) amplitude for this chunk
            rms = np.sqrt(np.mean(chunk.astype(np.float64) ** 2))
            rms_values.append(rms)

        # Find maximum RMS for normalization
        max_rms = max(rms_values) if rms_values else 1.0

        # Prevent division by zero
        if max_rms == 0:
            max_rms = 1.0

        # Second pass: normalize relative to the maximum RMS in this audio
        waveform = []
        for rms in rms_values:
            # Normalize to 0-max_amplitude range based on actual audio dynamics
            normalized = int((rms / max_rms) * max_amplitude)

            # Ensure it's within bounds (min 1 to avoid invisible bars)
            normalized = max(1, min(max_amplitude, normalized))

            waveform.append(normalized)

        return waveform

    except Exception as e:
        print(f"Error generating waveform for {audio_path}: {e}")
        # Return flat waveform as fallback
        return [50] * samples


def generate_waveform_json(
    audio_path: Path,
    samples: int = None,
    max_amplitude: int = 100,
    points_per_second: int = 3
) -> str:
    """
    Generate waveform data as JSON string.

    Args:
        audio_path: Path to audio file
        samples: Number of waveform samples (if None, calculated from duration)
        max_amplitude: Maximum amplitude value
        points_per_second: Number of waveform points per second (default: 3)

    Returns:
        JSON string of waveform data
    """
    waveform = generate_waveform(audio_path, samples, max_amplitude, points_per_second)
    return json.dumps(waveform)


def get_audio_duration(audio_path: Path) -> Optional[int]:
    """
    Get duration of audio file in seconds.

    Args:
        audio_path: Path to audio file

    Returns:
        Duration in seconds, or None if error
    """
    try:
        audio = AudioSegment.from_file(str(audio_path))
        return int(audio.duration_seconds)
    except Exception as e:
        print(f"Error getting duration for {audio_path}: {e}")
        return None
