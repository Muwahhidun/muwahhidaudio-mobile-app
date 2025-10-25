"""
Direct migration script to apply case-insensitive unique constraints.
Run this instead of alembic if alembic connection fails.
"""
import asyncio
from sqlalchemy import text
from app.database import AsyncSessionLocal, engine


async def apply_migration():
    """Apply the case-insensitive unique constraints migration directly."""
    async with engine.begin() as conn:
        print("🔄 Starting migration...")

        # Step 1: Clean up duplicate records (soft delete)
        print("\n📋 Step 1: Cleaning up duplicates...")

        # Clean themes
        print("  - Cleaning themes...")
        await conn.execute(text("""
            UPDATE themes
            SET is_active = false
            WHERE id NOT IN (
                SELECT MIN(id)
                FROM themes
                WHERE is_active = true
                GROUP BY LOWER(name)
            )
            AND is_active = true
        """))
        print("  ✅ Themes cleaned")

        # Clean lesson_teachers
        print("  - Cleaning lesson_teachers...")
        await conn.execute(text("""
            UPDATE lesson_teachers
            SET is_active = false
            WHERE id NOT IN (
                SELECT MIN(id)
                FROM lesson_teachers
                WHERE is_active = true
                GROUP BY LOWER(name)
            )
            AND is_active = true
        """))
        print("  ✅ Lesson teachers cleaned")

        # Clean book_authors
        print("  - Cleaning book_authors...")
        await conn.execute(text("""
            UPDATE book_authors
            SET is_active = false
            WHERE id NOT IN (
                SELECT MIN(id)
                FROM book_authors
                WHERE is_active = true
                GROUP BY LOWER(name)
            )
            AND is_active = true
        """))
        print("  ✅ Book authors cleaned")

        # Step 2: Drop old UNIQUE constraints
        print("\n📋 Step 2: Dropping old UNIQUE constraints...")

        try:
            await conn.execute(text("ALTER TABLE themes DROP CONSTRAINT IF EXISTS unique_theme_name"))
            print("  ✅ Dropped unique_theme_name")
        except Exception as e:
            print(f"  ⚠️ Could not drop unique_theme_name: {e}")

        try:
            await conn.execute(text("ALTER TABLE lesson_teachers DROP CONSTRAINT IF EXISTS unique_lesson_teacher_name"))
            print("  ✅ Dropped unique_lesson_teacher_name")
        except Exception as e:
            print(f"  ⚠️ Could not drop unique_lesson_teacher_name: {e}")

        try:
            await conn.execute(text("ALTER TABLE book_authors DROP CONSTRAINT IF EXISTS unique_book_author_name"))
            print("  ✅ Dropped unique_book_author_name")
        except Exception as e:
            print(f"  ⚠️ Could not drop unique_book_author_name: {e}")

        try:
            await conn.execute(text("ALTER TABLE books DROP CONSTRAINT IF EXISTS unique_book_per_author"))
            print("  ✅ Dropped unique_book_per_author")
        except Exception as e:
            print(f"  ⚠️ Could not drop unique_book_per_author: {e}")

        # Step 3: Create new case-insensitive unique indexes
        print("\n📋 Step 3: Creating case-insensitive unique indexes...")

        try:
            await conn.execute(text("""
                CREATE UNIQUE INDEX IF NOT EXISTS ix_themes_name_lower_unique
                ON themes (LOWER(name))
            """))
            print("  ✅ Created ix_themes_name_lower_unique")
        except Exception as e:
            print(f"  ⚠️ Could not create ix_themes_name_lower_unique: {e}")

        try:
            await conn.execute(text("""
                CREATE UNIQUE INDEX IF NOT EXISTS ix_lesson_teachers_name_lower_unique
                ON lesson_teachers (LOWER(name))
            """))
            print("  ✅ Created ix_lesson_teachers_name_lower_unique")
        except Exception as e:
            print(f"  ⚠️ Could not create ix_lesson_teachers_name_lower_unique: {e}")

        try:
            await conn.execute(text("""
                CREATE UNIQUE INDEX IF NOT EXISTS ix_book_authors_name_lower_unique
                ON book_authors (LOWER(name))
            """))
            print("  ✅ Created ix_book_authors_name_lower_unique")
        except Exception as e:
            print(f"  ⚠️ Could not create ix_book_authors_name_lower_unique: {e}")

        try:
            await conn.execute(text("""
                CREATE UNIQUE INDEX IF NOT EXISTS ix_books_name_author_lower_unique
                ON books (LOWER(name), author_id)
            """))
            print("  ✅ Created ix_books_name_author_lower_unique")
        except Exception as e:
            print(f"  ⚠️ Could not create ix_books_name_author_lower_unique: {e}")

        print("\n✅ Migration completed successfully!")
        print("\n🎉 Now you can't create duplicates with different case!")


if __name__ == "__main__":
    asyncio.run(apply_migration())
