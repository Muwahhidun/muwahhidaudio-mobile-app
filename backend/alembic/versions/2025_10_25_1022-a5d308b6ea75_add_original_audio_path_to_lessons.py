"""add_original_audio_path_to_lessons

Revision ID: a5d308b6ea75
Revises: c0acc2ddd06b
Create Date: 2025-10-25 10:22:12.873971

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a5d308b6ea75'
down_revision: Union[str, None] = 'c0acc2ddd06b'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add original_audio_path column to lessons table
    op.add_column('lessons', sa.Column('original_audio_path', sa.String(length=500), nullable=True))


def downgrade() -> None:
    # Remove original_audio_path column from lessons table
    op.drop_column('lessons', 'original_audio_path')
