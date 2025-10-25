"""
Pydantic schemas for User model.
Used for API request/response validation.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field


# Role schemas
class RoleBase(BaseModel):
    """Base role schema."""
    name: str
    level: int


class RoleResponse(RoleBase):
    """Role response schema."""
    id: int
    description: Optional[str] = None

    class Config:
        from_attributes = True


# User schemas
class UserRegister(BaseModel):
    """User registration schema."""
    email: EmailStr = Field(..., description="User email address")
    password: str = Field(..., min_length=8, max_length=100, description="User password (min 8 characters)")
    first_name: Optional[str] = Field(None, max_length=255, description="First name")
    last_name: Optional[str] = Field(None, max_length=255, description="Last name")


class UserLogin(BaseModel):
    """User login schema."""
    email: EmailStr = Field(..., description="User email address")
    password: str = Field(..., description="User password")


class UserResponse(BaseModel):
    """User response schema (without password)."""
    id: int
    email: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    is_active: bool
    role: RoleResponse
    created_at: datetime

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    """User update schema."""
    first_name: Optional[str] = Field(None, max_length=255)
    last_name: Optional[str] = Field(None, max_length=255)


# Token schemas
class Token(BaseModel):
    """JWT token response."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenWithUser(BaseModel):
    """JWT token response with user data."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse


class TokenData(BaseModel):
    """Token payload data."""
    user_id: Optional[int] = None
    email: Optional[str] = None
