"""
Series API endpoints.
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.api.auth import get_current_user
from app.models import User
from app.schemas.lesson import (
    LessonSeriesWithCounts,
    LessonSeriesWithRelations,
    LessonSeriesCreate,
    LessonSeriesUpdate,
    LessonListItem
)
from app.crud import teacher as teacher_crud
from app.crud import lesson as lesson_crud
from app.crud import series as series_crud

router = APIRouter(prefix="/series", tags=["Series"])


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Require admin role."""
    if current_user.role.level < 2:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user


@router.get("")
async def get_all_series(
    search: Optional[str] = Query(None, description="Search by name or description"),
    teacher_id: Optional[int] = Query(None, description="Filter by teacher ID"),
    book_id: Optional[int] = Query(None, description="Filter by book ID"),
    theme_id: Optional[int] = Query(None, description="Filter by theme ID"),
    year: Optional[int] = Query(None, description="Filter by year"),
    is_completed: Optional[bool] = Query(None, description="Filter by completion status"),
    include_inactive: bool = Query(False, description="Include inactive series (admin only)"),
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of records to return"),
    db: AsyncSession = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user)
):
    """
    Get all series with relationships and pagination.

    Args:
        search: Search query for name or description (case-insensitive)
        teacher_id: Filter by teacher ID
        book_id: Filter by book ID
        theme_id: Filter by theme ID
        year: Filter by year
        is_completed: Filter by completion status
        include_inactive: Include inactive series (requires admin role)
        skip: Number of records to skip
        limit: Maximum number of records to return

    Returns dictionary with series list, total count, skip, and limit.
    Series are ordered by year (newest first) and order.
    For regular users, only active series are returned.
    For admins with include_inactive=true, all series are returned.
    """
    can_see_inactive = include_inactive and current_user and current_user.role.level >= 2

    # Get total count
    total = await series_crud.count_series(
        db,
        search=search,
        teacher_id=teacher_id,
        book_id=book_id,
        theme_id=theme_id,
        year=year,
        is_completed=is_completed,
        include_inactive=can_see_inactive
    )

    # Get series
    series_list = await series_crud.get_all_series(
        db,
        search=search,
        teacher_id=teacher_id,
        book_id=book_id,
        theme_id=theme_id,
        year=year,
        is_completed=is_completed,
        include_inactive=can_see_inactive,
        skip=skip,
        limit=limit
    )

    # Add display_name to each series
    items = []
    for series in series_list:
        series_dict = {
            "id": series.id,
            "name": series.name,
            "year": series.year,
            "description": series.description,
            "teacher_id": series.teacher_id,
            "book_id": series.book_id,
            "theme_id": series.theme_id,
            "is_completed": series.is_completed,
            "order": series.order,
            "is_active": series.is_active,
            "created_at": series.created_at,
            "updated_at": series.updated_at,
            "teacher": series.teacher,
            "book": series.book,
            "theme": series.theme,
            "display_name": f"{series.year} - {series.name}"
        }
        items.append(LessonSeriesWithRelations(**series_dict))

    return {
        "items": items,
        "total": total,
        "skip": skip,
        "limit": limit
    }


@router.post("", response_model=LessonSeriesWithRelations, status_code=status.HTTP_201_CREATED)
async def create_series(
    series_data: LessonSeriesCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Create a new series (admin only).

    Args:
        series_data: Series creation data

    Returns:
        Created series object with relationships
    """
    series = await series_crud.create_series(db, series_data)

    return LessonSeriesWithRelations(
        id=series.id,
        name=series.name,
        year=series.year,
        description=series.description,
        teacher_id=series.teacher_id,
        book_id=series.book_id,
        theme_id=series.theme_id,
        is_completed=series.is_completed,
        order=series.order,
        is_active=series.is_active,
        created_at=series.created_at,
        updated_at=series.updated_at,
        teacher=series.teacher,
        book=series.book,
        theme=series.theme,
        display_name=f"{series.year} - {series.name}"
    )


@router.put("/{series_id}", response_model=LessonSeriesWithRelations)
async def update_series(
    series_id: int,
    series_data: LessonSeriesUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Update a series (admin only).

    Args:
        series_id: Series ID
        series_data: Series update data

    Returns:
        Updated series object with relationships
    """
    series = await series_crud.update_series(db, series_id, series_data)

    if not series:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Series not found"
        )

    return LessonSeriesWithRelations(
        id=series.id,
        name=series.name,
        year=series.year,
        description=series.description,
        teacher_id=series.teacher_id,
        book_id=series.book_id,
        theme_id=series.theme_id,
        is_completed=series.is_completed,
        order=series.order,
        is_active=series.is_active,
        created_at=series.created_at,
        updated_at=series.updated_at,
        teacher=series.teacher,
        book=series.book,
        theme=series.theme,
        display_name=f"{series.year} - {series.name}"
    )


@router.delete("/{series_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_series(
    series_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Delete a series (soft delete, admin only).

    Args:
        series_id: Series ID
    """
    success = await series_crud.delete_series(db, series_id)

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Series not found"
        )

    return None


@router.get("/{series_id}", response_model=LessonSeriesWithCounts)
async def get_series(series_id: int, db: AsyncSession = Depends(get_db)):
    """
    Get series by ID with stats.

    Args:
        series_id: Series ID

    Returns:
        Series object with lessons count and total duration
    """
    result = await teacher_crud.get_series_with_stats(db, series_id)

    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Series not found"
        )

    series = result["series"]
    return LessonSeriesWithCounts(
        id=series.id,
        name=series.name,
        year=series.year,
        description=series.description,
        teacher_id=series.teacher_id,
        book_id=series.book_id,
        theme_id=series.theme_id,
        is_completed=series.is_completed,
        order=series.order,
        is_active=series.is_active,
        created_at=series.created_at,
        updated_at=series.updated_at,
        teacher=series.teacher,
        book=series.book,
        theme=series.theme,
        display_name=f"{series.year} - {series.name}",
        lessons_count=result["lessons_count"],
        total_duration=result["total_duration"]
    )


@router.get("/{series_id}/lessons", response_model=List[LessonListItem])
async def get_series_lessons(series_id: int, db: AsyncSession = Depends(get_db)):
    """
    Get all lessons in a series.

    Args:
        series_id: Series ID

    Returns:
        List of lessons ordered by lesson_number
    """
    # Check if series exists
    series = await teacher_crud.get_series_by_id(db, series_id)
    if not series:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Series not found"
        )

    # Get lessons
    lessons = await teacher_crud.get_series_lessons(db, series_id)

    # Format lessons for response
    result = []
    for lsn in lessons:
        result.append(LessonListItem(
            id=lsn.id,
            lesson_number=lsn.lesson_number,
            display_title=lesson_crud.get_display_title(lsn),
            duration_seconds=lsn.duration_seconds,
            formatted_duration=lesson_crud.format_duration(lsn.duration_seconds),
            audio_url=lesson_crud.get_audio_url(lsn.id),
            waveform_data=lsn.waveform_data,
            teacher=lsn.teacher,
            book=lsn.book
        ))

    return result
