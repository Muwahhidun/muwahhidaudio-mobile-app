"""
Application configuration settings.
Uses pydantic-settings for environment variable management.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Application
    APP_NAME: str = "Islamic Audio Lessons API"
    DEBUG: bool = True
    API_V1_PREFIX: str = "/api"

    # Database
    DATABASE_URL: str

    # Redis
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_CACHE_DB: int = 0
    REDIS_SESSION_DB: int = 1
    REDIS_PASSWORD: str = ""

    # JWT Authentication
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # CORS
    ALLOWED_ORIGINS: str = "http://localhost:3000,http://localhost:8080,http://localhost:*"

    @property
    def allowed_origins_list(self) -> List[str]:
        """Parse ALLOWED_ORIGINS into a list."""
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",")]

    # Audio files
    AUDIO_FILES_PATH: str = "/app/audio_files"

    # Cache TTL (seconds)
    CACHE_TTL_THEMES: int = 3600  # 1 hour
    CACHE_TTL_TEACHERS: int = 3600  # 1 hour
    CACHE_TTL_SERIES: int = 1800  # 30 minutes
    CACHE_TTL_LESSONS: int = 1800  # 30 minutes

    # Email & SMTP (fallback if not in database)
    SMTP_HOST: str = "smtp.mail.ru"
    SMTP_PORT: int = 465
    SMTP_USERNAME: str = "x@muwahhid.ru"
    SMTP_PASSWORD: str = "tv4RAYKDrZFtgmMEd5oS"
    SMTP_USE_SSL: bool = True
    EMAIL_FROM_NAME: str = "Muwahhid"
    EMAIL_FROM_ADDRESS: str = "x@muwahhid.ru"
    FRONTEND_URL: str = "http://localhost:3065"

    # Encryption key for sensitive data (32 url-safe base64-encoded bytes)
    # Generate with: python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
    SETTINGS_ENCRYPTION_KEY: str = ""  # Will auto-generate if empty (dev only)

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra='ignore'  # Ignore extra environment variables
    )


# Global settings instance
settings = Settings()
