"""
Script to apply the latest migration manually.
"""
import asyncio
import sys
from os.path import dirname, abspath

# Add the parent directory to the path so we can import app modules
sys.path.insert(0, dirname(dirname(abspath(__file__))))

from alembic.config import Config
from alembic import command


async def apply_migration():
    """Apply the latest migration."""
    alembic_cfg = Config("alembic.ini")
    command.upgrade(alembic_cfg, "head")
    print("Migration applied successfully!")


if __name__ == "__main__":
    asyncio.run(apply_migration())