"""
CRUD operations for Book model.
"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_
from sqlalchemy.orm import selectinload

from app.models import Book
from app.schemas.content import BookCreate, BookUpdate


async def count_books(
    db: AsyncSession,
    search: Optional[str] = None,
    theme_id: Optional[int] = None,
    author_id: Optional[int] = None,
    include_inactive: bool = False
) -> int:
    """
    Count total number of books with filters.

    Args:
        db: Database session
        search: Search query for name or description
        theme_id: Filter by theme ID
        author_id: Filter by author ID
        include_inactive: Include inactive books (for admin)

    Returns:
        Total count of books matching filters
    """
    query = select(func.count(Book.id))

    if not include_inactive:
        query = query.where(Book.is_active == True)

    if search:
        search_term = f"%{search}%"
        query = query.where(
            or_(
                Book.name.ilike(search_term),
                Book.description.ilike(search_term)
            )
        )

    if theme_id is not None:
        query = query.where(Book.theme_id == theme_id)

    if author_id is not None:
        query = query.where(Book.author_id == author_id)

    result = await db.execute(query)
    return result.scalar_one()


async def get_all_books(
    db: AsyncSession,
    search: Optional[str] = None,
    theme_id: Optional[int] = None,
    author_id: Optional[int] = None,
    include_inactive: bool = False,
    skip: int = 0,
    limit: int = 100
) -> List[Book]:
    """
    Get all books with optional search, filters, and pagination.

    Args:
        db: Database session
        search: Search query for name or description (case-insensitive)
        theme_id: Filter by theme ID
        author_id: Filter by author ID
        include_inactive: Include inactive books (for admin)
        skip: Number of records to skip
        limit: Maximum number of records to return

    Returns:
        List of Book objects
    """
    query = (
        select(Book)
        .options(selectinload(Book.theme), selectinload(Book.author))
    )

    # Filter by active status unless include_inactive is True
    if not include_inactive:
        query = query.where(Book.is_active == True)

    # Add search filter if provided
    if search:
        search_term = f"%{search}%"
        query = query.where(
            or_(
                Book.name.ilike(search_term),
                Book.description.ilike(search_term)
            )
        )

    # Add theme filter if provided
    if theme_id is not None:
        query = query.where(Book.theme_id == theme_id)

    # Add author filter if provided
    if author_id is not None:
        query = query.where(Book.author_id == author_id)

    query = query.order_by(Book.sort_order, Book.name).offset(skip).limit(limit)
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_book_by_id(db: AsyncSession, book_id: int) -> Optional[Book]:
    """
    Get book by ID with relations.

    Args:
        db: Database session
        book_id: Book ID

    Returns:
        Book object if found, None otherwise
    """
    result = await db.execute(
        select(Book)
        .where(Book.id == book_id)
        .options(selectinload(Book.theme), selectinload(Book.author))
    )
    return result.scalar_one_or_none()


async def create_book(db: AsyncSession, book_data: BookCreate) -> Book:
    """
    Create a new book.

    Args:
        db: Database session
        book_data: Book data

    Returns:
        Created Book object
    """
    book = Book(**book_data.model_dump())
    db.add(book)
    await db.commit()
    await db.refresh(book)

    # Load relationships
    result = await db.execute(
        select(Book)
        .where(Book.id == book.id)
        .options(selectinload(Book.theme), selectinload(Book.author))
    )
    book = result.scalar_one()

    return book


async def update_book(
    db: AsyncSession, book_id: int, book_data: BookUpdate
) -> Optional[Book]:
    """
    Update book.

    Args:
        db: Database session
        book_id: Book ID
        book_data: Book update data

    Returns:
        Updated Book object if found, None otherwise
    """
    result = await db.execute(select(Book).where(Book.id == book_id))
    book = result.scalar_one_or_none()

    if not book:
        return None

    # Update only provided fields
    update_data = book_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(book, field, value)

    await db.commit()
    await db.refresh(book)

    # Load relationships
    result = await db.execute(
        select(Book)
        .where(Book.id == book.id)
        .options(selectinload(Book.theme), selectinload(Book.author))
    )
    book = result.scalar_one()

    return book


async def delete_book(db: AsyncSession, book_id: int) -> bool:
    """
    Delete book (soft delete by setting is_active=False).

    Args:
        db: Database session
        book_id: Book ID

    Returns:
        True if deleted, False if not found
    """
    result = await db.execute(select(Book).where(Book.id == book_id))
    book = result.scalar_one_or_none()

    if not book:
        return False

    book.is_active = False
    await db.commit()
    return True
