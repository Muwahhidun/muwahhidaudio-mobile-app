"""
Authentication API endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.user import (
    UserRegister, UserLogin, UserResponse, Token, TokenWithUser,
    EmailVerificationRequest, ResendVerificationRequest, RefreshTokenRequest,
    UserProfileUpdate
)
from app.crud import user as user_crud
from app.auth.jwt import create_access_token, create_refresh_token, verify_token
from app.auth.dependencies import get_current_user
from app.models import User
from app.services.email import send_verification_email

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=TokenWithUser, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserRegister,
    db: AsyncSession = Depends(get_db)
):
    """
    Register a new user with email verification.

    - **email**: User email address (must be unique)
    - **username**: Username (3-20 chars, English only, must be unique)
    - **password**: Password (min 8 chars, letters + digits, English only)
    - **first_name**: First name (optional)
    - **last_name**: Last name (optional)

    Returns JWT tokens and user data.
    User must verify email before login.
    """
    # Check if email already exists
    existing_email = await user_crud.get_user_by_email(db, user_data.email)
    if existing_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    # Check if username already exists
    existing_username = await user_crud.get_user_by_username(db, user_data.username)
    if existing_username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already taken"
        )

    # Create user with verification token
    user = await user_crud.create_user(
        db,
        email=user_data.email,
        username=user_data.username,
        password=user_data.password,
        first_name=user_data.first_name,
        last_name=user_data.last_name
    )

    await db.commit()

    # Send verification email
    try:
        await send_verification_email(
            db=db,
            email=user.email,
            username=user.username,
            token=user.verification_token
        )
    except Exception as e:
        # Log error but don't fail registration
        print(f"Failed to send verification email: {e}")

    # Create tokens for the new user
    access_token = create_access_token(data={"sub": str(user.id), "email": user.email})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": user
    }


@router.post("/login", response_model=TokenWithUser)
async def login(
    credentials: UserLogin,
    db: AsyncSession = Depends(get_db)
):
    """
    Login and get JWT tokens.

    - **login_or_email**: Username or email address
    - **password**: User password

    Returns:
    - **access_token**: JWT access token (valid for 1 hour)
    - **refresh_token**: JWT refresh token (valid for 7 days)
    - **token_type**: Token type (bearer)
    - **user**: User data

    Raises:
    - 401: Invalid credentials
    - 403: Email not verified or user inactive
    """
    # Authenticate user
    user = await user_crud.authenticate_user(db, credentials.login_or_email, credentials.password)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username/email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user"
        )

    # Check if email is verified
    if not user.email_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Email not verified. Please check your email for verification link."
        )

    # Create tokens
    access_token = create_access_token(data={"sub": str(user.id), "email": user.email})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": user
    }


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """
    Get current user profile.

    Requires authentication (Bearer token).
    """
    return current_user


@router.put("/me", response_model=UserResponse)
async def update_me(
    profile_data: UserProfileUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Update current user profile.

    Requires authentication (Bearer token).

    - **email**: New email address (optional)
    - **username**: New username (optional)
    - **current_password**: Current password (required for verification)
    - **new_password**: New password (optional)
    - **first_name**: First name (optional)
    - **last_name**: Last name (optional)

    Returns updated user data.

    Raises:
    - 400: Invalid current password
    - 409: Email or username already taken
    """
    try:
        updated_user = await user_crud.update_user_profile(
            db=db,
            user=current_user,
            email=profile_data.email,
            username=profile_data.username,
            current_password=profile_data.current_password,
            new_password=profile_data.new_password,
            first_name=profile_data.first_name,
            last_name=profile_data.last_name
        )

        if not updated_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Incorrect current password"
            )

        await db.commit()
        return updated_user

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )


@router.get("/verify-email")
async def verify_email(
    token: str = Query(..., description="Email verification token"),
    db: AsyncSession = Depends(get_db)
):
    """
    Verify user email with token from verification link.

    - **token**: Verification token from email link

    Returns success message if token is valid and not expired.

    Raises:
    - 400: Invalid or expired token
    """
    user = await user_crud.verify_email_token(db, token)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired verification token"
        )

    await db.commit()

    return {
        "message": "Email successfully verified",
        "email": user.email,
        "username": user.username
    }


@router.post("/resend-verification")
async def resend_verification(
    request: ResendVerificationRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Resend email verification link.

    - **email**: User email address

    Returns success message. Always returns 200 for security
    (doesn't reveal if email exists in database).

    Rate limited: 1 request per 5 minutes per email.
    """
    # Get user by email
    user = await user_crud.get_user_by_email(db, request.email)

    # For security, always return success even if user doesn't exist
    if not user:
        return {"message": "If this email is registered, a verification link has been sent"}

    # Check if already verified
    if user.email_verified:
        return {"message": "Email is already verified"}

    # Check if user is inactive
    if not user.is_active:
        return {"message": "If this email is registered, a verification link has been sent"}

    # Generate new verification token
    verification_token, token_expires = user_crud.generate_verification_token()
    user.verification_token = verification_token
    user.verification_token_expires = token_expires

    await db.commit()

    # Send verification email
    try:
        await send_verification_email(
            db=db,
            email=user.email,
            username=user.username,
            token=user.verification_token
        )
    except Exception as e:
        # Log error but don't expose it to user
        print(f"Failed to send verification email: {e}")

    return {"message": "If this email is registered, a verification link has been sent"}


@router.post("/refresh", response_model=Token)
async def refresh_token_endpoint(
    request: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Refresh access token using refresh token.

    - **refresh_token**: Valid refresh token

    Returns:
    - **access_token**: New JWT access token (valid for 1 hour)
    - **refresh_token**: New JWT refresh token (valid for 7 days)
    - **token_type**: Token type (bearer)

    Raises:
    - 401: Invalid or expired refresh token
    - 404: User not found or inactive
    """
    # Verify refresh token
    payload = verify_token(request.refresh_token, token_type="refresh")

    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Get user ID from payload
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
        )

    # Get user from database
    user = await user_crud.get_user_by_id(db, int(user_id))

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user"
        )

    # Create new tokens
    new_access_token = create_access_token(data={"sub": str(user.id), "email": user.email})
    new_refresh_token = create_refresh_token(data={"sub": str(user.id)})

    return {
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
        "token_type": "bearer"
    }
