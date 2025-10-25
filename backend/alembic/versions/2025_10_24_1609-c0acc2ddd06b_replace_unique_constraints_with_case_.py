"""replace_unique_constraints_with_case_insensitive

Revision ID: c0acc2ddd06b
Revises: fb6b2e951ff1
Create Date: 2025-10-24 16:09:56.399346

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c0acc2ddd06b'
down_revision: Union[str, None] = 'fb6b2e951ff1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Step 1: Clean up duplicate records (soft delete)
    # Keep the record with the lowest ID for each case-insensitive duplicate

    # Clean themes
    op.execute("""
        UPDATE themes
        SET is_active = false
        WHERE id NOT IN (
            SELECT MIN(id)
            FROM themes
            WHERE is_active = true
            GROUP BY LOWER(name)
        )
        AND is_active = true
    """)

    # Clean lesson_teachers
    op.execute("""
        UPDATE lesson_teachers
        SET is_active = false
        WHERE id NOT IN (
            SELECT MIN(id)
            FROM lesson_teachers
            WHERE is_active = true
            GROUP BY LOWER(name)
        )
        AND is_active = true
    """)

    # Clean book_authors
    op.execute("""
        UPDATE book_authors
        SET is_active = false
        WHERE id NOT IN (
            SELECT MIN(id)
            FROM book_authors
            WHERE is_active = true
            GROUP BY LOWER(name)
        )
        AND is_active = true
    """)

    # Step 2: Drop old UNIQUE constraints
    op.drop_constraint('unique_theme_name', 'themes', type_='unique')
    op.drop_constraint('unique_lesson_teacher_name', 'lesson_teachers', type_='unique')
    op.drop_constraint('unique_book_author_name', 'book_authors', type_='unique')
    op.drop_constraint('unique_book_per_author', 'books', type_='unique')

    # Step 3: Create new case-insensitive unique indexes
    op.create_index(
        'ix_themes_name_lower_unique',
        'themes',
        [sa.text('LOWER(name)')],
        unique=True
    )

    op.create_index(
        'ix_lesson_teachers_name_lower_unique',
        'lesson_teachers',
        [sa.text('LOWER(name)')],
        unique=True
    )

    op.create_index(
        'ix_book_authors_name_lower_unique',
        'book_authors',
        [sa.text('LOWER(name)')],
        unique=True
    )

    # For books, we need a composite index with LOWER(name) and author_id
    op.create_index(
        'ix_books_name_author_lower_unique',
        'books',
        [sa.text('LOWER(name)'), 'author_id'],
        unique=True
    )


def downgrade() -> None:
    # Drop case-insensitive indexes
    op.drop_index('ix_books_name_author_lower_unique', table_name='books')
    op.drop_index('ix_book_authors_name_lower_unique', table_name='book_authors')
    op.drop_index('ix_lesson_teachers_name_lower_unique', table_name='lesson_teachers')
    op.drop_index('ix_themes_name_lower_unique', table_name='themes')

    # Restore old UNIQUE constraints
    op.create_unique_constraint('unique_book_per_author', 'books', ['name', 'author_id'])
    op.create_unique_constraint('unique_book_author_name', 'book_authors', ['name'])
    op.create_unique_constraint('unique_lesson_teacher_name', 'lesson_teachers', ['name'])
    op.create_unique_constraint('unique_theme_name', 'themes', ['name'])
