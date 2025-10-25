"""
CRUD operations for BookAuthor model.
"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_

from app.models import BookAuthor
from app.schemas.content import BookAuthorCreate, BookAuthorUpdate


async def get_all_authors(
    db: AsyncSession,
    search: Optional[str] = None,
    birth_year_from: Optional[int] = None,
    birth_year_to: Optional[int] = None,
    death_year_from: Optional[int] = None,
    death_year_to: Optional[int] = None,
    include_inactive: bool = False
) -> List[BookAuthor]:
    """
    Get all book authors with optional search and filters.

    Args:
        db: Database session
        search: Search by name or biography
        birth_year_from: Filter by birth year from (inclusive)
        birth_year_to: Filter by birth year to (inclusive)
        death_year_from: Filter by death year from (inclusive)
        death_year_to: Filter by death year to (inclusive)
        include_inactive: Include inactive authors (for admin)

    Returns:
        List of BookAuthor objects
    """
    query = select(BookAuthor)

    if not include_inactive:
        query = query.where(BookAuthor.is_active == True)

    # Apply search filter
    if search:
        search_term = f"%{search}%"
        query = query.where(
            or_(
                BookAuthor.name.ilike(search_term),
                BookAuthor.biography.ilike(search_term)
            )
        )

    # Apply birth year filters
    if birth_year_from is not None:
        query = query.where(BookAuthor.birth_year >= birth_year_from)
    if birth_year_to is not None:
        query = query.where(BookAuthor.birth_year <= birth_year_to)

    # Apply death year filters
    if death_year_from is not None:
        query = query.where(BookAuthor.death_year >= death_year_from)
    if death_year_to is not None:
        query = query.where(BookAuthor.death_year <= death_year_to)

    query = query.order_by(BookAuthor.name)
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_author_by_id(db: AsyncSession, author_id: int) -> Optional[BookAuthor]:
    """
    Get book author by ID.

    Args:
        db: Database session
        author_id: Author ID

    Returns:
        BookAuthor object if found, None otherwise
    """
    result = await db.execute(
        select(BookAuthor).where(BookAuthor.id == author_id)
    )
    return result.scalar_one_or_none()


async def create_author(db: AsyncSession, author_data: BookAuthorCreate) -> BookAuthor:
    """
    Create a new book author.

    Args:
        db: Database session
        author_data: Author data

    Returns:
        Created BookAuthor object
    """
    author = BookAuthor(**author_data.model_dump())
    db.add(author)
    await db.commit()
    await db.refresh(author)
    return author


async def update_author(
    db: AsyncSession, author_id: int, author_data: BookAuthorUpdate
) -> Optional[BookAuthor]:
    """
    Update book author.

    Args:
        db: Database session
        author_id: Author ID
        author_data: Author update data

    Returns:
        Updated BookAuthor object if found, None otherwise
    """
    result = await db.execute(select(BookAuthor).where(BookAuthor.id == author_id))
    author = result.scalar_one_or_none()

    if not author:
        return None

    # Update only provided fields
    update_data = author_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(author, field, value)

    await db.commit()
    await db.refresh(author)

    return author


async def delete_author(db: AsyncSession, author_id: int) -> bool:
    """
    Delete book author (soft delete by setting is_active=False).

    Args:
        db: Database session
        author_id: Author ID

    Returns:
        True if deleted, False if not found
    """
    result = await db.execute(select(BookAuthor).where(BookAuthor.id == author_id))
    author = result.scalar_one_or_none()

    if not author:
        return False

    author.is_active = False
    await db.commit()
    return True
