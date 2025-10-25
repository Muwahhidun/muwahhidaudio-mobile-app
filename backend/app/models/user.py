"""
User and Role models.
Handles authentication and authorization.
"""
from sqlalchemy import Column, Integer, String, Boolean, BigInteger, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.database import Base
from app.models.base import TimestampMixin


class Role(Base, TimestampMixin):
    """User roles (Admin, Moderator, User)."""

    __tablename__ = "roles"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), unique=True, nullable=False)  # 'Admin', 'Moderator', 'User'
    description = Column(Text, nullable=True)
    level = Column(Integer, nullable=False, default=0)  # 0=User, 1=Moderator, 2=Admin

    # Relationships
    users = relationship("User", back_populates="role")

    def __repr__(self):
        return f"<Role(id={self.id}, name='{self.name}', level={self.level})>"


class User(Base, TimestampMixin):
    """Application users."""

    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    first_name = Column(String(255), nullable=True)
    last_name = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    role_id = Column(Integer, ForeignKey("roles.id"), default=3, nullable=False)  # Default: User role

    # Relationships
    role = relationship("Role", back_populates="users")
    bookmarks = relationship("Bookmark", back_populates="user", cascade="all, delete-orphan")
    test_attempts = relationship("TestAttempt", back_populates="user", cascade="all, delete-orphan")
    feedbacks = relationship("Feedback", back_populates="user", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User(id={self.id}, email='{self.email}', name='{self.first_name} {self.last_name}')>"
