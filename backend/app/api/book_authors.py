"""
Book Authors API endpoints.
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.content import BookAuthorResponse, BookAuthorCreate, BookAuthorUpdate
from app.crud import book_author as author_crud
from app.api.auth import get_current_user
from app.models import User

router = APIRouter(prefix="/book-authors", tags=["Book Authors"])


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Require admin role."""
    if current_user.role.level < 2:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user


@router.get("")
async def get_authors(
    search: Optional[str] = Query(None, description="Search by name or biography"),
    birth_year_from: Optional[int] = Query(None, description="Filter by birth year from"),
    birth_year_to: Optional[int] = Query(None, description="Filter by birth year to"),
    death_year_from: Optional[int] = Query(None, description="Filter by death year from"),
    death_year_to: Optional[int] = Query(None, description="Filter by death year to"),
    has_series: bool = Query(False, description="Filter authors whose books have lesson series"),
    include_inactive: bool = Query(False, description="Include inactive authors (admin only)"),
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of records to return"),
    db: AsyncSession = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user)
):
    """
    Get all book authors with optional search, filters, and pagination.

    Args:
        search: Search by name or biography
        birth_year_from: Filter by birth year from (inclusive)
        birth_year_to: Filter by birth year to (inclusive)
        death_year_from: Filter by death year from (inclusive)
        death_year_to: Filter by death year to (inclusive)
        include_inactive: Include inactive authors (requires admin role)
        skip: Number of records to skip
        limit: Maximum number of records to return

    Returns dictionary with authors list, total count, skip, and limit.
    For regular users, only active authors are returned.
    For admins with include_inactive=true, all authors are returned.
    """
    # Only admins can see inactive authors
    can_see_inactive = include_inactive and current_user and current_user.role.level >= 2

    # Get total count
    total = await author_crud.count_book_authors(db, search=search, has_series=has_series, include_inactive=can_see_inactive)

    # Get authors
    authors = await author_crud.get_all_authors(
        db,
        search=search,
        birth_year_from=birth_year_from,
        birth_year_to=birth_year_to,
        death_year_from=death_year_from,
        death_year_to=death_year_to,
        has_series=has_series,
        include_inactive=can_see_inactive,
        skip=skip,
        limit=limit
    )

    return {
        "items": authors,
        "total": total,
        "skip": skip,
        "limit": limit
    }


@router.get("/{author_id}", response_model=BookAuthorResponse)
async def get_author(author_id: int, db: AsyncSession = Depends(get_db)):
    """
    Get book author by ID.

    Args:
        author_id: Author ID

    Returns:
        Author object
    """
    author = await author_crud.get_author_by_id(db, author_id)

    if not author:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book author not found"
        )

    return author


@router.post("", response_model=BookAuthorResponse, status_code=status.HTTP_201_CREATED)
async def create_author(
    author_data: BookAuthorCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Create a new book author (Admin only).

    Args:
        author_data: Author creation data

    Returns:
        Created author object
    """
    author = await author_crud.create_author(db, author_data)
    return author


@router.put("/{author_id}", response_model=BookAuthorResponse)
async def update_author(
    author_id: int,
    author_data: BookAuthorUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Update book author (Admin only).

    Args:
        author_id: Author ID
        author_data: Author update data

    Returns:
        Updated author object
    """
    author = await author_crud.update_author(db, author_id, author_data)

    if not author:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book author not found"
        )

    return author


@router.delete("/{author_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_author(
    author_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Delete book author (Admin only).

    Performs soft delete by setting is_active=False.

    Args:
        author_id: Author ID
    """
    deleted = await author_crud.delete_author(db, author_id)

    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book author not found"
        )
