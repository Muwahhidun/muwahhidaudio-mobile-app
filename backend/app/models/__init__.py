"""
Models package.
Import all models here for Alembic migrations.
"""
from app.models.user import Role, User
from app.models.content import Theme, BookAuthor, Book
from app.models.lesson import LessonTeacher, LessonSeries, Lesson
from app.models.test import Test, TestQuestion, TestAttempt
from app.models.bookmark import Bookmark
from app.models.feedback import Feedback, FeedbackMessage
from app.models.system_settings import SystemSettings

__all__ = [
    # User models
    "Role",
    "User",
    # Content models
    "Theme",
    "BookAuthor",
    "Book",
    # Lesson models
    "LessonTeacher",
    "LessonSeries",
    "Lesson",
    # Test models
    "Test",
    "TestQuestion",
    "TestAttempt",
    # Other models
    "Bookmark",
    "Feedback",
    "FeedbackMessage",
    # System models
    "SystemSettings",
]
