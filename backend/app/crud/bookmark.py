"""
CRUD operations for Bookmark model.
"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, distinct
from sqlalchemy.orm import selectinload

from app.models import Bookmark, Lesson, LessonSeries


async def count_bookmarked_series(db: AsyncSession, user_id: int) -> int:
    """
    Count number of unique series that have at least one bookmark for user.

    Args:
        db: Database session
        user_id: User ID

    Returns:
        Count of unique series with bookmarks
    """
    query = (
        select(func.count(distinct(Lesson.series_id)))
        .select_from(Bookmark)
        .join(Lesson, Bookmark.lesson_id == Lesson.id)
        .where(Bookmark.user_id == user_id)
    )

    result = await db.execute(query)
    return result.scalar_one()


async def get_bookmarked_series(
    db: AsyncSession,
    user_id: int,
    skip: int = 0,
    limit: int = 10
) -> List[tuple[LessonSeries, int]]:
    """
    Get list of series that have bookmarks for user, with bookmark counts.
    Returns tuples of (LessonSeries, bookmarks_count).

    Args:
        db: Database session
        user_id: User ID
        skip: Pagination offset
        limit: Max results

    Returns:
        List of (LessonSeries, bookmarks_count) tuples
    """
    # Get series IDs with bookmark counts
    subquery = (
        select(
            Lesson.series_id,
            func.count(Bookmark.id).label('bookmarks_count')
        )
        .select_from(Bookmark)
        .join(Lesson, Bookmark.lesson_id == Lesson.id)
        .where(Bookmark.user_id == user_id)
        .group_by(Lesson.series_id)
        .subquery()
    )

    # Get full series objects with counts
    query = (
        select(LessonSeries, subquery.c.bookmarks_count)
        .join(subquery, LessonSeries.id == subquery.c.series_id)
        .options(
            selectinload(LessonSeries.teacher),
            selectinload(LessonSeries.book),
            selectinload(LessonSeries.theme)
        )
        .order_by(LessonSeries.year.desc(), LessonSeries.order)
        .offset(skip)
        .limit(limit)
    )

    result = await db.execute(query)
    return list(result.all())


async def get_bookmarks_by_series(
    db: AsyncSession,
    user_id: int,
    series_id: int
) -> List[Bookmark]:
    """
    Get all bookmarks for a specific series.

    Args:
        db: Database session
        user_id: User ID
        series_id: Series ID

    Returns:
        List of Bookmark objects with lesson details
    """
    query = (
        select(Bookmark)
        .join(Lesson, Bookmark.lesson_id == Lesson.id)
        .where(
            Bookmark.user_id == user_id,
            Lesson.series_id == series_id
        )
        .options(
            selectinload(Bookmark.lesson).selectinload(Lesson.series),
            selectinload(Bookmark.lesson).selectinload(Lesson.teacher),
            selectinload(Bookmark.lesson).selectinload(Lesson.book),
            selectinload(Bookmark.lesson).selectinload(Lesson.theme)
        )
        .order_by(Lesson.lesson_number)
    )

    result = await db.execute(query)
    return list(result.scalars().all())


async def check_bookmark(
    db: AsyncSession,
    user_id: int,
    lesson_id: int
) -> Optional[Bookmark]:
    """
    Check if a lesson is bookmarked by user.

    Args:
        db: Database session
        user_id: User ID
        lesson_id: Lesson ID

    Returns:
        Bookmark object if exists, None otherwise
    """
    query = (
        select(Bookmark)
        .where(
            Bookmark.user_id == user_id,
            Bookmark.lesson_id == lesson_id
        )
        .options(
            selectinload(Bookmark.lesson).selectinload(Lesson.series),
            selectinload(Bookmark.lesson).selectinload(Lesson.teacher),
            selectinload(Bookmark.lesson).selectinload(Lesson.book),
            selectinload(Bookmark.lesson).selectinload(Lesson.theme)
        )
    )

    result = await db.execute(query)
    return result.scalar_one_or_none()


async def create_bookmark(
    db: AsyncSession,
    user_id: int,
    lesson_id: int,
    custom_name: Optional[str] = None
) -> Bookmark:
    """
    Create a new bookmark.

    Args:
        db: Database session
        user_id: User ID
        lesson_id: Lesson ID
        custom_name: Optional custom note/name

    Returns:
        Created Bookmark object
    """
    bookmark = Bookmark(
        user_id=user_id,
        lesson_id=lesson_id,
        custom_name=custom_name
    )

    db.add(bookmark)
    await db.commit()
    await db.refresh(bookmark)

    # Load relationships
    await db.refresh(
        bookmark,
        ['lesson']
    )

    return bookmark


async def update_bookmark(
    db: AsyncSession,
    bookmark_id: int,
    user_id: int,
    custom_name: Optional[str] = None
) -> Optional[Bookmark]:
    """
    Update bookmark's custom name.

    Args:
        db: Database session
        bookmark_id: Bookmark ID
        user_id: User ID (for security check)
        custom_name: New custom name

    Returns:
        Updated Bookmark or None if not found
    """
    query = select(Bookmark).where(
        Bookmark.id == bookmark_id,
        Bookmark.user_id == user_id
    )

    result = await db.execute(query)
    bookmark = result.scalar_one_or_none()

    if not bookmark:
        return None

    bookmark.custom_name = custom_name
    await db.commit()
    await db.refresh(bookmark)

    return bookmark


async def delete_bookmark(
    db: AsyncSession,
    bookmark_id: int,
    user_id: int
) -> bool:
    """
    Delete a bookmark by ID.

    Args:
        db: Database session
        bookmark_id: Bookmark ID
        user_id: User ID (for security check)

    Returns:
        True if deleted, False if not found
    """
    query = select(Bookmark).where(
        Bookmark.id == bookmark_id,
        Bookmark.user_id == user_id
    )

    result = await db.execute(query)
    bookmark = result.scalar_one_or_none()

    if not bookmark:
        return False

    await db.delete(bookmark)
    await db.commit()

    return True


async def delete_bookmark_by_lesson(
    db: AsyncSession,
    user_id: int,
    lesson_id: int
) -> bool:
    """
    Delete a bookmark by lesson ID.

    Args:
        db: Database session
        user_id: User ID
        lesson_id: Lesson ID

    Returns:
        True if deleted, False if not found
    """
    query = select(Bookmark).where(
        Bookmark.user_id == user_id,
        Bookmark.lesson_id == lesson_id
    )

    result = await db.execute(query)
    bookmark = result.scalar_one_or_none()

    if not bookmark:
        return False

    await db.delete(bookmark)
    await db.commit()

    return True
