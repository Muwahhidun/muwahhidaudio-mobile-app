"""
CRUD operations for Lesson model.
"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models import Lesson


async def get_lesson_by_id(db: AsyncSession, lesson_id: int) -> Optional[Lesson]:
    """
    Get lesson by ID with all relationships.

    Args:
        db: Database session
        lesson_id: Lesson ID

    Returns:
        Lesson object if found, None otherwise
    """
    result = await db.execute(
        select(Lesson)
        .options(
            selectinload(Lesson.series),
            selectinload(Lesson.teacher),
            selectinload(Lesson.book),
            selectinload(Lesson.theme)
        )
        .where(Lesson.id == lesson_id, Lesson.is_active == True)
    )
    return result.scalar_one_or_none()


def format_duration(seconds: Optional[int]) -> str:
    """
    Format duration in seconds to human-readable string.

    Args:
        seconds: Duration in seconds

    Returns:
        Formatted duration string (e.g., "30м 15с" or "1ч 15м")
    """
    if not seconds:
        return "0м"

    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    secs = seconds % 60

    if hours > 0:
        if minutes > 0:
            return f"{hours}ч {minutes}м"
        return f"{hours}ч"
    elif minutes > 0:
        if secs > 0:
            return f"{minutes}м {secs}с"
        return f"{minutes}м"
    else:
        return f"{secs}с"


def get_display_title(lesson: Lesson) -> str:
    """
    Get display title for lesson (e.g., "Урок 1").

    Args:
        lesson: Lesson object

    Returns:
        Display title string
    """
    if lesson.lesson_number:
        return f"Урок {lesson.lesson_number}"
    return lesson.title


def get_audio_url(lesson_id: int, base_url: str = "/api/lessons") -> str:
    """
    Get audio streaming URL for lesson.

    Args:
        lesson_id: Lesson ID
        base_url: Base API URL

    Returns:
        Audio streaming URL
    """
    return f"{base_url}/{lesson_id}/audio"


def parse_tags(tags_str: Optional[str]) -> List[str]:
    """
    Parse comma-separated tags string into list.

    Args:
        tags_str: Tags string (e.g., "акыда,основы,таухид")

    Returns:
        List of tags
    """
    if not tags_str:
        return []
    return [tag.strip() for tag in tags_str.split(",") if tag.strip()]
