"""
Feedback model.
User feedback and support messages.
"""
from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from app.database import Base
from app.models.base import TimestampMixin


class Feedback(Base, TimestampMixin):
    """User feedback and support messages."""

    __tablename__ = "feedbacks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    message_text = Column(Text, nullable=False)
    admin_reply = Column(Text, nullable=True)
    status = Column(String(20), default='new', nullable=False, index=True)  # 'new', 'replied', 'closed'
    replied_at = Column(DateTime, nullable=True)
    closed_at = Column(DateTime, nullable=True)

    # Relationships
    user = relationship("User", back_populates="feedbacks")

    def __repr__(self):
        return f"<Feedback(id={self.id}, user_id={self.user_id}, status='{self.status}')>"
