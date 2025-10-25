"""
Bookmark model.
User bookmarks for lessons (max 20 per user).
"""
from sqlalchemy import Column, Integer, String, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.database import Base
from app.models.base import TimestampMixin


class Bookmark(Base, TimestampMixin):
    """User bookmarks for lessons."""

    __tablename__ = "bookmarks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False, index=True)
    custom_name = Column(String(200), nullable=False)

    # Unique constraint: one bookmark per user/lesson
    __table_args__ = (
        UniqueConstraint('user_id', 'lesson_id', name='uq_user_lesson_bookmark'),
    )

    # Relationships
    user = relationship("User", back_populates="bookmarks")
    lesson = relationship("Lesson", back_populates="bookmarks")

    def __repr__(self):
        return f"<Bookmark(id={self.id}, user_id={self.user_id}, lesson_id={self.lesson_id})>"
