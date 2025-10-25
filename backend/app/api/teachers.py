"""
Teachers API endpoints.
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.api.auth import get_current_user
from app.models import User
from app.schemas.lesson import (
    LessonTeacherResponse,
    LessonTeacherCreate,
    LessonTeacherUpdate,
    LessonSeriesWithCounts
)
from app.crud import teacher as teacher_crud

router = APIRouter(prefix="/teachers", tags=["Teachers"])


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Require admin role."""
    if current_user.role.level < 2:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user


@router.get("", response_model=List[LessonTeacherResponse])
async def get_teachers(
    search: Optional[str] = Query(None, description="Search by name or biography"),
    include_inactive: bool = Query(False, description="Include inactive teachers (admin only)"),
    db: AsyncSession = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user)
):
    """
    Get all teachers with optional search.

    Returns list of teachers ordered by name.
    """
    can_see_inactive = include_inactive and current_user and current_user.role.level >= 2
    teachers = await teacher_crud.get_all_teachers(db, search=search, include_inactive=can_see_inactive)
    return teachers


@router.get("/{teacher_id}", response_model=LessonTeacherResponse)
async def get_teacher(teacher_id: int, db: AsyncSession = Depends(get_db)):
    """
    Get teacher by ID.

    Args:
        teacher_id: Teacher ID

    Returns:
        Teacher object
    """
    teacher = await teacher_crud.get_teacher_by_id(db, teacher_id)

    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher not found"
        )

    return teacher


@router.get("/{teacher_id}/series", response_model=List[LessonSeriesWithCounts])
async def get_teacher_series(teacher_id: int, db: AsyncSession = Depends(get_db)):
    """
    Get all series by teacher.

    Args:
        teacher_id: Teacher ID

    Returns:
        List of series with counts, ordered by year (newest first)
    """
    # Check if teacher exists
    teacher = await teacher_crud.get_teacher_by_id(db, teacher_id)
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher not found"
        )

    # Get series
    series_list = await teacher_crud.get_teacher_series(db, teacher_id)

    # For each series, add display_name
    result = []
    for series in series_list:
        series_dict = {
            **series.__dict__,
            "display_name": f"{series.year} - {series.name}",
            "lessons_count": 0  # TODO: Count lessons per series
        }
        result.append(LessonSeriesWithCounts(**series_dict))

    return result


@router.post("", response_model=LessonTeacherResponse, status_code=status.HTTP_201_CREATED)
async def create_teacher(
    teacher_data: LessonTeacherCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Create a new teacher (admin only).

    Args:
        teacher_data: Teacher creation data

    Returns:
        Created teacher object
    """
    teacher = await teacher_crud.create_teacher(db, teacher_data)
    return teacher


@router.put("/{teacher_id}", response_model=LessonTeacherResponse)
async def update_teacher(
    teacher_id: int,
    teacher_data: LessonTeacherUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Update a teacher (admin only).

    Args:
        teacher_id: Teacher ID
        teacher_data: Teacher update data

    Returns:
        Updated teacher object
    """
    teacher = await teacher_crud.update_teacher(db, teacher_id, teacher_data)

    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher not found"
        )

    return teacher


@router.delete("/{teacher_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_teacher(
    teacher_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Delete a teacher (soft delete, admin only).

    Args:
        teacher_id: Teacher ID
    """
    success = await teacher_crud.delete_teacher(db, teacher_id)

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher not found"
        )

    return None
