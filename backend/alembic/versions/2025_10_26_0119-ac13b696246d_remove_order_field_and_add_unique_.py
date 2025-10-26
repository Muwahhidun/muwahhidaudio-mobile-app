"""remove_order_field_and_add_unique_series_constraint_to_tests

Revision ID: ac13b696246d
Revises: a5d308b6ea75
Create Date: 2025-10-26 01:19:42.165356

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ac13b696246d'
down_revision: Union[str, None] = 'a5d308b6ea75'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Step 1: Delete duplicate tests, keeping only the most recent one per series
    # This ensures we can add a unique constraint on series_id
    op.execute("""
        DELETE FROM tests
        WHERE id NOT IN (
            SELECT MAX(id)
            FROM tests
            GROUP BY series_id
        )
    """)

    # Step 2: Add unique constraint on series_id
    op.create_unique_constraint('unique_test_per_series', 'tests', ['series_id'])

    # Step 3: Drop the 'order' column as it's no longer needed
    op.drop_column('tests', 'order')


def downgrade() -> None:
    # Step 1: Re-add the 'order' column
    op.add_column('tests', sa.Column('order', sa.Integer(), nullable=True, server_default='0'))

    # Step 2: Drop the unique constraint
    op.drop_constraint('unique_test_per_series', 'tests', type_='unique')
