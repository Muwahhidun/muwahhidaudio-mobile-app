"""
CRUD operations for Theme model.
"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_
from sqlalchemy.orm import selectinload

from app.models import Theme, Book, LessonSeries
from app.schemas.content import ThemeCreate, ThemeUpdate


async def count_themes(
    db: AsyncSession,
    search: Optional[str] = None,
    teacher_id: Optional[int] = None,
    include_inactive: bool = False
) -> int:
    """
    Count total number of themes with filters.

    Args:
        db: Database session
        search: Search query for name or description
        teacher_id: Filter by teacher (themes taught by this teacher)
        include_inactive: Include inactive themes (for admin)

    Returns:
        Total count of themes matching filters
    """
    query = select(func.count(func.distinct(Theme.id)))

    # Join with LessonSeries if filtering by teacher
    if teacher_id is not None:
        query = query.join(LessonSeries, LessonSeries.theme_id == Theme.id)
        query = query.where(LessonSeries.teacher_id == teacher_id)
        query = query.where(LessonSeries.is_active == True)

    if not include_inactive:
        query = query.where(Theme.is_active == True)

    if search:
        search_term = f"%{search}%"
        query = query.where(
            or_(
                Theme.name.ilike(search_term),
                Theme.description.ilike(search_term)
            )
        )

    result = await db.execute(query)
    return result.scalar_one()


async def get_all_themes(
    db: AsyncSession,
    search: Optional[str] = None,
    teacher_id: Optional[int] = None,
    include_inactive: bool = False,
    skip: int = 0,
    limit: int = 100
) -> List[Theme]:
    """
    Get all themes with optional search and pagination.

    Args:
        db: Database session
        search: Search query for name or description (case-insensitive)
        teacher_id: Filter by teacher (themes taught by this teacher)
        include_inactive: Include inactive themes (for admin)
        skip: Number of records to skip
        limit: Maximum number of records to return

    Returns:
        List of Theme objects
    """
    query = select(Theme).distinct()

    # Join with LessonSeries if filtering by teacher
    if teacher_id is not None:
        query = query.join(LessonSeries, LessonSeries.theme_id == Theme.id)
        query = query.where(LessonSeries.teacher_id == teacher_id)
        query = query.where(LessonSeries.is_active == True)

    # Filter by active status unless include_inactive is True
    if not include_inactive:
        query = query.where(Theme.is_active == True)

    # Add search filter if provided
    if search:
        search_term = f"%{search}%"
        query = query.where(
            or_(
                Theme.name.ilike(search_term),
                Theme.description.ilike(search_term)
            )
        )

    query = query.order_by(Theme.sort_order, Theme.name).offset(skip).limit(limit)
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_theme_by_id(db: AsyncSession, theme_id: int) -> Optional[Theme]:
    """
    Get theme by ID.

    Args:
        db: Database session
        theme_id: Theme ID

    Returns:
        Theme object if found, None otherwise
    """
    result = await db.execute(
        select(Theme)
        .where(Theme.id == theme_id, Theme.is_active == True)
    )
    return result.scalar_one_or_none()


async def get_theme_with_counts(db: AsyncSession, theme_id: int) -> Optional[dict]:
    """
    Get theme with books and series counts.

    Args:
        db: Database session
        theme_id: Theme ID

    Returns:
        Dict with theme info and counts
    """
    theme = await get_theme_by_id(db, theme_id)
    if not theme:
        return None

    # Count books
    books_count_result = await db.execute(
        select(func.count(Book.id))
        .where(Book.theme_id == theme_id, Book.is_active == True)
    )
    books_count = books_count_result.scalar()

    # Count series
    series_count_result = await db.execute(
        select(func.count(LessonSeries.id))
        .where(LessonSeries.theme_id == theme_id, LessonSeries.is_active == True)
    )
    series_count = series_count_result.scalar()

    return {
        "theme": theme,
        "books_count": books_count,
        "series_count": series_count
    }


async def create_theme(db: AsyncSession, theme_data: ThemeCreate) -> Theme:
    """
    Create a new theme.

    Args:
        db: Database session
        theme_data: Theme data

    Returns:
        Created Theme object
    """
    theme = Theme(**theme_data.model_dump())
    db.add(theme)
    await db.commit()
    await db.refresh(theme)
    return theme


async def update_theme(
    db: AsyncSession, theme_id: int, theme_data: ThemeUpdate
) -> Optional[Theme]:
    """
    Update theme.

    Args:
        db: Database session
        theme_id: Theme ID
        theme_data: Theme update data

    Returns:
        Updated Theme object if found, None otherwise
    """
    result = await db.execute(select(Theme).where(Theme.id == theme_id))
    theme = result.scalar_one_or_none()

    if not theme:
        return None

    # Update only provided fields
    update_data = theme_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(theme, field, value)

    await db.commit()
    await db.refresh(theme)
    return theme


async def delete_theme(db: AsyncSession, theme_id: int) -> bool:
    """
    Delete theme (soft delete by setting is_active=False).

    Args:
        db: Database session
        theme_id: Theme ID

    Returns:
        True if deleted, False if not found
    """
    result = await db.execute(select(Theme).where(Theme.id == theme_id))
    theme = result.scalar_one_or_none()

    if not theme:
        return False

    theme.is_active = False
    await db.commit()
    return True
