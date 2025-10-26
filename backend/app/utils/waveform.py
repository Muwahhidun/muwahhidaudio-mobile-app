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
    samples: int = 100,
    max_amplitude: int = 100
) -> List[int]:
    """
    Generate waveform data from audio file.

    Args:
        audio_path: Path to audio file (MP3, WAV, etc.)
        samples: Number of waveform samples to generate (default: 100)
        max_amplitude: Maximum amplitude value (default: 100)

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

        # Calculate how many samples per waveform point
        chunk_size = len(samples_data) // samples

        if chunk_size == 0:
            chunk_size = 1

        waveform = []

        # Process audio in chunks
        for i in range(samples):
            start = i * chunk_size
            end = min(start + chunk_size, len(samples_data))

            if start >= len(samples_data):
                break

            # Get chunk of audio
            chunk = samples_data[start:end]

            # Calculate RMS (Root Mean Square) amplitude for this chunk
            rms = np.sqrt(np.mean(chunk.astype(np.float64) ** 2))

            # Normalize to 0-max_amplitude range
            # Typical audio is 16-bit, so max value is around 32768
            normalized = int((rms / 32768.0) * max_amplitude)

            # Ensure it's within bounds
            normalized = max(1, min(max_amplitude, normalized))

            waveform.append(normalized)

        return waveform

    except Exception as e:
        print(f"Error generating waveform for {audio_path}: {e}")
        # Return flat waveform as fallback
        return [50] * samples


def generate_waveform_json(
    audio_path: Path,
    samples: int = 100,
    max_amplitude: int = 100
) -> str:
    """
    Generate waveform data as JSON string.

    Args:
        audio_path: Path to audio file
        samples: Number of waveform samples
        max_amplitude: Maximum amplitude value

    Returns:
        JSON string of waveform data
    """
    waveform = generate_waveform(audio_path, samples, max_amplitude)
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
