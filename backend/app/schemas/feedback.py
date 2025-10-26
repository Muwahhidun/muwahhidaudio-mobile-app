"""
Pydantic schemas for Feedback model.
Used for API request/response validation.
"""
from __future__ import annotations

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

from app.schemas.user import UserResponse


# ==================== Feedback Schemas ====================


class FeedbackCreate(BaseModel):
    """Schema for creating new feedback."""
    subject: str = Field(..., min_length=3, max_length=255, description="Subject/title of the feedback")
    message_text: str = Field(..., min_length=10, description="Message text")


class FeedbackAdminUpdate(BaseModel):
    """Schema for admin updating feedback (reply, status)."""
    admin_reply: Optional[str] = Field(None, description="Admin's reply to the feedback")
    status: Optional[str] = Field(None, description="Status: new, replied, closed")


# ==================== FeedbackMessage Schemas ====================


class FeedbackMessageCreate(BaseModel):
    """Schema for creating a new message in feedback conversation."""
    message_text: str = Field(..., min_length=1, description="Message text")
    send_as_admin: Optional[bool] = Field(None, description="Send as admin (for admins only). If not specified, auto-detected from user role.")


class FeedbackMessageResponse(BaseModel):
    """Schema for feedback message response."""
    id: int
    feedback_id: int
    author_id: int
    is_admin: bool
    message_text: str
    created_at: datetime
    author: Optional[UserResponse] = None  # Author information

    class Config:
        from_attributes = True


# ==================== Complete Feedback Response ====================


class FeedbackResponse(BaseModel):
    """Schema for feedback response."""
    id: int
    user_id: int
    subject: str
    message_text: str
    admin_reply: Optional[str] = None
    status: str  # 'new', 'replied', 'closed'
    created_at: datetime
    replied_at: Optional[datetime] = None
    closed_at: Optional[datetime] = None
    user: Optional[UserResponse] = None  # For admin view
    messages: list[FeedbackMessageResponse] = []  # Conversation history

    class Config:
        from_attributes = True


class PaginatedFeedbacksResponse(BaseModel):
    """Paginated feedbacks response."""
    items: list[FeedbackResponse]
    total: int
    skip: int
    limit: int
