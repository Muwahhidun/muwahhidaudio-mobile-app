"""
Test models: Tests, Questions, Attempts.
Knowledge testing system.
"""
from sqlalchemy import Column, Integer, String, Text, Boolean, ForeignKey, JSON, DateTime
from sqlalchemy.orm import relationship
from app.database import Base
from app.models.base import TimestampMixin


class Test(Base, TimestampMixin):
    """Tests for lesson series."""

    __tablename__ = "tests"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    series_id = Column(Integer, ForeignKey("lesson_series.id", ondelete="RESTRICT"), nullable=False, index=True)
    teacher_id = Column(Integer, ForeignKey("lesson_teachers.id", ondelete="RESTRICT"), nullable=False, index=True)
    passing_score = Column(Integer, default=80)  # Percentage to pass (0-100)
    time_per_question_seconds = Column(Integer, default=30)
    questions_count = Column(Integer, default=0)
    is_active = Column(Boolean, default=True, nullable=False, index=True)

    # Relationships
    series = relationship("LessonSeries", back_populates="tests")
    teacher = relationship("LessonTeacher", back_populates="tests")
    questions = relationship("TestQuestion", back_populates="test", cascade="all, delete-orphan")
    attempts = relationship("TestAttempt", back_populates="test", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Test(id={self.id}, title='{self.title}', series_id={self.series_id})>"


class TestQuestion(Base, TimestampMixin):
    """Questions for tests."""

    __tablename__ = "test_questions"

    id = Column(Integer, primary_key=True, index=True)
    test_id = Column(Integer, ForeignKey("tests.id", ondelete="CASCADE"), nullable=False, index=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False, index=True)
    question_text = Column(Text, nullable=False)
    options = Column(JSON, nullable=False)  # ["Answer 1", "Answer 2", "Answer 3", "Answer 4"]
    correct_answer_index = Column(Integer, nullable=False)  # 0-3
    explanation = Column(Text, nullable=True)
    order = Column(Integer, default=0, index=True)
    points = Column(Integer, default=1)

    # Relationships
    test = relationship("Test", back_populates="questions")
    lesson = relationship("Lesson", back_populates="test_questions")

    def __repr__(self):
        return f"<TestQuestion(id={self.id}, test_id={self.test_id}, order={self.order})>"


class TestAttempt(Base):
    """User test attempts."""

    __tablename__ = "test_attempts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    test_id = Column(Integer, ForeignKey("tests.id", ondelete="CASCADE"), nullable=False, index=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="SET NULL"), nullable=True, index=True)
    started_at = Column(DateTime, nullable=False)
    completed_at = Column(DateTime, nullable=True)  # NULL = not finished yet
    score = Column(Integer, default=0)
    max_score = Column(Integer, nullable=False)
    passed = Column(Boolean, default=False, nullable=False, index=True)
    answers = Column(JSON, nullable=True)  # {"question_1": 0, "question_2": 2, ...}
    time_spent_seconds = Column(Integer, nullable=True)

    # Relationships
    user = relationship("User", back_populates="test_attempts")
    test = relationship("Test", back_populates="attempts")
    lesson = relationship("Lesson", back_populates="test_attempts")

    def __repr__(self):
        return f"<TestAttempt(id={self.id}, user_id={self.user_id}, score={self.score}/{self.max_score})>"
