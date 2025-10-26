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


async def get_users(
    db: AsyncSession,
    search: Optional[str] = None,
    role_id: Optional[int] = None,
    is_active: Optional[bool] = None,
    skip: int = 0,
    limit: int = 10
) -> tuple[list[User], int]:
    """
    Get list of users with filters and pagination.

    Args:
        db: Database session
        search: Search by email or username
        role_id: Filter by role ID
        is_active: Filter by active status
        skip: Number of records to skip (pagination)
        limit: Maximum number of records to return

    Returns:
        Tuple of (list of users, total count)
    """
    from sqlalchemy import func

    # Build query
    query = select(User).options(selectinload(User.role))

    # Apply filters
    if search:
        query = query.where(
            or_(
                User.email.ilike(f'%{search}%'),
                User.username.ilike(f'%{search}%')
            )
        )

    if role_id is not None:
        query = query.where(User.role_id == role_id)

    if is_active is not None:
        query = query.where(User.is_active == is_active)

    # Get total count
    count_query = select(func.count()).select_from(User)
    if search:
        count_query = count_query.where(
            or_(
                User.email.ilike(f'%{search}%'),
                User.username.ilike(f'%{search}%')
            )
        )
    if role_id is not None:
        count_query = count_query.where(User.role_id == role_id)
    if is_active is not None:
        count_query = count_query.where(User.is_active == is_active)

    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    # Apply pagination and ordering
    query = query.order_by(User.created_at.desc()).offset(skip).limit(limit)

    # Execute query
    result = await db.execute(query)
    users = result.scalars().all()

    return list(users), total


async def update_user_admin(
    db: AsyncSession,
    user_id: int,
    email: Optional[str] = None,
    username: Optional[str] = None,
    password: Optional[str] = None,
    first_name: Optional[str] = None,
    last_name: Optional[str] = None,
    role_id: Optional[int] = None,
    is_active: Optional[bool] = None,
    email_verified: Optional[bool] = None
) -> Optional[User]:
    """
    Update user by admin (credentials, role, status, email verification).

    Args:
        db: Database session
        user_id: User ID to update
        email: New email (optional)
        username: New username (optional)
        password: New password (optional, will be hashed)
        first_name: New first name (optional)
        last_name: New last name (optional)
        role_id: New role ID (optional)
        is_active: New active status (optional)
        email_verified: New email verification status (optional)

    Returns:
        Updated User object or None if not found

    Raises:
        ValueError: If email or username already taken by another user
    """
    user = await get_user_by_id(db, user_id)

    if not user:
        return None

    # Check if email is changing and if it's already taken by another user
    if email and email != user.email:
        existing_email = await get_user_by_email(db, email)
        if existing_email and existing_email.id != user_id:
            raise ValueError("Email already registered")
        user.email = email
        # Reset email verification when email changes
        user.email_verified = False
        verification_token, token_expires = generate_verification_token()
        user.verification_token = verification_token
        user.verification_token_expires = token_expires

    # Check if username is changing and if it's already taken by another user
    if username and username != user.username:
        existing_username = await get_user_by_username(db, username)
        if existing_username and existing_username.id != user_id:
            raise ValueError("Username already taken")
        user.username = username

    # Update password if provided
    if password:
        user.password_hash = hash_password(password)

    # Update other fields
    if first_name is not None:
        user.first_name = first_name

    if last_name is not None:
        user.last_name = last_name

    if role_id is not None:
        user.role_id = role_id

    if is_active is not None:
        user.is_active = is_active

    if email_verified is not None:
        user.email_verified = email_verified
        if email_verified:
            # Clear verification token if email is verified
            user.verification_token = None
            user.verification_token_expires = None

    await db.flush()
    await db.refresh(user, ["role"])

    return user


async def update_user_profile(
    db: AsyncSession,
    user: User,
    email: Optional[str] = None,
    username: Optional[str] = None,
    current_password: str = None,
    new_password: Optional[str] = None,
    first_name: Optional[str] = None,
    last_name: Optional[str] = None
) -> Optional[User]:
    """
    Update user profile (for self-update).

    Args:
        db: Database session
        user: Current user object
        email: New email (optional)
        username: New username (optional)
        current_password: Current password (required for verification)
        new_password: New password (optional)
        first_name: New first name (optional)
        last_name: New last name (optional)

    Returns:
        Updated User object or None if current password is incorrect

    Raises:
        ValueError: If email or username already taken
    """
    # Verify current password
    if not verify_password(current_password, user.password_hash):
        return None

    # Check if email is changing and if it's already taken
    if email and email != user.email:
        existing_email = await get_user_by_email(db, email)
        if existing_email:
            raise ValueError("Email already registered")
        user.email = email
        # Reset email verification when email changes
        user.email_verified = False
        verification_token, token_expires = generate_verification_token()
        user.verification_token = verification_token
        user.verification_token_expires = token_expires

    # Check if username is changing and if it's already taken
    if username and username != user.username:
        existing_username = await get_user_by_username(db, username)
        if existing_username:
            raise ValueError("Username already taken")
        user.username = username

    # Update password if new password provided
    if new_password:
        user.password_hash = hash_password(new_password)

    # Update other fields
    if first_name is not None:
        user.first_name = first_name

    if last_name is not None:
        user.last_name = last_name

    await db.flush()
    await db.refresh(user, ["role"])

    return user
