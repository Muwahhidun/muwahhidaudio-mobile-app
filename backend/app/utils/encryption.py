"""
Encryption utilities for sensitive data like SMTP passwords.
Uses Fernet symmetric encryption from cryptography library.
"""
import base64
from cryptography.fernet import Fernet
from app.config import settings


def get_encryption_key() -> bytes:
    """
    Get encryption key from settings.
    If not set, generate a new one (for development only).
    """
    key = settings.SETTINGS_ENCRYPTION_KEY
    if not key:
        # Generate a new key for development
        # In production, this should be set in environment variables
        return Fernet.generate_key()

    # Key should be 32 url-safe base64-encoded bytes
    if isinstance(key, str):
        return key.encode()
    return key


def encrypt_value(value: str) -> str:
    """
    Encrypt a string value.

    Args:
        value: Plain text string to encrypt

    Returns:
        Encrypted string (base64 encoded)
    """
    if not value:
        return value

    key = get_encryption_key()
    f = Fernet(key)
    encrypted_bytes = f.encrypt(value.encode())
    return encrypted_bytes.decode()


def decrypt_value(encrypted_value: str) -> str:
    """
    Decrypt an encrypted string value.

    Args:
        encrypted_value: Encrypted string (base64 encoded)

    Returns:
        Decrypted plain text string
    """
    if not encrypted_value:
        return encrypted_value

    key = get_encryption_key()
    f = Fernet(key)
    try:
        decrypted_bytes = f.decrypt(encrypted_value.encode())
        return decrypted_bytes.decode()
    except Exception:
        # If decryption fails, return as-is (might be plain text)
        return encrypted_value
