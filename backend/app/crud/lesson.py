"""
CRUD operations for Lesson model.
"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, and_
from sqlalchemy.orm import selectinload

from app.models import Lesson
from app.schemas.lesson import LessonCreate, LessonUpdate


async def get_all_lessons(
    db: AsyncSession,
    search: Optional[str] = None,
    series_id: Optional[int] = None,
    teacher_id: Optional[int] = None,
    book_id: Optional[int] = None,
    theme_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 100
) -> List[Lesson]:
    """
    Get all active lessons with filters.

    Args:
        db: Database session
        search: Search query for title or description
        series_id: Filter by series ID
        teacher_id: Filter by teacher ID
        book_id: Filter by book ID
        theme_id: Filter by theme ID

    Returns:
        List of lessons
    """
    query = select(Lesson).options(
        selectinload(Lesson.series),
        selectinload(Lesson.teacher),
        selectinload(Lesson.book),
        selectinload(Lesson.theme)
    ).where(Lesson.is_active == True)

    # Apply filters
    if search:
        search_term = f"%{search}%"
        query = query.where(
            or_(
                Lesson.title.ilike(search_term),
                Lesson.description.ilike(search_term),
                Lesson.tags.ilike(search_term)
            )
        )

    if series_id:
        query = query.where(Lesson.series_id == series_id)

    if teacher_id:
        query = query.where(Lesson.teacher_id == teacher_id)

    if book_id:
        query = query.where(Lesson.book_id == book_id)

    if theme_id:
        query = query.where(Lesson.theme_id == theme_id)

    # Order by lesson number
    query = query.order_by(Lesson.series_id, Lesson.lesson_number)

    # Apply pagination
    query = query.offset(skip).limit(limit)

    result = await db.execute(query)
    return list(result.scalars().all())


async def count_lessons(
    db: AsyncSession,
    search: Optional[str] = None,
    series_id: Optional[int] = None,
    teacher_id: Optional[int] = None,
    book_id: Optional[int] = None,
    theme_id: Optional[int] = None
) -> int:
    """
    Count total number of active lessons with filters.

    Args:
        db: Database session
        search: Search query for title or description
        series_id: Filter by series ID
        teacher_id: Filter by teacher ID
        book_id: Filter by book ID
        theme_id: Filter by theme ID

    Returns:
        Total count of lessons matching filters
    """
    from sqlalchemy import func

    query = select(func.count(Lesson.id)).where(Lesson.is_active == True)

    # Apply same filters as get_all_lessons
    if search:
        search_term = f"%{search}%"
        query = query.where(
            or_(
                Lesson.title.ilike(search_term),
                Lesson.description.ilike(search_term),
                Lesson.tags.ilike(search_term)
            )
        )

    if series_id:
        query = query.where(Lesson.series_id == series_id)

    if teacher_id:
        query = query.where(Lesson.teacher_id == teacher_id)

    if book_id:
        query = query.where(Lesson.book_id == book_id)

    if theme_id:
        query = query.where(Lesson.theme_id == theme_id)

    result = await db.execute(query)
    return result.scalar_one()


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


async def create_lesson(db: AsyncSession, lesson_data: LessonCreate) -> Lesson:
    """
    Create a new lesson.

    Args:
        db: Database session
        lesson_data: Lesson creation data

    Returns:
        Created lesson object
    """
    lesson = Lesson(**lesson_data.model_dump())
    db.add(lesson)
    await db.commit()
    await db.refresh(lesson)

    # Load relationships
    await db.refresh(lesson, ["series", "teacher", "book", "theme"])

    return lesson


async def update_lesson(
    db: AsyncSession,
    lesson_id: int,
    lesson_data: LessonUpdate
) -> Optional[Lesson]:
    """
    Update a lesson.

    Args:
        db: Database session
        lesson_id: Lesson ID
        lesson_data: Lesson update data

    Returns:
        Updated lesson object or None if not found
    """
    lesson = await get_lesson_by_id(db, lesson_id)

    if not lesson:
        return None

    # Update only provided fields
    update_data = lesson_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(lesson, field, value)

    await db.commit()
    await db.refresh(lesson)

    # Load relationships
    await db.refresh(lesson, ["series", "teacher", "book", "theme"])

    return lesson


async def delete_lesson(db: AsyncSession, lesson_id: int) -> bool:
    """
    Soft delete a lesson (set is_active to False).

    Args:
        db: Database session
        lesson_id: Lesson ID

    Returns:
        True if deleted, False if not found
    """
    lesson = await get_lesson_by_id(db, lesson_id)

    if not lesson:
        return False

    lesson.is_active = False
    await db.commit()

    return True
