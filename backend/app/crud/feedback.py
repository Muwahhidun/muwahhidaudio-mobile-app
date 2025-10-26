"""
CRUD operations for Feedback model.
"""
from datetime import datetime
from typing import Optional
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.feedback import Feedback, FeedbackMessage


async def create_feedback(
    db: AsyncSession,
    user_id: int,
    subject: str,
    message_text: str
) -> Feedback:
    """Create a new feedback/support request."""
    feedback = Feedback(
        user_id=user_id,
        subject=subject,
        message_text=message_text,
        status='new'
    )
    db.add(feedback)
    await db.flush()
    await db.refresh(feedback, ["user"])
    return feedback


async def get_feedback_by_id(
    db: AsyncSession,
    feedback_id: int
) -> Optional[Feedback]:
    """Get feedback by ID with user and messages relationships loaded."""
    query = (
        select(Feedback)
        .options(
            selectinload(Feedback.user),
            selectinload(Feedback.messages).selectinload(FeedbackMessage.author)
        )
        .where(Feedback.id == feedback_id)
    )
    result = await db.execute(query)
    return result.scalar_one_or_none()


async def get_user_feedbacks(
    db: AsyncSession,
    user_id: int,
    skip: int = 0,
    limit: int = 10
) -> tuple[list[Feedback], int]:
    """
    Get user's feedbacks with pagination.
    Returns (items, total_count).
    """
    # Count query
    count_query = select(func.count()).select_from(Feedback).where(Feedback.user_id == user_id)
    total = await db.scalar(count_query) or 0

    # Data query
    query = (
        select(Feedback)
        .options(
            selectinload(Feedback.user),
            selectinload(Feedback.messages).selectinload(FeedbackMessage.author)
        )
        .where(Feedback.user_id == user_id)
        .order_by(Feedback.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    result = await db.execute(query)
    items = list(result.scalars().all())

    return items, total


async def get_all_feedbacks(
    db: AsyncSession,
    status: Optional[str] = None,
    user_id: Optional[int] = None,
    search: Optional[str] = None,
    skip: int = 0,
    limit: int = 10
) -> tuple[list[Feedback], int]:
    """
    Get all feedbacks with filters and pagination (admin only).
    Returns (items, total_count).
    """
    # Base query
    query = select(Feedback).options(
        selectinload(Feedback.user),
        selectinload(Feedback.messages).selectinload(FeedbackMessage.author)
    )

    # Filters
    if status:
        query = query.where(Feedback.status == status)
    if user_id is not None:
        query = query.where(Feedback.user_id == user_id)
    if search:
        query = query.where(
            or_(
                Feedback.subject.ilike(f'%{search}%'),
                Feedback.message_text.ilike(f'%{search}%')
            )
        )

    # Count query (apply same filters)
    count_query = select(func.count()).select_from(Feedback)
    if status:
        count_query = count_query.where(Feedback.status == status)
    if user_id is not None:
        count_query = count_query.where(Feedback.user_id == user_id)
    if search:
        count_query = count_query.where(
            or_(
                Feedback.subject.ilike(f'%{search}%'),
                Feedback.message_text.ilike(f'%{search}%')
            )
        )

    total = await db.scalar(count_query) or 0

    # Data query with ordering and pagination
    query = query.order_by(Feedback.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    items = list(result.scalars().all())

    return items, total


async def update_feedback_admin(
    db: AsyncSession,
    feedback_id: int,
    admin_reply: Optional[str] = None,
    status: Optional[str] = None
) -> Optional[Feedback]:
    """
    Update feedback by admin (reply, status).

    Auto-logic:
    - If admin_reply is provided → status='replied', replied_at=now()
    - If status='closed' → closed_at=now()
    """
    feedback = await get_feedback_by_id(db, feedback_id)
    if not feedback:
        return None

    # Update admin_reply
    if admin_reply is not None:
        feedback.admin_reply = admin_reply
        # Auto-set status to 'replied' and timestamp
        if feedback.status == 'new':
            feedback.status = 'replied'
            feedback.replied_at = datetime.utcnow()

    # Update status
    if status is not None:
        feedback.status = status

        # Auto-set timestamps based on status
        if status == 'replied' and feedback.replied_at is None:
            feedback.replied_at = datetime.utcnow()
        elif status == 'closed' and feedback.closed_at is None:
            feedback.closed_at = datetime.utcnow()

    await db.flush()
    await db.refresh(feedback, ["user"])
    return feedback


# ==================== FeedbackMessage CRUD ====================


async def create_message(
    db: AsyncSession,
    feedback_id: int,
    author_id: int,
    is_admin: bool,
    message_text: str
) -> FeedbackMessage:
    """Create a new message in a feedback conversation."""
    message = FeedbackMessage(
        feedback_id=feedback_id,
        author_id=author_id,
        is_admin=is_admin,
        message_text=message_text
    )
    db.add(message)
    await db.flush()
    await db.refresh(message, ["author"])

    # If admin is replying, automatically update feedback status to 'replied'
    if is_admin:
        feedback = await get_feedback_by_id(db, feedback_id)
        if feedback and feedback.status == 'new':
            feedback.status = 'replied'
            feedback.replied_at = datetime.utcnow()
            await db.flush()

    return message


async def get_feedback_messages(
    db: AsyncSession,
    feedback_id: int
) -> list[FeedbackMessage]:
    """
    Get all messages for a feedback, ordered by creation time.
    Messages are auto-ordered by created_at via relationship definition.
    """
    query = (
        select(FeedbackMessage)
        .options(selectinload(FeedbackMessage.author))
        .where(FeedbackMessage.feedback_id == feedback_id)
        .order_by(FeedbackMessage.created_at.asc())
    )
    result = await db.execute(query)
    return list(result.scalars().all())


async def delete_message(
    db: AsyncSession,
    message_id: int
) -> bool:
    """
    Delete a feedback message by ID.
    Returns True if deleted, False if not found.
    """
    query = select(FeedbackMessage).where(FeedbackMessage.id == message_id)
    result = await db.execute(query)
    message = result.scalar_one_or_none()

    if not message:
        return False

    await db.delete(message)
    await db.flush()
    return True


async def delete_feedback(
    db: AsyncSession,
    feedback_id: int
) -> bool:
    """
    Delete a feedback and all its messages.
    Returns True if deleted, False if not found.
    """
    feedback = await get_feedback_by_id(db, feedback_id)

    if not feedback:
        return False

    # Delete all messages first
    messages_query = select(FeedbackMessage).where(FeedbackMessage.feedback_id == feedback_id)
    messages_result = await db.execute(messages_query)
    messages = messages_result.scalars().all()

    for message in messages:
        await db.delete(message)

    # Delete the feedback
    await db.delete(feedback)
    await db.flush()
    return True
