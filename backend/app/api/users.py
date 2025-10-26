"""
Users management API endpoints (admin only).
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.user import (
    UserResponse, UserAdminUpdate, PaginatedUsersResponse
)
from app.crud import user as user_crud
from app.auth.dependencies import get_current_user
from app.models import User

router = APIRouter(prefix="/api/users", tags=["Users Management"])


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """
    Dependency to require admin role.

    Raises:
        HTTPException: 403 if user is not admin
    """
    if not current_user.role or current_user.role.level < 2:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user


@router.get("", response_model=PaginatedUsersResponse)
async def get_users(
    search: str = Query(None, description="Search by email or username"),
    role_id: int = Query(None, description="Filter by role ID"),
    is_active: bool = Query(None, description="Filter by active status"),
    skip: int = Query(0, ge=0, description="Skip records"),
    limit: int = Query(10, ge=1, le=100, description="Limit records"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """
    Get list of users with filters and pagination.

    Admin only. Returns paginated list of users.
    """
    users, total = await user_crud.get_users(
        db=db,
        search=search,
        role_id=role_id,
        is_active=is_active,
        skip=skip,
        limit=limit
    )

    return PaginatedUsersResponse(
        items=users,
        total=total,
        skip=skip,
        limit=limit
    )


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """
    Get user by ID.

    Admin only.
    """
    user = await user_crud.get_user_by_id(db, user_id)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return user


@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    update_data: UserAdminUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """
    Update user by admin (credentials, role, status, email verification).

    Admin only. Allows changing:
    - email: Email address
    - username: Username
    - password: Password (will be hashed)
    - first_name: First name
    - last_name: Last name
    - role_id: User role
    - is_active: Active status
    - email_verified: Email verification status

    Raises:
    - 404: User not found
    - 409: Email or username already taken
    """
    try:
        user = await user_crud.update_user_admin(
            db=db,
            user_id=user_id,
            email=update_data.email,
            username=update_data.username,
            password=update_data.password,
            first_name=update_data.first_name,
            last_name=update_data.last_name,
            role_id=update_data.role_id,
            is_active=update_data.is_active,
            email_verified=update_data.email_verified
        )

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        await db.commit()

        return user

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )


@router.delete("/{user_id}")
async def delete_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """
    Delete user by ID.

    Admin only. Cannot delete yourself.
    """
    # Prevent self-deletion
    if user_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete yourself"
        )

    user = await user_crud.get_user_by_id(db, user_id)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    await db.delete(user)
    await db.commit()

    return {"message": "User deleted successfully"}
