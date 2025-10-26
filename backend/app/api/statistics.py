"""
Statistics API endpoints for admin panel.
Provides aggregated statistics about content.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import Dict

from app.database import get_db
from app.models import (
    Theme, Book, BookAuthor, LessonTeacher,
    LessonSeries, Lesson, User
)
from app.api.auth import get_current_user
from app.schemas.user import UserResponse as UserSchema

router = APIRouter(prefix="/statistics", tags=["statistics"])


def require_admin(current_user: UserSchema = Depends(get_current_user)) -> UserSchema:
    """
    Dependency to require admin role (level >= 2).
    """
    if current_user.role.level < 2:
        from fastapi import HTTPException
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user


@router.get("")
async def get_statistics(
    db: AsyncSession = Depends(get_db),
    current_user: UserSchema = Depends(require_admin)
) -> Dict:
    """
    Get aggregated statistics for admin dashboard.

    Returns:
        Dictionary with counts for all entities
    """
    # Themes statistics
    themes_total = await db.scalar(select(func.count(Theme.id)))
    themes_active = await db.scalar(select(func.count(Theme.id)).where(Theme.is_active == True))

    # Books statistics
    books_total = await db.scalar(select(func.count(Book.id)))
    books_active = await db.scalar(select(func.count(Book.id)).where(Book.is_active == True))

    # Authors statistics
    authors_total = await db.scalar(select(func.count(BookAuthor.id)))
    authors_active = await db.scalar(select(func.count(BookAuthor.id)).where(BookAuthor.is_active == True))

    # Teachers statistics
    teachers_total = await db.scalar(select(func.count(LessonTeacher.id)))
    teachers_active = await db.scalar(select(func.count(LessonTeacher.id)).where(LessonTeacher.is_active == True))

    # Series statistics
    series_total = await db.scalar(select(func.count(LessonSeries.id)))
    series_active = await db.scalar(select(func.count(LessonSeries.id)).where(LessonSeries.is_active == True))
    series_completed = await db.scalar(
        select(func.count(LessonSeries.id)).where(
            LessonSeries.is_active == True,
            LessonSeries.is_completed == True
        )
    )
    series_in_progress = await db.scalar(
        select(func.count(LessonSeries.id)).where(
            LessonSeries.is_active == True,
            LessonSeries.is_completed == False
        )
    )

    # Lessons statistics
    lessons_total = await db.scalar(select(func.count(Lesson.id)))
    lessons_active = await db.scalar(select(func.count(Lesson.id)).where(Lesson.is_active == True))
    lessons_with_audio = await db.scalar(
        select(func.count(Lesson.id)).where(
            Lesson.is_active == True,
            Lesson.audio_path.isnot(None)
        )
    )
    lessons_without_audio = await db.scalar(
        select(func.count(Lesson.id)).where(
            Lesson.is_active == True,
            Lesson.audio_path.is_(None)
        )
    )

    # Total duration of all active lessons (in seconds)
    total_duration = await db.scalar(
        select(func.sum(Lesson.duration_seconds)).where(
            Lesson.is_active == True,
            Lesson.duration_seconds.isnot(None)
        )
    ) or 0

    # Users statistics
    users_total = await db.scalar(select(func.count(User.id)))
    users_active = await db.scalar(select(func.count(User.id)).where(User.is_active == True))

    return {
        "themes": {
            "total": themes_total or 0,
            "active": themes_active or 0,
            "inactive": (themes_total or 0) - (themes_active or 0)
        },
        "books": {
            "total": books_total or 0,
            "active": books_active or 0,
            "inactive": (books_total or 0) - (books_active or 0)
        },
        "authors": {
            "total": authors_total or 0,
            "active": authors_active or 0,
            "inactive": (authors_total or 0) - (authors_active or 0)
        },
        "teachers": {
            "total": teachers_total or 0,
            "active": teachers_active or 0,
            "inactive": (teachers_total or 0) - (teachers_active or 0)
        },
        "series": {
            "total": series_total or 0,
            "active": series_active or 0,
            "inactive": (series_total or 0) - (series_active or 0),
            "completed": series_completed or 0,
            "in_progress": series_in_progress or 0
        },
        "lessons": {
            "total": lessons_total or 0,
            "active": lessons_active or 0,
            "inactive": (lessons_total or 0) - (lessons_active or 0),
            "with_audio": lessons_with_audio or 0,
            "without_audio": lessons_without_audio or 0,
            "total_duration_seconds": int(total_duration),
            "total_duration_hours": round(total_duration / 3600, 1) if total_duration else 0
        },
        "users": {
            "total": users_total or 0,
            "active": users_active or 0,
            "inactive": (users_total or 0) - (users_active or 0)
        }
    }
