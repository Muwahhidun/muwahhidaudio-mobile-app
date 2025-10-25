"""
CRUD operations for User model.
"""
from typing import Optional
import bcrypt
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models import User, Role


def hash_password(password: str) -> str:
    """Hash password using bcrypt."""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against hash."""
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))


async def get_user_by_email(db: AsyncSession, email: str) -> Optional[User]:
    """
    Get user by email.

    Args:
        db: Database session
        email: User email

    Returns:
        User object if found, None otherwise
    """
    result = await db.execute(
        select(User)
        .options(selectinload(User.role))
        .where(User.email == email)
    )
    return result.scalar_one_or_none()


async def get_user_by_id(db: AsyncSession, user_id: int) -> Optional[User]:
    """
    Get user by ID.

    Args:
        db: Database session
        user_id: User ID

    Returns:
        User object if found, None otherwise
    """
    result = await db.execute(
        select(User)
        .options(selectinload(User.role))
        .where(User.id == user_id)
    )
    return result.scalar_one_or_none()


async def create_user(
    db: AsyncSession,
    email: str,
    password: str,
    first_name: Optional[str] = None,
    last_name: Optional[str] = None
) -> User:
    """
    Create a new user.

    Args:
        db: Database session
        email: User email
        password: Plain text password (will be hashed)
        first_name: User first name
        last_name: User last name

    Returns:
        Created User object
    """
    # Get default "User" role (level=0)
    result = await db.execute(select(Role).where(Role.level == 0))
    default_role = result.scalar_one()

    # Create user
    user = User(
        email=email,
        password_hash=hash_password(password),
        first_name=first_name,
        last_name=last_name,
        role_id=default_role.id,
        is_active=True
    )

    db.add(user)
    await db.flush()

    # Reload with role
    await db.refresh(user, ["role"])

    return user


async def authenticate_user(db: AsyncSession, email: str, password: str) -> Optional[User]:
    """
    Authenticate user by email and password.

    Args:
        db: Database session
        email: User email
        password: Plain text password

    Returns:
        User object if credentials are valid, None otherwise
    """
    user = await get_user_by_email(db, email)

    if not user:
        return None

    if not verify_password(password, user.password_hash):
        return None

    return user


async def update_user(
    db: AsyncSession,
    user: User,
    first_name: Optional[str] = None,
    last_name: Optional[str] = None
) -> User:
    """
    Update user information.

    Args:
        db: Database session
        user: User object to update
        first_name: New first name (optional)
        last_name: New last name (optional)

    Returns:
        Updated User object
    """
    if first_name is not None:
        user.first_name = first_name

    if last_name is not None:
        user.last_name = last_name

    await db.flush()
    await db.refresh(user)

    return user
