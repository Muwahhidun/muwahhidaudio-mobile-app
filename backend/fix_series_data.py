"""
Script to fix NULL values in series boolean fields directly.
"""
import asyncio
import sys
from os.path import dirname, abspath
import os

# Add the parent directory to the path so we can import app modules
sys.path.insert(0, dirname(dirname(abspath(__file__))))

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
from app.config import settings


async def fix_series_data():
    """Fix NULL values in series boolean fields."""
    # Create database engine
    engine = create_async_engine(settings.DATABASE_URL)
    
    # Create session
    async_session = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    
    async with async_session() as session:
        try:
            # Update NULL values in boolean fields
            print("Updating NULL values in lesson_series table...")
            
            # Fix is_completed field
            result = await session.execute(
                text("UPDATE lesson_series SET is_completed = FALSE WHERE is_completed IS NULL")
            )
            print(f"Updated {result.rowcount} rows for is_completed")
            
            # Fix is_active field
            result = await session.execute(
                text("UPDATE lesson_series SET is_active = TRUE WHERE is_active IS NULL")
            )
            print(f"Updated {result.rowcount} rows for is_active")
            
            # Fix order field
            result = await session.execute(
                text('UPDATE lesson_series SET "order" = 0 WHERE "order" IS NULL')
            )
            print(f"Updated {result.rowcount} rows for order")
            
            # Commit changes
            await session.commit()
            print("All updates committed successfully!")
            
            # Verify the changes
            result = await session.execute(
                text("SELECT COUNT(*) FROM lesson_series WHERE is_completed IS NULL OR is_active IS NULL OR \"order\" IS NULL")
            )
            count = result.scalar()
            print(f"Remaining rows with NULL values: {count}")
            
            if count == 0:
                print("All NULL values have been fixed!")
            else:
                print("There are still some NULL values in the database.")
                
        except Exception as e:
            print(f"Error: {e}")
            await session.rollback()
        finally:
            await engine.dispose()


if __name__ == "__main__":
    asyncio.run(fix_series_data())