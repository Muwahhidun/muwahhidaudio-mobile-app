"""
CRUD operations for LessonSeries model.
"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models import LessonSeries
from app.schemas.lesson import LessonSeriesCreate, LessonSeriesUpdate


async def get_all_series(
    db: AsyncSession,
    search: Optional[str] = None,
    teacher_id: Optional[int] = None,
    book_id: Optional[int] = None,
    theme_id: Optional[int] = None,
    year: Optional[int] = None,
    is_completed: Optional[bool] = None
) -> List[LessonSeries]:
    """
    Get all series with relationships (including inactive for admin panel).

    Args:
        db: Database session
        search: Search by name or description
        teacher_id: Filter by teacher
        book_id: Filter by book
        theme_id: Filter by theme
        year: Filter by year
        is_completed: Filter by completion status

    Returns:
        List of LessonSeries objects
    """
    from sqlalchemy import or_

    query = select(LessonSeries)
    # ВРЕМЕННО УБРАН ФИЛЬТР для отладки админ-панели
    # .where(LessonSeries.is_active == True)

    # Apply search filter
    if search:
        search_term = f"%{search}%"
        query = query.where(
            or_(
                LessonSeries.name.ilike(search_term),
                LessonSeries.description.ilike(search_term)
            )
        )

    # Apply other filters
    if teacher_id is not None:
        query = query.where(LessonSeries.teacher_id == teacher_id)

    if book_id is not None:
        query = query.where(LessonSeries.book_id == book_id)

    if theme_id is not None:
        query = query.where(LessonSeries.theme_id == theme_id)

    if year is not None:
        query = query.where(LessonSeries.year == year)

    if is_completed is not None:
        query = query.where(LessonSeries.is_completed == is_completed)

    query = query.options(
        selectinload(LessonSeries.teacher),
        selectinload(LessonSeries.book),
        selectinload(LessonSeries.theme)
    ).order_by(LessonSeries.year.desc(), LessonSeries.order)

    result = await db.execute(query)
    return list(result.scalars().all())


async def create_series(db: AsyncSession, series_data: LessonSeriesCreate) -> LessonSeries:
    """
    Create a new lesson series.

    Args:
        db: Database session
        series_data: Series creation data

    Returns:
        Created LessonSeries object
    """
    series_dict = series_data.model_dump()

    # Если выбрана книга, автоматически установить theme_id из книги
    if series_dict.get('book_id'):
        from app.models import Book
        book_result = await db.execute(select(Book).where(Book.id == series_dict['book_id']))
        book = book_result.scalar_one_or_none()
        if book and book.theme_id:
            series_dict['theme_id'] = book.theme_id

    series = LessonSeries(**series_dict)
    db.add(series)
    await db.commit()
    await db.refresh(series)

    # Load relationships
    result = await db.execute(
        select(LessonSeries)
        .where(LessonSeries.id == series.id)
        .options(
            selectinload(LessonSeries.teacher),
            selectinload(LessonSeries.book),
            selectinload(LessonSeries.theme)
        )
    )
    series = result.scalar_one()

    return series


async def update_series(
    db: AsyncSession, series_id: int, series_data: LessonSeriesUpdate
) -> Optional[LessonSeries]:
    """
    Update a lesson series.

    Args:
        db: Database session
        series_id: Series ID
        series_data: Series update data

    Returns:
        Updated LessonSeries object if found, None otherwise
    """
    result = await db.execute(select(LessonSeries).where(LessonSeries.id == series_id))
    series = result.scalar_one_or_none()

    if not series:
        return None

    # Update only provided fields
    update_data = series_data.model_dump(exclude_unset=True)

    # Если изменяется book_id, автоматически обновить theme_id из книги
    if 'book_id' in update_data:
        if update_data['book_id']:
            from app.models import Book
            book_result = await db.execute(select(Book).where(Book.id == update_data['book_id']))
            book = book_result.scalar_one_or_none()
            if book and book.theme_id:
                update_data['theme_id'] = book.theme_id
        # Если book_id стал null, theme_id остается как есть (можно выбрать вручную)

    for field, value in update_data.items():
        setattr(series, field, value)

    await db.commit()
    await db.refresh(series)

    # Load relationships
    result = await db.execute(
        select(LessonSeries)
        .where(LessonSeries.id == series.id)
        .options(
            selectinload(LessonSeries.teacher),
            selectinload(LessonSeries.book),
            selectinload(LessonSeries.theme)
        )
    )
    series = result.scalar_one()

    return series


async def delete_series(db: AsyncSession, series_id: int) -> bool:
    """
    Delete a lesson series (soft delete by setting is_active=False).

    Args:
        db: Database session
        series_id: Series ID

    Returns:
        True if deleted, False if not found
    """
    result = await db.execute(select(LessonSeries).where(LessonSeries.id == series_id))
    series = result.scalar_one_or_none()

    if not series:
        return False

    series.is_active = False
    await db.commit()
    return True
