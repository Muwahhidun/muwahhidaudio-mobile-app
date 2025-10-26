"""
Feedback API endpoints.
User support/feedback messages.
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.feedback import (
    FeedbackCreate, FeedbackAdminUpdate, FeedbackResponse,
    PaginatedFeedbacksResponse, FeedbackMessageCreate, FeedbackMessageResponse
)
from app.crud import feedback as feedback_crud
from app.auth.dependencies import get_current_user, require_admin
from app.models import User
from app.models.feedback import FeedbackMessage

router = APIRouter(prefix="/feedbacks", tags=["Feedback"])


@router.post("", response_model=FeedbackResponse, status_code=status.HTTP_201_CREATED)
async def create_feedback(
    feedback_data: FeedbackCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create new feedback/support request.

    - **subject**: Subject/title of the feedback (3-255 chars)
    - **message_text**: Message text (min 10 chars)

    Returns created feedback with status='new'.
    """
    feedback = await feedback_crud.create_feedback(
        db=db,
        user_id=current_user.id,
        subject=feedback_data.subject,
        message_text=feedback_data.message_text
    )
    await db.commit()

    # Reload with messages relationship
    feedback = await feedback_crud.get_feedback_by_id(db, feedback.id)
    return feedback


@router.get("/my", response_model=PaginatedFeedbacksResponse)
async def get_my_feedbacks(
    skip: int = Query(0, ge=0, description="Skip records"),
    limit: int = Query(10, ge=1, le=100, description="Limit records"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get current user's feedbacks (paginated).

    Returns feedbacks ordered by creation date (newest first).
    """
    items, total = await feedback_crud.get_user_feedbacks(
        db=db,
        user_id=current_user.id,
        skip=skip,
        limit=limit
    )
    return PaginatedFeedbacksResponse(
        items=items,
        total=total,
        skip=skip,
        limit=limit
    )


@router.get("/{feedback_id}", response_model=FeedbackResponse)
async def get_feedback(
    feedback_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get feedback by ID.

    User can only see their own feedbacks.
    Admin can see any feedback.
    """
    feedback = await feedback_crud.get_feedback_by_id(db, feedback_id)

    if not feedback:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Feedback not found"
        )

    # Check permissions: user can only see their own, admin can see all
    if feedback.user_id != current_user.id and current_user.role.name != 'Admin':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this feedback"
        )

    return feedback


@router.get("", response_model=PaginatedFeedbacksResponse)
async def get_all_feedbacks(
    status_filter: str = Query(None, description="Filter by status: new, replied, closed"),
    user_id: int = Query(None, description="Filter by user ID"),
    search: str = Query(None, description="Search in subject or message"),
    skip: int = Query(0, ge=0, description="Skip records"),
    limit: int = Query(10, ge=1, le=100, description="Limit records"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """
    Get all feedbacks with filters (admin only).

    - **status_filter**: Filter by status (new, replied, closed)
    - **user_id**: Filter by user ID
    - **search**: Search in subject or message text
    - **skip**: Pagination offset
    - **limit**: Pagination limit

    Returns feedbacks ordered by creation date (newest first).
    """
    items, total = await feedback_crud.get_all_feedbacks(
        db=db,
        status=status_filter,
        user_id=user_id,
        search=search,
        skip=skip,
        limit=limit
    )
    return PaginatedFeedbacksResponse(
        items=items,
        total=total,
        skip=skip,
        limit=limit
    )


@router.put("/{feedback_id}", response_model=FeedbackResponse)
async def update_feedback(
    feedback_id: int,
    update_data: FeedbackAdminUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """
    Update feedback (admin only).

    - **admin_reply**: Admin's reply (optional)
    - **status**: Status (new, replied, closed) (optional)

    Auto-logic:
    - If admin_reply provided → status='replied', replied_at=now()
    - If status='closed' → closed_at=now()
    """
    feedback = await feedback_crud.update_feedback_admin(
        db=db,
        feedback_id=feedback_id,
        admin_reply=update_data.admin_reply,
        status=update_data.status
    )

    if not feedback:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Feedback not found"
        )

    await db.commit()
    return feedback


# ==================== FeedbackMessage Endpoints ====================


@router.post("/{feedback_id}/messages", response_model=FeedbackMessageResponse, status_code=status.HTTP_201_CREATED)
async def create_message(
    feedback_id: int,
    message_data: FeedbackMessageCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Add a new message to feedback conversation.

    Both user and admin can add messages.
    - User can only add messages to their own feedbacks
    - Admin can add messages to any feedback

    The is_admin flag can be specified explicitly via send_as_admin parameter (admins only),
    or will be auto-detected from user role if not specified.
    """
    # Get feedback to check permissions
    feedback = await feedback_crud.get_feedback_by_id(db, feedback_id)

    if not feedback:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Feedback not found"
        )

    # Check user role
    user_is_admin = current_user.role.name == 'Admin'

    # Check permissions: user can only message their own feedbacks
    if feedback.user_id != current_user.id and not user_is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to add messages to this feedback"
        )

    # Determine is_admin flag for the message
    if message_data.send_as_admin is not None:
        # Explicit specification via send_as_admin parameter
        if message_data.send_as_admin and not user_is_admin:
            # Regular user cannot send as admin
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only administrators can send messages as admin"
            )
        is_admin = message_data.send_as_admin
    else:
        # Auto-detect from user role
        is_admin = user_is_admin

    # Create message
    message = await feedback_crud.create_message(
        db=db,
        feedback_id=feedback_id,
        author_id=current_user.id,
        is_admin=is_admin,
        message_text=message_data.message_text
    )

    await db.commit()
    return message


@router.delete("/{feedback_id}/messages/{message_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_message(
    feedback_id: int,
    message_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """
    Delete a feedback message (admin only).

    - Verify the message belongs to the specified feedback
    - Only administrators can delete messages
    """
    # Get feedback to verify it exists
    feedback = await feedback_crud.get_feedback_by_id(db, feedback_id)
    if not feedback:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Feedback not found"
        )

    # Get the message to verify it belongs to this feedback
    message_query = select(FeedbackMessage).where(
        FeedbackMessage.id == message_id
    )
    result = await db.execute(message_query)
    message = result.scalar_one_or_none()

    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
        )

    if message.feedback_id != feedback_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message does not belong to this feedback"
        )

    # Delete the message
    deleted = await feedback_crud.delete_message(db, message_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
        )

    await db.commit()
    return None


@router.delete("/{feedback_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_feedback(
    feedback_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """
    Delete a feedback and all its messages (admin only).

    - Only administrators can delete feedbacks
    - This will also delete all messages associated with this feedback
    """
    # Verify feedback exists
    feedback = await feedback_crud.get_feedback_by_id(db, feedback_id)
    if not feedback:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Feedback not found"
        )

    # Delete the feedback (and all its messages)
    deleted = await feedback_crud.delete_feedback(db, feedback_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Feedback not found"
        )

    await db.commit()
    return None
