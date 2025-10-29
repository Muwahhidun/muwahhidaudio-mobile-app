"""
Books API endpoints.
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.content import BookResponse, BookWithRelations, BookCreate, BookUpdate
from app.crud import book as book_crud
from app.api.auth import get_current_user
from app.models import User

router = APIRouter(prefix="/books", tags=["Books"])


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Require admin role."""
    if current_user.role.level < 2:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user


@router.get("")
async def get_books(
    search: Optional[str] = Query(None, description="Search by name or description"),
    theme_id: Optional[int] = Query(None, description="Filter by theme ID"),
    author_id: Optional[int] = Query(None, description="Filter by author ID"),
    has_series: bool = Query(False, description="Filter books that have lesson series"),
    include_inactive: bool = Query(False, description="Include inactive books (admin only)"),
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of records to return"),
    db: AsyncSession = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user)
):
    """
    Get all books with optional search, filters, and pagination.

    Args:
        search: Search query for name or description (case-insensitive)
        theme_id: Filter by theme ID
        author_id: Filter by author ID
        include_inactive: Include inactive books (requires admin role)
        skip: Number of records to skip
        limit: Maximum number of records to return

    Returns dictionary with books list, total count, skip, and limit.
    For regular users, only active books are returned.
    For admins with include_inactive=true, all books are returned.
    """
    # Only admins can see inactive books
    can_see_inactive = include_inactive and current_user and current_user.role.level >= 2

    # Get total count
    total = await book_crud.count_books(
        db,
        search=search,
        theme_id=theme_id,
        author_id=author_id,
        has_series=has_series,
        include_inactive=can_see_inactive
    )

    # Get books
    books = await book_crud.get_all_books(
        db,
        search=search,
        theme_id=theme_id,
        author_id=author_id,
        has_series=has_series,
        include_inactive=can_see_inactive,
        skip=skip,
        limit=limit
    )

    return {
        "items": books,
        "total": total,
        "skip": skip,
        "limit": limit
    }


@router.get("/{book_id}", response_model=BookWithRelations)
async def get_book(book_id: int, db: AsyncSession = Depends(get_db)):
    """
    Get book by ID with theme and author info.

    Args:
        book_id: Book ID

    Returns:
        Book object with relations
    """
    book = await book_crud.get_book_by_id(db, book_id)

    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found"
        )

    return book


@router.post("", response_model=BookWithRelations, status_code=status.HTTP_201_CREATED)
async def create_book(
    book_data: BookCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Create a new book (Admin only).

    Args:
        book_data: Book creation data

    Returns:
        Created book object
    """
    book = await book_crud.create_book(db, book_data)
    return book


@router.put("/{book_id}", response_model=BookWithRelations)
async def update_book(
    book_id: int,
    book_data: BookUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Update book (Admin only).

    Args:
        book_id: Book ID
        book_data: Book update data

    Returns:
        Updated book object
    """
    book = await book_crud.update_book(db, book_id, book_data)

    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found"
        )

    return book


@router.delete("/{book_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_book(
    book_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Delete book (Admin only).

    Performs soft delete by setting is_active=False.

    Args:
        book_id: Book ID
    """
    deleted = await book_crud.delete_book(db, book_id)

    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found"
        )
