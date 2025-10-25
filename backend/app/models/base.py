"""
Base mixins for models.
Provides common fields like created_at, updated_at.
"""
from datetime import datetime
from sqlalchemy import Column, DateTime
from sqlalchemy.ext.declarative import declared_attr


class TimestampMixin:
    """Mixin for created_at and updated_at timestamps."""

    @declared_attr
    def created_at(cls):
        return Column(DateTime, nullable=False, default=datetime.utcnow)

    @declared_attr
    def updated_at(cls):
        return Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
