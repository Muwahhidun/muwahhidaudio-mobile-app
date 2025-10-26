"""
Pydantic schemas for User model.
Used for API request/response validation.
"""
from datetime import datetime
from typing import Optional
import re
from pydantic import BaseModel, EmailStr, Field, field_validator


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
    """User registration schema with email verification."""
    email: EmailStr = Field(..., description="User email address")
    username: str = Field(..., min_length=3, max_length=20, description="Username (3-20 characters, English only)")
    password: str = Field(..., min_length=8, max_length=100, description="Password (min 8 characters, letters + digits)")
    first_name: Optional[str] = Field(None, max_length=255, description="First name (optional)")
    last_name: Optional[str] = Field(None, max_length=255, description="Last name (optional)")

    @field_validator('username')
    @classmethod
    def validate_username(cls, v: str) -> str:
        """Validate username: only English letters, digits, underscore."""
        if not re.match(r'^[a-zA-Z0-9_]{3,20}$', v):
            raise ValueError('Username must be 3-20 characters and contain only English letters, digits, and underscore')
        return v

    @field_validator('password')
    @classmethod
    def validate_password(cls, v: str) -> str:
        """Validate password: min 8 chars, letters + digits, English only."""
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        if not re.search(r'[A-Za-z]', v):
            raise ValueError('Password must contain at least one letter')
        if not re.search(r'\d', v):
            raise ValueError('Password must contain at least one digit')
        if not re.match(r'^[A-Za-z\d@$!%*?&]+$', v):
            raise ValueError('Password must contain only English letters, digits, and special characters (@$!%*?&)')
        return v


class UserLogin(BaseModel):
    """User login schema."""
    login_or_email: str = Field(..., description="Username or email address")
    password: str = Field(..., description="User password")


class UserResponse(BaseModel):
    """User response schema (without password)."""
    id: int
    email: str
    username: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    is_active: bool
    email_verified: bool
    role: RoleResponse
    created_at: datetime

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    """User update schema."""
    first_name: Optional[str] = Field(None, max_length=255)
    last_name: Optional[str] = Field(None, max_length=255)


class UserProfileUpdate(BaseModel):
    """User profile update schema (for self-update)."""
    email: Optional[EmailStr] = Field(None, description="New email address")
    username: Optional[str] = Field(None, min_length=3, max_length=20, description="New username")
    current_password: str = Field(..., description="Current password (required for verification)")
    new_password: Optional[str] = Field(None, min_length=8, max_length=100, description="New password (optional)")
    first_name: Optional[str] = Field(None, max_length=255, description="First name")
    last_name: Optional[str] = Field(None, max_length=255, description="Last name")

    @field_validator('username')
    @classmethod
    def validate_username(cls, v: Optional[str]) -> Optional[str]:
        """Validate username: only English letters, digits, underscore."""
        if v is not None and not re.match(r'^[a-zA-Z0-9_]{3,20}$', v):
            raise ValueError('Username must be 3-20 characters and contain only English letters, digits, and underscore')
        return v

    @field_validator('new_password')
    @classmethod
    def validate_new_password(cls, v: Optional[str]) -> Optional[str]:
        """Validate new password if provided."""
        if v is None:
            return v
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        if not re.search(r'[A-Za-z]', v):
            raise ValueError('Password must contain at least one letter')
        if not re.search(r'\d', v):
            raise ValueError('Password must contain at least one digit')
        if not re.match(r'^[A-Za-z\d@$!%*?&]+$', v):
            raise ValueError('Password must contain only English letters, digits, and special characters (@$!%*?&)')
        return v


class UserAdminUpdate(BaseModel):
    """User update schema for admins (role, status, email verification, credentials)."""
    email: Optional[EmailStr] = Field(None, description="New email address")
    username: Optional[str] = Field(None, min_length=3, max_length=20, description="New username")
    password: Optional[str] = Field(None, min_length=8, max_length=100, description="New password")
    first_name: Optional[str] = Field(None, max_length=255, description="First name")
    last_name: Optional[str] = Field(None, max_length=255, description="Last name")
    role_id: Optional[int] = Field(None, description="Role ID (1=User, 2=Admin)")
    is_active: Optional[bool] = Field(None, description="Active status")
    email_verified: Optional[bool] = Field(None, description="Email verification status")

    @field_validator('username')
    @classmethod
    def validate_username(cls, v: Optional[str]) -> Optional[str]:
        """Validate username: only English letters, digits, underscore."""
        if v is not None and not re.match(r'^[a-zA-Z0-9_]{3,20}$', v):
            raise ValueError('Username must be 3-20 characters and contain only English letters, digits, and underscore')
        return v

    @field_validator('password')
    @classmethod
    def validate_password(cls, v: Optional[str]) -> Optional[str]:
        """Validate password if provided."""
        if v is None:
            return v
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        if not re.search(r'[A-Za-z]', v):
            raise ValueError('Password must contain at least one letter')
        if not re.search(r'\d', v):
            raise ValueError('Password must contain at least one digit')
        if not re.match(r'^[A-Za-z\d@$!%*?&]+$', v):
            raise ValueError('Password must contain only English letters, digits, and special characters (@$!%*?&)')
        return v


class PaginatedUsersResponse(BaseModel):
    """Paginated users response."""
    items: list[UserResponse]
    total: int
    skip: int
    limit: int


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


# Email verification schemas
class EmailVerificationRequest(BaseModel):
    """Email verification request schema."""
    token: str = Field(..., description="Verification token from email")


class ResendVerificationRequest(BaseModel):
    """Resend verification email request schema."""
    email: EmailStr = Field(..., description="User email address")


class RefreshTokenRequest(BaseModel):
    """Refresh token request schema."""
    refresh_token: str = Field(..., description="Refresh token to exchange for new access token")
