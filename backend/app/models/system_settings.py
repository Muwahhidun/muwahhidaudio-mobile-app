"""
SystemSettings model.
Stores application configuration like SMTP settings, email templates, etc.
"""
from sqlalchemy import Column, Integer, String, Boolean, Text
from app.database import Base
from app.models.base import TimestampMixin


class SystemSettings(Base, TimestampMixin):
    """System-wide settings stored in database."""

    __tablename__ = "system_settings"

    id = Column(Integer, primary_key=True, index=True)
    key = Column(String(100), unique=True, nullable=False, index=True)
    value = Column(Text, nullable=True)
    category = Column(String(50), nullable=True, index=True)  # e.g., 'smtp', 'email', 'general'
    description = Column(Text, nullable=True)
    is_encrypted = Column(Boolean, default=False, nullable=False)  # For passwords

    def __repr__(self):
        return f"<SystemSettings(key='{self.key}', category='{self.category}')>"
