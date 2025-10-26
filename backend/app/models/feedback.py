"""
Feedback model.
User feedback and support messages with conversation history.
"""
from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime, Boolean
from sqlalchemy.orm import relationship
from app.database import Base
from app.models.base import TimestampMixin


class Feedback(Base, TimestampMixin):
    """User feedback and support messages."""

    __tablename__ = "feedbacks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    subject = Column(String(255), nullable=False, index=True)
    message_text = Column(Text, nullable=False)
    admin_reply = Column(Text, nullable=True)
    status = Column(String(20), default='new', nullable=False, index=True)  # 'new', 'replied', 'closed'
    replied_at = Column(DateTime, nullable=True)
    closed_at = Column(DateTime, nullable=True)

    # Relationships
    user = relationship("User", back_populates="feedbacks")
    messages = relationship("FeedbackMessage", back_populates="feedback", cascade="all, delete-orphan", order_by="FeedbackMessage.created_at")

    def __repr__(self):
        return f"<Feedback(id={self.id}, user_id={self.user_id}, status='{self.status}')>"


class FeedbackMessage(Base, TimestampMixin):
    """Individual message in a feedback conversation."""

    __tablename__ = "feedback_messages"

    id = Column(Integer, primary_key=True, index=True)
    feedback_id = Column(Integer, ForeignKey("feedbacks.id", ondelete="CASCADE"), nullable=False, index=True)
    author_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    is_admin = Column(Boolean, default=False, nullable=False, index=True)
    message_text = Column(Text, nullable=False)

    # Relationships
    feedback = relationship("Feedback", back_populates="messages")
    author = relationship("User")

    def __repr__(self):
        return f"<FeedbackMessage(id={self.id}, feedback_id={self.feedback_id}, is_admin={self.is_admin})>"
