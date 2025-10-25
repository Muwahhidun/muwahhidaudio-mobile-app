"""
Script to clean up duplicate records that differ only by case.
Keeps the first record (by id) and soft-deletes others.
"""
import asyncio
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.models import Theme, LessonTeacher, BookAuthor


async def clean_theme_duplicates(db: AsyncSession):
    """Clean duplicate themes (case-insensitive)."""
    print("\n=== Cleaning Theme duplicates ===")

    # Get all active themes
    result = await db.execute(
        select(Theme).where(Theme.is_active == True).order_by(Theme.id)
    )
    themes = list(result.scalars().all())

    # Track seen names (lowercase)
    seen = {}
    duplicates_removed = 0

    for theme in themes:
        name_lower = theme.name.lower()

        if name_lower in seen:
            # This is a duplicate - soft delete it
            print(f"  Removing duplicate: '{theme.name}' (id={theme.id}) - keeping '{seen[name_lower].name}' (id={seen[name_lower].id})")
            theme.is_active = False
            duplicates_removed += 1
        else:
            seen[name_lower] = theme

    await db.commit()
    print(f"  Removed {duplicates_removed} duplicate themes")


async def clean_teacher_duplicates(db: AsyncSession):
    """Clean duplicate teachers (case-insensitive)."""
    print("\n=== Cleaning Teacher duplicates ===")

    # Get all active teachers
    result = await db.execute(
        select(LessonTeacher).where(LessonTeacher.is_active == True).order_by(LessonTeacher.id)
    )
    teachers = list(result.scalars().all())

    # Track seen names (lowercase)
    seen = {}
    duplicates_removed = 0

    for teacher in teachers:
        name_lower = teacher.name.lower()

        if name_lower in seen:
            # This is a duplicate - soft delete it
            print(f"  Removing duplicate: '{teacher.name}' (id={teacher.id}) - keeping '{seen[name_lower].name}' (id={seen[name_lower].id})")
            teacher.is_active = False
            duplicates_removed += 1
        else:
            seen[name_lower] = teacher

    await db.commit()
    print(f"  Removed {duplicates_removed} duplicate teachers")


async def clean_author_duplicates(db: AsyncSession):
    """Clean duplicate book authors (case-insensitive)."""
    print("\n=== Cleaning Book Author duplicates ===")

    # Get all active authors
    result = await db.execute(
        select(BookAuthor).where(BookAuthor.is_active == True).order_by(BookAuthor.id)
    )
    authors = list(result.scalars().all())

    # Track seen names (lowercase)
    seen = {}
    duplicates_removed = 0

    for author in authors:
        name_lower = author.name.lower()

        if name_lower in seen:
            # This is a duplicate - soft delete it
            print(f"  Removing duplicate: '{author.name}' (id={author.id}) - keeping '{seen[name_lower].name}' (id={seen[name_lower].id})")
            author.is_active = False
            duplicates_removed += 1
        else:
            seen[name_lower] = author

    await db.commit()
    print(f"  Removed {duplicates_removed} duplicate authors")


async def main():
    """Main function to clean all duplicates."""
    print("Starting duplicate cleanup...")

    async with AsyncSessionLocal() as db:
        await clean_theme_duplicates(db)
        await clean_teacher_duplicates(db)
        await clean_author_duplicates(db)

    print("\n✓ Duplicate cleanup completed!")


if __name__ == "__main__":
    asyncio.run(main())
