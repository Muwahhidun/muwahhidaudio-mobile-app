"""
Bookmark API endpoints.
User lesson bookmarks management.
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.database import get_db
from app.schemas.bookmark import (
    BookmarkCreate, BookmarkUpdate, BookmarkResponse, BookmarkWithLesson,
    SeriesWithBookmarkCount, BookmarkToggleRequest
)
from app.crud import bookmark as bookmark_crud
from app.crud import lesson as lesson_crud
from app.auth.dependencies import get_current_user
from app.models import User

router = APIRouter(prefix="/bookmarks", tags=["Bookmarks"])


@router.get("/series", response_model=dict)
async def get_bookmarked_series(
    skip: int = Query(0, ge=0, description="Skip records"),
    limit: int = Query(10, ge=1, le=100, description="Limit records"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get series that have bookmarked lessons (paginated).

    Returns series with bookmark count for current user.
    """
    # Get total count
    total = await bookmark_crud.count_bookmarked_series(db, current_user.id)

    # Get series with counts
    series_with_counts = await bookmark_crud.get_bookmarked_series(
        db=db,
        user_id=current_user.id,
        skip=skip,
        limit=limit
    )

    # Convert to response format
    items = []
    for series, count in series_with_counts:
        # Calculate display_name and lessons_count
        display_name = f"{series.year} - {series.name}"
        if series.teacher:
            display_name = f"{series.teacher.name} - {display_name}"

        series_dict = {
            'id': series.id,
            'name': series.name,
            'year': series.year,
            'display_name': display_name,
            'teacher_id': series.teacher_id,
            'book_id': series.book_id,
            'theme_id': series.theme_id,
            'is_active': series.is_active,
            'is_completed': series.is_completed,
            'description': series.description,
            'order': series.order,
            'created_at': series.created_at,
            'updated_at': series.updated_at,
            'teacher': {
                'id': series.teacher.id,
                'name': series.teacher.name
            } if series.teacher else None,
            'book': {
                'id': series.book.id,
                'name': series.book.name
            } if series.book else None,
            'theme': {
                'id': series.theme.id,
                'name': series.theme.name
            } if series.theme else None,
            'bookmarks_count': count
        }
        items.append(series_dict)

    return {
        'items': items,
        'total': total,
        'skip': skip,
        'limit': limit
    }


@router.get("/series/{series_id}", response_model=List[BookmarkWithLesson])
async def get_series_bookmarks(
    series_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get all bookmarks for a specific series.

    Returns bookmarks with full lesson details.
    """
    bookmarks = await bookmark_crud.get_bookmarks_by_series(
        db=db,
        user_id=current_user.id,
        series_id=series_id
    )

    # Format lesson details
    result = []
    for bookmark in bookmarks:
        lesson = bookmark.lesson
        lesson_data = {
            'id': bookmark.id,
            'user_id': bookmark.user_id,
            'lesson_id': bookmark.lesson_id,
            'custom_name': bookmark.custom_name,
            'created_at': bookmark.created_at,
            'updated_at': bookmark.updated_at,
            'lesson': {
                'id': lesson.id,
                'title': lesson.title,
                'description': lesson.description,
                'lesson_number': lesson.lesson_number,
                'duration_seconds': lesson.duration_seconds,
                'tags': lesson.tags,
                'is_active': lesson.is_active,
                'series_id': lesson.series_id,
                'book_id': lesson.book_id,
                'teacher_id': lesson.teacher_id,
                'theme_id': lesson.theme_id,
                'audio_file_path': lesson.audio_path,
                'waveform_data': lesson.waveform_data,
                'created_at': lesson.created_at,
                'updated_at': lesson.updated_at,
                'display_title': f"Урок {lesson.lesson_number}" if lesson.lesson_number else lesson.title,
                'formatted_duration': format_duration_helper(lesson.duration_seconds),
                'audio_url': f"/api/lessons/{lesson.id}/audio" if lesson.audio_path else None,
                'series': {
                    'id': lesson.series.id,
                    'name': lesson.series.name,
                    'year': lesson.series.year
                } if lesson.series else None,
                'teacher': {
                    'id': lesson.teacher.id,
                    'name': lesson.teacher.name
                } if lesson.teacher else None,
                'book': {
                    'id': lesson.book.id,
                    'name': lesson.book.name
                } if lesson.book else None,
                'theme': {
                    'id': lesson.theme.id,
                    'name': lesson.theme.name
                } if lesson.theme else None
            }
        }
        result.append(lesson_data)

    return result


@router.get("/check/{lesson_id}", response_model=BookmarkWithLesson | None)
async def check_bookmark(
    lesson_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Check if a lesson is bookmarked.

    Returns bookmark if exists, null otherwise.
    """
    bookmark = await bookmark_crud.check_bookmark(
        db=db,
        user_id=current_user.id,
        lesson_id=lesson_id
    )

    if not bookmark:
        return None

    return bookmark


@router.post("", response_model=BookmarkResponse, status_code=status.HTTP_201_CREATED)
async def create_bookmark(
    bookmark_data: BookmarkCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create a new bookmark.

    - **lesson_id**: ID of lesson to bookmark
    - **custom_name**: Optional note/name for bookmark (max 200 chars)
    """
    # Check if lesson exists
    lesson = await lesson_crud.get_lesson_by_id(db, bookmark_data.lesson_id)
    if not lesson:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesson not found"
        )

    # Check if already bookmarked
    existing = await bookmark_crud.check_bookmark(
        db=db,
        user_id=current_user.id,
        lesson_id=bookmark_data.lesson_id
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Lesson already bookmarked"
        )

    # Create bookmark
    bookmark = await bookmark_crud.create_bookmark(
        db=db,
        user_id=current_user.id,
        lesson_id=bookmark_data.lesson_id,
        custom_name=bookmark_data.custom_name
    )

    return bookmark


@router.put("/{bookmark_id}", response_model=BookmarkResponse)
async def update_bookmark(
    bookmark_id: int,
    update_data: BookmarkUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Update bookmark's custom name.

    User can only update their own bookmarks.
    """
    bookmark = await bookmark_crud.update_bookmark(
        db=db,
        bookmark_id=bookmark_id,
        user_id=current_user.id,
        custom_name=update_data.custom_name
    )

    if not bookmark:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Bookmark not found"
        )

    return bookmark


@router.delete("/{bookmark_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_bookmark(
    bookmark_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Delete a bookmark.

    User can only delete their own bookmarks.
    """
    deleted = await bookmark_crud.delete_bookmark(
        db=db,
        bookmark_id=bookmark_id,
        user_id=current_user.id
    )

    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Bookmark not found"
        )

    return None


@router.post("/toggle", response_model=dict)
async def toggle_bookmark(
    toggle_data: BookmarkToggleRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Toggle bookmark: add if doesn't exist, remove if exists.

    - **lesson_id**: ID of lesson to toggle
    - **custom_name**: Optional note/name if adding bookmark

    Returns: {"action": "added" | "removed", "bookmark": BookmarkResponse | null}
    """
    # Check if lesson exists
    lesson = await lesson_crud.get_lesson_by_id(db, toggle_data.lesson_id)
    if not lesson:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesson not found"
        )

    # Check if already bookmarked
    existing = await bookmark_crud.check_bookmark(
        db=db,
        user_id=current_user.id,
        lesson_id=toggle_data.lesson_id
    )

    if existing:
        # Remove bookmark
        await bookmark_crud.delete_bookmark_by_lesson(
            db=db,
            user_id=current_user.id,
            lesson_id=toggle_data.lesson_id
        )
        return {
            'action': 'removed',
            'bookmark': None
        }
    else:
        # Add bookmark
        bookmark = await bookmark_crud.create_bookmark(
            db=db,
            user_id=current_user.id,
            lesson_id=toggle_data.lesson_id,
            custom_name=toggle_data.custom_name
        )
        # Convert to dict for proper serialization
        bookmark_dict = {
            'id': bookmark.id,
            'user_id': bookmark.user_id,
            'lesson_id': bookmark.lesson_id,
            'custom_name': bookmark.custom_name,
            'created_at': bookmark.created_at,
            'updated_at': bookmark.updated_at
        }
        return {
            'action': 'added',
            'bookmark': bookmark_dict
        }


def format_duration_helper(seconds: int | None) -> str | None:
    """Helper to format duration in seconds to human-readable string."""
    if not seconds:
        return None

    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    secs = seconds % 60

    if hours > 0:
        return f"{hours}ч {minutes}м"
    elif minutes > 0:
        return f"{minutes}м {secs}с"
    else:
        return f"{secs}с"
