"""
Themes API endpoints.
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.content import ThemeResponse, ThemeWithCounts, ThemeCreate, ThemeUpdate
from app.crud import theme as theme_crud
from app.api.auth import get_current_user
from app.models import User

router = APIRouter(prefix="/themes", tags=["Themes"])


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Require admin role."""
    if current_user.role.level < 2:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user


@router.get("", response_model=List[ThemeResponse])
async def get_themes(
    search: Optional[str] = Query(None, description="Search by name or description"),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all active themes with optional search.

    Args:
        search: Search query for name or description (case-insensitive)

    Returns list of themes ordered by sort_order.
    """
    themes = await theme_crud.get_all_themes(db, search=search)
    return themes


@router.get("/{theme_id}", response_model=ThemeWithCounts)
async def get_theme(theme_id: int, db: AsyncSession = Depends(get_db)):
    """
    Get theme by ID with books and series counts.

    Args:
        theme_id: Theme ID

    Returns:
        Theme object with counts
    """
    result = await theme_crud.get_theme_with_counts(db, theme_id)

    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Theme not found"
        )

    theme = result["theme"]
    return ThemeWithCounts(
        **theme.__dict__,
        books_count=result["books_count"],
        series_count=result["series_count"]
    )


@router.post("", response_model=ThemeResponse, status_code=status.HTTP_201_CREATED)
async def create_theme(
    theme_data: ThemeCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Create a new theme (Admin only).

    Args:
        theme_data: Theme creation data

    Returns:
        Created theme object
    """
    theme = await theme_crud.create_theme(db, theme_data)
    return theme


@router.put("/{theme_id}", response_model=ThemeResponse)
async def update_theme(
    theme_id: int,
    theme_data: ThemeUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Update theme (Admin only).

    Args:
        theme_id: Theme ID
        theme_data: Theme update data

    Returns:
        Updated theme object
    """
    theme = await theme_crud.update_theme(db, theme_id, theme_data)

    if not theme:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Theme not found"
        )

    return theme


@router.delete("/{theme_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_theme(
    theme_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Delete theme (Admin only).

    Performs soft delete by setting is_active=False.

    Args:
        theme_id: Theme ID
    """
    deleted = await theme_crud.delete_theme(db, theme_id)

    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Theme not found"
        )
