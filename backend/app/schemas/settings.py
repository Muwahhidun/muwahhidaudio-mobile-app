"""
Pydantic schemas for SystemSettings model.
Used for API request/response validation.
"""
from typing import Optional
from pydantic import BaseModel, EmailStr, Field


class SMTPSettings(BaseModel):
    """SMTP and email settings response schema."""
    smtp_host: str = Field(..., description="SMTP server hostname")
    smtp_port: int = Field(..., ge=1, le=65535, description="SMTP server port")
    smtp_username: str = Field(..., description="SMTP username/email")
    smtp_password: str = Field(..., description="SMTP password (masked in response)")
    smtp_use_ssl: bool = Field(..., description="Use SSL for SMTP connection")
    email_from_name: str = Field(..., description="Display name for sender")
    email_from_address: EmailStr = Field(..., description="Email address for sender")
    frontend_url: str = Field(..., description="Frontend URL for email links")


class SMTPSettingsUpdate(BaseModel):
    """SMTP and email settings update schema."""
    smtp_host: str = Field(..., min_length=1, description="SMTP server hostname")
    smtp_port: int = Field(..., ge=1, le=65535, description="SMTP server port (1-65535)")
    smtp_username: str = Field(..., min_length=1, description="SMTP username/email")
    smtp_password: str = Field(..., min_length=1, description="SMTP password")
    smtp_use_ssl: bool = Field(..., description="Use SSL for SMTP connection")
    email_from_name: str = Field(..., min_length=1, description="Display name for sender")
    email_from_address: EmailStr = Field(..., description="Email address for sender")
    frontend_url: str = Field(..., min_length=1, description="Frontend URL for email links")


class TestEmailRequest(BaseModel):
    """Test email request schema."""
    test_email: EmailStr = Field(..., description="Email address to send test email to")


class TestEmailResponse(BaseModel):
    """Test email response schema."""
    success: bool = Field(..., description="Whether email was sent successfully")
    message: str = Field(..., description="Result message")
