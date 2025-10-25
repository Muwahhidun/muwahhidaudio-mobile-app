"""
Migration API endpoint (admin only).
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from app.database import get_db
from app.api.auth import get_current_user
from app.models import User

router = APIRouter(prefix="/migration", tags=["Migration"])


@router.get("/check-duplicates")
async def check_duplicates(db: AsyncSession = Depends(get_db)):
    """Check for case-insensitive duplicates in the database."""
    # Check themes (INCLUDING inactive ones!)
    result = await db.execute(text("""
        SELECT LOWER(name) as name_lower, COUNT(*) as count, string_agg(CAST(id AS TEXT) || '(' || CAST(is_active AS TEXT) || ')', ', ') as ids
        FROM themes
        GROUP BY LOWER(name)
        HAVING COUNT(*) > 1
    """))
    theme_dups = [{"name": row[0], "count": row[1], "ids": row[2]} for row in result]

    # Check teachers
    result = await db.execute(text("""
        SELECT LOWER(name) as name_lower, COUNT(*) as count, string_agg(CAST(id AS TEXT), ', ') as ids
        FROM lesson_teachers
        WHERE is_active = true
        GROUP BY LOWER(name)
        HAVING COUNT(*) > 1
    """))
    teacher_dups = [{"name": row[0], "count": row[1], "ids": row[2]} for row in result]

    # Check authors
    result = await db.execute(text("""
        SELECT LOWER(name) as name_lower, COUNT(*) as count, string_agg(CAST(id AS TEXT), ', ') as ids
        FROM book_authors
        WHERE is_active = true
        GROUP BY LOWER(name)
        HAVING COUNT(*) > 1
    """))
    author_dups = [{"name": row[0], "count": row[1], "ids": row[2]} for row in result]

    return {
        "themes": theme_dups,
        "teachers": teacher_dups,
        "authors": author_dups
    }


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Require admin role."""
    if current_user.role.level < 2:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user


@router.post("/apply-case-insensitive")
async def apply_case_insensitive_migration(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Apply case-insensitive unique constraints migration.
    This will:
    1. Soft-delete duplicate records (keeping lowest ID)
    2. Drop old case-sensitive unique constraints
    3. Create new case-insensitive unique indexes
    """
    try:
        # Step 1: Clean up duplicates using CTE
        # Themes
        result = await db.execute(text("""
            WITH keep_ids AS (
                SELECT MIN(id) as id
                FROM themes
                WHERE is_active = true
                GROUP BY LOWER(name)
            )
            UPDATE themes
            SET is_active = false
            WHERE is_active = true
            AND id NOT IN (SELECT id FROM keep_ids)
        """))
        themes_updated = result.rowcount
        await db.flush()  # Flush to make changes visible within transaction

        # Lesson teachers
        result = await db.execute(text("""
            WITH keep_ids AS (
                SELECT MIN(id) as id
                FROM lesson_teachers
                WHERE is_active = true
                GROUP BY LOWER(name)
            )
            UPDATE lesson_teachers
            SET is_active = false
            WHERE is_active = true
            AND id NOT IN (SELECT id FROM keep_ids)
        """))
        teachers_updated = result.rowcount
        await db.flush()

        # Book authors
        result = await db.execute(text("""
            WITH keep_ids AS (
                SELECT MIN(id) as id
                FROM book_authors
                WHERE is_active = true
                GROUP BY LOWER(name)
            )
            UPDATE book_authors
            SET is_active = false
            WHERE is_active = true
            AND id NOT IN (SELECT id FROM keep_ids)
        """))
        authors_updated = result.rowcount
        await db.flush()

        # Lesson series (by year, name, teacher_id)
        result = await db.execute(text("""
            WITH keep_ids AS (
                SELECT MIN(id) as id
                FROM lesson_series
                WHERE is_active = true
                GROUP BY year, LOWER(name), teacher_id
            )
            UPDATE lesson_series
            SET is_active = false
            WHERE is_active = true
            AND id NOT IN (SELECT id FROM keep_ids)
        """))
        series_updated = result.rowcount
        await db.flush()

        # Step 2: Drop old constraints (ignore errors if they don't exist)
        try:
            await db.execute(text("ALTER TABLE themes DROP CONSTRAINT IF EXISTS unique_theme_name"))
        except:
            pass

        try:
            await db.execute(text("ALTER TABLE lesson_teachers DROP CONSTRAINT IF EXISTS unique_lesson_teacher_name"))
        except:
            pass

        try:
            await db.execute(text("ALTER TABLE book_authors DROP CONSTRAINT IF EXISTS unique_book_author_name"))
        except:
            pass

        try:
            await db.execute(text("ALTER TABLE books DROP CONSTRAINT IF EXISTS unique_book_per_author"))
        except:
            pass

        try:
            await db.execute(text("ALTER TABLE lesson_series DROP CONSTRAINT IF EXISTS unique_series_per_teacher"))
        except:
            pass

        # Step 3: Create case-insensitive PARTIAL indexes (only for active records)
        await db.execute(text("""
            CREATE UNIQUE INDEX IF NOT EXISTS ix_themes_name_lower_unique
            ON themes (LOWER(name))
            WHERE is_active = true
        """))

        await db.execute(text("""
            CREATE UNIQUE INDEX IF NOT EXISTS ix_lesson_teachers_name_lower_unique
            ON lesson_teachers (LOWER(name))
            WHERE is_active = true
        """))

        await db.execute(text("""
            CREATE UNIQUE INDEX IF NOT EXISTS ix_book_authors_name_lower_unique
            ON book_authors (LOWER(name))
            WHERE is_active = true
        """))

        # First drop the old index if it exists
        try:
            await db.execute(text("DROP INDEX IF EXISTS ix_books_name_author_lower_unique"))
        except:
            pass

        # Create index with COALESCE to handle NULL author_id
        await db.execute(text("""
            CREATE UNIQUE INDEX IF NOT EXISTS ix_books_name_author_lower_unique
            ON books (LOWER(name), COALESCE(author_id, -1))
            WHERE is_active = true
        """))

        # Series: case-insensitive unique by (year, name, teacher_id)
        await db.execute(text("""
            CREATE UNIQUE INDEX IF NOT EXISTS ix_series_year_name_teacher_lower_unique
            ON lesson_series (year, LOWER(name), teacher_id)
            WHERE is_active = true
        """))

        await db.commit()

        return {
            "status": "success",
            "message": "Case-insensitive unique constraints applied successfully. Duplicates have been soft-deleted.",
            "duplicates_removed": {
                "themes": themes_updated,
                "lesson_teachers": teachers_updated,
                "book_authors": authors_updated,
                "lesson_series": series_updated
            }
        }

    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Migration failed: {str(e)}"
        )
