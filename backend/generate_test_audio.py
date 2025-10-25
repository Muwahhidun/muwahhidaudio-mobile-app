"""
Generate placeholder MP3 files for testing audio streaming.
Creates minimal valid MP3 files.
"""
import os


def create_minimal_mp3(filename: str, duration_kb: int = 100):
    """
    Create a minimal valid MP3 file for testing.

    This creates a file with a valid MP3 header followed by null frames.
    Not playable audio, but valid for streaming tests.

    Args:
        filename: Output filename
        duration_kb: Approximate file size in KB
    """
    # Valid MP3 frame header (MPEG 1 Layer 3, 128kbps, 44.1kHz)
    mp3_header = bytes([
        0xFF, 0xFB,  # Frame sync + MPEG 1 Layer 3
        0x90, 0x00,  # 128kbps, 44.1kHz, no padding, no private bit
    ])

    # ID3v2 header (minimal)
    id3_header = bytes([
        0x49, 0x44, 0x33,  # "ID3"
        0x03, 0x00,        # Version 2.3.0
        0x00,              # Flags
        0x00, 0x00, 0x00, 0x00  # Size (0 - no tags)
    ])

    # Create file with header and padding
    frame_size = 417  # Typical frame size for 128kbps MP3
    num_frames = (duration_kb * 1024) // frame_size

    with open(filename, 'wb') as f:
        # Write ID3 header
        f.write(id3_header)

        # Write MP3 frames
        for _ in range(num_frames):
            f.write(mp3_header)
            # Pad frame with zeros
            f.write(b'\x00' * (frame_size - len(mp3_header)))


def main():
    """Generate test audio files for lessons 1-8."""
    audio_dir = "audio_files"
    os.makedirs(audio_dir, exist_ok=True)

    # Create varying sizes for different lessons
    sizes = {
        1: 100,   # 100 KB
        2: 150,   # 150 KB
        3: 200,   # 200 KB
        4: 120,   # 120 KB
        5: 180,   # 180 KB
        6: 160,   # 160 KB
        7: 140,   # 140 KB
        8: 190,   # 190 KB
    }

    for lesson_id, size_kb in sizes.items():
        filename = os.path.join(audio_dir, f"lesson_{lesson_id}.mp3")
        create_minimal_mp3(filename, size_kb)
        file_size = os.path.getsize(filename)
        print(f"Created {filename} ({file_size:,} bytes)")

    print(f"\nGenerated {len(sizes)} test MP3 files in {audio_dir}/")


if __name__ == "__main__":
    main()
