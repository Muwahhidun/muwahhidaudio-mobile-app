"""
CRUD operations for User model.
"""
from typing import Optional
from datetime import datetime, timedelta
import uuid
import bcrypt
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
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


async def get_user_by_username(db: AsyncSession, username: str) -> Optional[User]:
    """
    Get user by username.

    Args:
        db: Database session
        username: Username

    Returns:
        User object if found, None otherwise
    """
    result = await db.execute(
        select(User)
        .options(selectinload(User.role))
        .where(User.username == username)
    )
    return result.scalar_one_or_none()


async def get_user_by_login_or_email(db: AsyncSession, login: str) -> Optional[User]:
    """
    Get user by username OR email.
    Automatically detects if login is email (contains @) or username.

    Args:
        db: Database session
        login: Username or email address

    Returns:
        User object if found, None otherwise
    """
    # Check if login contains @ (email) or not (username)
    if '@' in login:
        return await get_user_by_email(db, login)
    else:
        return await get_user_by_username(db, login)


def generate_verification_token() -> tuple[str, datetime]:
    """
    Generate a unique verification token and expiration date.

    Returns:
        Tuple of (token, expires_at)
        - token: UUID4 string
        - expires_at: datetime 30 days from now
    """
    token = str(uuid.uuid4())
    expires_at = datetime.utcnow() + timedelta(days=30)
    return token, expires_at


async def verify_email_token(db: AsyncSession, token: str) -> Optional[User]:
    """
    Verify email verification token and mark user as verified.

    Args:
        db: Database session
        token: Verification token

    Returns:
        User object if token is valid, None otherwise
    """
    # Find user with this token
    result = await db.execute(
        select(User)
        .options(selectinload(User.role))
        .where(User.verification_token == token)
    )
    user = result.scalar_one_or_none()

    if not user:
        return None

    # Check if token is expired
    if user.verification_token_expires and user.verification_token_expires < datetime.utcnow():
        return None

    # Mark user as verified
    user.email_verified = True
    user.verification_token = None
    user.verification_token_expires = None

    await db.flush()
    await db.refresh(user)

    return user


async def create_user(
    db: AsyncSession,
    email: str,
    username: str,
    password: str,
    first_name: Optional[str] = None,
    last_name: Optional[str] = None
) -> User:
    """
    Create a new user with email verification token.

    Args:
        db: Database session
        email: User email
        username: Username (unique, 3-20 chars)
        password: Plain text password (will be hashed)
        first_name: User first name (optional)
        last_name: User last name (optional)

    Returns:
        Created User object with verification token
    """
    # Get default "User" role (level=0)
    result = await db.execute(select(Role).where(Role.level == 0))
    default_role = result.scalar_one()

    # Generate verification token
    verification_token, token_expires = generate_verification_token()

    # Create user
    user = User(
        email=email,
        username=username,
        password_hash=hash_password(password),
        first_name=first_name,
        last_name=last_name,
        role_id=default_role.id,
        is_active=True,
        email_verified=False,  # Not verified yet
        verification_token=verification_token,
        verification_token_expires=token_expires
    )

    db.add(user)
    await db.flush()

    # Reload with role
    await db.refresh(user, ["role"])

    return user


async def authenticate_user(db: AsyncSession, login: str, password: str) -> Optional[User]:
    """
    Authenticate user by username/email and password.

    Args:
        db: Database session
        login: Username or email address
        password: Plain text password

    Returns:
        User object if credentials are valid, None otherwise
    """
    user = await get_user_by_login_or_email(db, login)

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
