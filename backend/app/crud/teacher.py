"""
CRUD operations for LessonTeacher and LessonSeries models.
"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload

from app.models import LessonTeacher, LessonSeries, Lesson, Theme, Book
from app.schemas.lesson import LessonTeacherCreate, LessonTeacherUpdate


async def count_teachers(
    db: AsyncSession,
    search: Optional[str] = None,
    include_inactive: bool = False
) -> int:
    """
    Count total number of teachers with filters.

    Args:
        db: Database session
        search: Search query for name or biography
        include_inactive: Include inactive teachers (for admin)

    Returns:
        Total count of teachers matching filters
    """
    query = select(func.count(LessonTeacher.id))

    if not include_inactive:
        query = query.where(LessonTeacher.is_active == True)

    if search:
        from sqlalchemy import or_
        search_term = f"%{search}%"
        query = query.where(
            or_(
                LessonTeacher.name.ilike(search_term),
                LessonTeacher.biography.ilike(search_term)
            )
        )

    result = await db.execute(query)
    return result.scalar_one()


async def get_all_teachers(
    db: AsyncSession,
    search: Optional[str] = None,
    include_inactive: bool = False,
    skip: int = 0,
    limit: int = 100
) -> List[LessonTeacher]:
    """
    Get all teachers with optional search and pagination.

    Args:
        db: Database session
        search: Optional search term for name or biography
        include_inactive: Include inactive teachers (for admin)
        skip: Number of records to skip
        limit: Maximum number of records to return

    Returns:
        List of LessonTeacher objects
    """
    query = select(LessonTeacher)

    if not include_inactive:
        query = query.where(LessonTeacher.is_active == True)

    # Apply search filter
    if search:
        from sqlalchemy import or_
        search_term = f"%{search}%"
        query = query.where(
            or_(
                LessonTeacher.name.ilike(search_term),
                LessonTeacher.biography.ilike(search_term)
            )
        )

    query = query.order_by(LessonTeacher.name).offset(skip).limit(limit)
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_teacher_by_id(db: AsyncSession, teacher_id: int) -> Optional[LessonTeacher]:
    """
    Get teacher by ID.

    Args:
        db: Database session
        teacher_id: Teacher ID

    Returns:
        LessonTeacher object if found, None otherwise
    """
    result = await db.execute(
        select(LessonTeacher)
        .where(LessonTeacher.id == teacher_id, LessonTeacher.is_active == True)
    )
    return result.scalar_one_or_none()


async def get_teacher_series(db: AsyncSession, teacher_id: int) -> List[LessonSeries]:
    """
    Get all series by teacher.

    Args:
        db: Database session
        teacher_id: Teacher ID

    Returns:
        List of LessonSeries objects with relationships
    """
    result = await db.execute(
        select(LessonSeries)
        .options(
            selectinload(LessonSeries.book),
            selectinload(LessonSeries.theme),
            selectinload(LessonSeries.teacher)
        )
        .where(
            LessonSeries.teacher_id == teacher_id,
            LessonSeries.is_active == True
        )
        .order_by(LessonSeries.year.desc(), LessonSeries.order)
    )
    return list(result.scalars().all())


async def get_series_by_id(db: AsyncSession, series_id: int) -> Optional[LessonSeries]:
    """
    Get series by ID with all relationships.

    Args:
        db: Database session
        series_id: Series ID

    Returns:
        LessonSeries object if found, None otherwise
    """
    result = await db.execute(
        select(LessonSeries)
        .options(
            selectinload(LessonSeries.teacher),
            selectinload(LessonSeries.book),
            selectinload(LessonSeries.theme)
        )
        .where(LessonSeries.id == series_id, LessonSeries.is_active == True)
    )
    return result.scalar_one_or_none()


async def get_series_lessons(db: AsyncSession, series_id: int) -> List[Lesson]:
    """
    Get all lessons in a series.

    Args:
        db: Database session
        series_id: Series ID

    Returns:
        List of Lesson objects ordered by lesson_number
    """
    result = await db.execute(
        select(Lesson)
        .where(
            Lesson.series_id == series_id,
            Lesson.is_active == True
        )
        .order_by(Lesson.lesson_number)
    )
    return list(result.scalars().all())


async def get_series_with_stats(db: AsyncSession, series_id: int) -> Optional[dict]:
    """
    Get series with lessons count and total duration.

    Args:
        db: Database session
        series_id: Series ID

    Returns:
        Dict with series info and stats
    """
    series = await get_series_by_id(db, series_id)
    if not series:
        return None

    # Get lessons count and total duration
    stats_result = await db.execute(
        select(
            func.count(Lesson.id).label("count"),
            func.sum(Lesson.duration_seconds).label("total_duration")
        )
        .where(Lesson.series_id == series_id, Lesson.is_active == True)
    )
    stats = stats_result.one()

    # Format duration
    total_seconds = stats.total_duration or 0
    hours = total_seconds // 3600
    minutes = (total_seconds % 3600) // 60

    formatted_duration = ""
    if hours > 0:
        formatted_duration = f"{hours}ч {minutes}м"
    else:
        formatted_duration = f"{minutes}м"

    return {
        "series": series,
        "lessons_count": stats.count,
        "total_duration": formatted_duration
    }


async def create_teacher(db: AsyncSession, teacher_data: LessonTeacherCreate) -> LessonTeacher:
    """
    Create a new teacher.

    Args:
        db: Database session
        teacher_data: Teacher creation data

    Returns:
        Created LessonTeacher object
    """
    teacher = LessonTeacher(**teacher_data.model_dump())
    db.add(teacher)
    await db.commit()
    await db.refresh(teacher)
    return teacher


async def update_teacher(
    db: AsyncSession, teacher_id: int, teacher_data: LessonTeacherUpdate
) -> Optional[LessonTeacher]:
    """
    Update an existing teacher.

    Args:
        db: Database session
        teacher_id: Teacher ID
        teacher_data: Teacher update data

    Returns:
        Updated LessonTeacher object if found, None otherwise
    """
    result = await db.execute(
        select(LessonTeacher).where(LessonTeacher.id == teacher_id)
    )
    teacher = result.scalar_one_or_none()

    if not teacher:
        return None

    # Update only provided fields
    update_data = teacher_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(teacher, field, value)

    await db.commit()
    await db.refresh(teacher)

    return teacher


async def delete_teacher(db: AsyncSession, teacher_id: int) -> bool:
    """
    Soft delete a teacher (set is_active = False).

    Args:
        db: Database session
        teacher_id: Teacher ID

    Returns:
        True if deleted successfully, False if teacher not found
    """
    result = await db.execute(
        select(LessonTeacher).where(LessonTeacher.id == teacher_id)
    )
    teacher = result.scalar_one_or_none()

    if not teacher:
        return False

    teacher.is_active = False
    await db.commit()

    return True
