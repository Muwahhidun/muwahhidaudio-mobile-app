"""
Pydantic schemas for Teacher, Series, Lesson models.
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field


# Lesson Teacher schemas
class LessonTeacherBase(BaseModel):
    """Base lesson teacher schema."""
    name: str = Field(..., max_length=255)
    biography: Optional[str] = None
    is_active: bool = True


class LessonTeacherCreate(LessonTeacherBase):
    """Schema for creating a lesson teacher."""
    pass


class LessonTeacherUpdate(BaseModel):
    """Schema for updating a lesson teacher."""
    name: Optional[str] = Field(None, max_length=255)
    biography: Optional[str] = None
    is_active: Optional[bool] = None


class LessonTeacherResponse(LessonTeacherBase):
    """Lesson teacher response schema."""
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class LessonTeacherWithCounts(LessonTeacherResponse):
    """Teacher with series and lessons count."""
    series_count: Optional[int] = 0
    lessons_count: Optional[int] = 0


# Lesson Series schemas
class LessonSeriesBase(BaseModel):
    """Base lesson series schema."""
    name: str = Field(..., max_length=255)
    year: int
    description: Optional[str] = None
    is_completed: bool = False
    order: int = 0
    is_active: bool = True


class LessonSeriesCreate(BaseModel):
    """Schema for creating a lesson series."""
    name: str = Field(..., max_length=255)
    year: int
    description: Optional[str] = None
    teacher_id: int
    book_id: Optional[int] = None
    theme_id: Optional[int] = None
    is_completed: bool = False
    order: int = 0
    is_active: bool = True


class LessonSeriesUpdate(BaseModel):
    """Schema for updating a lesson series."""
    name: Optional[str] = Field(None, max_length=255)
    year: Optional[int] = None
    description: Optional[str] = None
    teacher_id: Optional[int] = None
    book_id: Optional[int] = None
    theme_id: Optional[int] = None
    is_completed: Optional[bool] = None
    order: Optional[int] = None
    is_active: Optional[bool] = None


class LessonSeriesResponse(LessonSeriesBase):
    """Lesson series response schema."""
    id: int
    teacher_id: int
    book_id: Optional[int] = None
    theme_id: Optional[int] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# Nested schemas for relationships (to avoid circular imports)
class LessonSeriesNested(BaseModel):
    """Nested series info for lesson responses."""
    id: int
    name: str
    year: int
    display_name: Optional[str] = None

    class Config:
        from_attributes = True


class TeacherNested(BaseModel):
    """Nested teacher info."""
    id: int
    name: str

    class Config:
        from_attributes = True


class ThemeNested(BaseModel):
    """Nested theme info."""
    id: int
    name: str

    class Config:
        from_attributes = True


class BookNested(BaseModel):
    """Nested book info."""
    id: int
    name: str

    class Config:
        from_attributes = True


class LessonSeriesWithRelations(LessonSeriesResponse):
    """Series with teacher, book, theme info."""
    teacher: Optional[TeacherNested] = None
    book: Optional[BookNested] = None
    theme: Optional[ThemeNested] = None
    display_name: Optional[str] = None


class LessonSeriesWithCounts(LessonSeriesWithRelations):
    """Series with lessons count."""
    lessons_count: Optional[int] = 0
    total_duration: Optional[str] = None  # Formatted duration


# Lesson schemas
class LessonBase(BaseModel):
    """Base lesson schema."""
    title: str = Field(..., max_length=255)
    description: Optional[str] = None
    lesson_number: Optional[int] = None
    duration_seconds: Optional[int] = None
    tags: Optional[str] = None
    is_active: bool = True


class LessonCreate(BaseModel):
    """Schema for creating a lesson."""
    title: str = Field(..., max_length=255)
    description: Optional[str] = None
    lesson_number: Optional[int] = None
    duration_seconds: Optional[int] = None
    tags: Optional[str] = None
    series_id: int
    book_id: Optional[int] = None
    teacher_id: Optional[int] = None
    theme_id: Optional[int] = None
    is_active: bool = True


class LessonUpdate(BaseModel):
    """Schema for updating a lesson."""
    title: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = None
    audio_path: Optional[str] = Field(None, max_length=500)
    original_audio_path: Optional[str] = Field(None, max_length=500)
    lesson_number: Optional[int] = None
    duration_seconds: Optional[int] = None
    tags: Optional[str] = None
    waveform_data: Optional[str] = None  # JSON array of waveform amplitude values
    series_id: Optional[int] = None
    book_id: Optional[int] = None
    teacher_id: Optional[int] = None
    theme_id: Optional[int] = None
    is_active: Optional[bool] = None


class LessonResponse(LessonBase):
    """Lesson response schema."""
    id: int
    audio_path: Optional[str] = Field(None, serialization_alias='audio_file_path')
    original_audio_path: Optional[str] = None
    series_id: int
    book_id: Optional[int] = None
    teacher_id: Optional[int] = None
    theme_id: Optional[int] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
        populate_by_name = True


class LessonWithRelations(LessonResponse):
    """Lesson with all related info (for mobile app)."""
    display_title: Optional[str] = None  # e.g., "Урок 1"
    formatted_duration: Optional[str] = None  # e.g., "30м 15с"
    audio_url: Optional[str] = None  # API URL for audio streaming
    tags_list: Optional[List[str]] = None  # Parsed tags
    waveform_data: Optional[str] = None  # JSON array of waveform amplitude values

    # Related entities
    series: Optional[LessonSeriesNested] = None
    teacher: Optional[TeacherNested] = None
    book: Optional[BookNested] = None
    theme: Optional[ThemeNested] = None


class LessonListItem(BaseModel):
    """Simplified lesson for list views."""
    id: int
    lesson_number: Optional[int] = None
    display_title: str
    duration_seconds: Optional[int] = None
    formatted_duration: Optional[str] = None
    audio_url: Optional[str] = None
    waveform_data: Optional[str] = None  # JSON array of waveform amplitude values
    teacher: Optional[TeacherNested] = None
    book: Optional[BookNested] = None

    class Config:
        from_attributes = True
