"""
Pydantic schemas for Bookmark model.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
from .lesson import LessonWithRelations, LessonSeriesWithRelations


class BookmarkCreate(BaseModel):
    """Schema for creating a bookmark."""
    lesson_id: int
    custom_name: Optional[str] = Field(None, max_length=200)


class BookmarkUpdate(BaseModel):
    """Schema for updating a bookmark."""
    custom_name: Optional[str] = Field(None, max_length=200)


class BookmarkResponse(BaseModel):
    """Basic bookmark response schema."""
    id: int
    user_id: int
    lesson_id: int
    custom_name: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class BookmarkWithLesson(BookmarkResponse):
    """Bookmark with full lesson details."""
    lesson: Optional[LessonWithRelations] = None


class SeriesWithBookmarkCount(BaseModel):
    """Series with bookmarks count."""
    series: LessonSeriesWithRelations
    bookmarks_count: int

    class Config:
        from_attributes = True


class BookmarkToggleRequest(BaseModel):
    """Request for toggling a bookmark."""
    lesson_id: int
    custom_name: Optional[str] = Field(None, max_length=200)
