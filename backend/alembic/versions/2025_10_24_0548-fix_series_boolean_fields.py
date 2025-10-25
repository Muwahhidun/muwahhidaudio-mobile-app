"""fix_series_boolean_fields

Revision ID: 2025_10_24_0548
Revises: e1796ce42dc8
Create Date: 2025-10-24 05:48:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '2025_10_24_0548'
down_revision: Union[str, None] = 'e1796ce42dc8'
branch_labels: Union[str, None] = None
depends_on: Union[str, None] = None


def upgrade() -> None:
    # Update any NULL values in boolean fields to their defaults
    op.execute("UPDATE lesson_series SET is_completed = FALSE WHERE is_completed IS NULL")
    op.execute("UPDATE lesson_series SET is_active = TRUE WHERE is_active IS NULL")
    op.execute("UPDATE lesson_series SET \"order\" = 0 WHERE \"order\" IS NULL")
    
    # Make sure the columns are NOT NULL (they should already be, but just in case)
    op.alter_column('lesson_series', 'is_completed',
                    existing_type=sa.Boolean(),
                    nullable=False,
                    server_default=sa.text('false'))
    op.alter_column('lesson_series', 'is_active',
                    existing_type=sa.Boolean(),
                    nullable=False,
                    server_default=sa.text('true'))
    op.alter_column('lesson_series', 'order',
                    existing_type=sa.Integer(),
                    nullable=False,
                    server_default=sa.text('0'))


def downgrade() -> None:
    # Revert to allow NULL values
    op.alter_column('lesson_series', 'order',
                    existing_type=sa.Integer(),
                    nullable=True)
    op.alter_column('lesson_series', 'is_active',
                    existing_type=sa.Boolean(),
                    nullable=True)
    op.alter_column('lesson_series', 'is_completed',
                    existing_type=sa.Boolean(),
                    nullable=True)