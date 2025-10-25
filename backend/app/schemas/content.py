"""
Pydantic schemas for Theme, Author, Book models.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


# Theme schemas
class ThemeBase(BaseModel):
    """Base theme schema."""
    name: str = Field(..., max_length=255)
    description: Optional[str] = None
    sort_order: int = 0
    is_active: bool = True


class ThemeCreate(ThemeBase):
    """Schema for creating a theme."""
    pass


class ThemeUpdate(BaseModel):
    """Schema for updating a theme."""
    name: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None


class ThemeResponse(ThemeBase):
    """Theme response schema."""
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ThemeWithCounts(ThemeResponse):
    """Theme with counts of books and series."""
    books_count: Optional[int] = 0
    series_count: Optional[int] = 0


# Book Author schemas
class BookAuthorBase(BaseModel):
    """Base book author schema."""
    name: str = Field(..., max_length=255)
    biography: Optional[str] = None
    birth_year: Optional[int] = None
    death_year: Optional[int] = None
    is_active: bool = True


class BookAuthorCreate(BookAuthorBase):
    """Schema for creating a book author."""
    pass


class BookAuthorUpdate(BaseModel):
    """Schema for updating a book author."""
    name: Optional[str] = Field(None, max_length=255)
    biography: Optional[str] = None
    birth_year: Optional[int] = None
    death_year: Optional[int] = None
    is_active: Optional[bool] = None


class BookAuthorResponse(BookAuthorBase):
    """Book author response schema."""
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# Book schemas
class BookBase(BaseModel):
    """Base book schema."""
    name: str = Field(..., max_length=255)
    description: Optional[str] = None
    sort_order: int = 0
    is_active: bool = True


class BookCreate(BookBase):
    """Schema for creating a book."""
    theme_id: Optional[int] = None
    author_id: Optional[int] = None


class BookUpdate(BaseModel):
    """Schema for updating a book."""
    name: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = None
    theme_id: Optional[int] = None
    author_id: Optional[int] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None


class BookResponse(BookBase):
    """Book response schema."""
    id: int
    theme_id: Optional[int] = None
    author_id: Optional[int] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class BookWithRelations(BookResponse):
    """Book with theme and author info."""
    theme: Optional[ThemeResponse] = None
    author: Optional[BookAuthorResponse] = None


class BookWithCounts(BookWithRelations):
    """Book with series count."""
    series_count: Optional[int] = 0
