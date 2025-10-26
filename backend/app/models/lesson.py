"""
Lesson models: Teachers, Series, Lessons.
Core lesson structure and audio content.
"""
from sqlalchemy import Column, Integer, String, Text, Boolean, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.database import Base
from app.models.base import TimestampMixin


class LessonTeacher(Base, TimestampMixin):
    """Modern teachers/lecturers."""

    __tablename__ = "lesson_teachers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, unique=True)  # 'Мухаммад Абу Мунира'
    biography = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False, index=True)

    # Relationships
    lesson_series = relationship("LessonSeries", back_populates="teacher")
    lessons = relationship("Lesson", back_populates="teacher")
    tests = relationship("Test", back_populates="teacher")

    def __repr__(self):
        return f"<LessonTeacher(id={self.id}, name='{self.name}')>"


class LessonSeries(Base, TimestampMixin):
    """Series of lessons (e.g., 2025 - Три основы - Фаида 1)."""

    __tablename__ = "lesson_series"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    year = Column(Integer, nullable=False, index=True)
    description = Column(Text, nullable=True)
    teacher_id = Column(Integer, ForeignKey("lesson_teachers.id", ondelete="RESTRICT"), nullable=False, index=True)
    book_id = Column(Integer, ForeignKey("books.id", ondelete="SET NULL"), nullable=True, index=True)
    theme_id = Column(Integer, ForeignKey("themes.id", ondelete="SET NULL"), nullable=True, index=True)
    is_completed = Column(Boolean, default=False, nullable=False, index=True)
    order = Column(Integer, default=0, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False, index=True)

    # Unique constraint: one series per teacher/year/name combination
    __table_args__ = (
        UniqueConstraint('year', 'name', 'teacher_id', name='unique_series_per_teacher'),
    )

    # Relationships
    teacher = relationship("LessonTeacher", back_populates="lesson_series")
    book = relationship("Book", back_populates="lesson_series")
    theme = relationship("Theme", back_populates="lesson_series")
    lessons = relationship("Lesson", back_populates="series", cascade="all, delete-orphan")
    tests = relationship("Test", back_populates="series")

    def __repr__(self):
        return f"<LessonSeries(id={self.id}, name='{self.name}', year={self.year})>"


class Lesson(Base, TimestampMixin):
    """Individual audio lessons."""

    __tablename__ = "lessons"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)  # Auto-generated: teacher_book_year_series_урок_N
    description = Column(Text, nullable=True)
    audio_path = Column(String(500), nullable=True)  # Path to processed MP3 file (processed/)
    original_audio_path = Column(String(500), nullable=True)  # Path to original uploaded file (original/)
    lesson_number = Column(Integer, nullable=True)
    duration_seconds = Column(Integer, nullable=True)
    tags = Column(String(500), nullable=True)  # Comma-separated tags
    waveform_data = Column(Text, nullable=True)  # JSON array of waveform amplitude values
    series_id = Column(Integer, ForeignKey("lesson_series.id", ondelete="RESTRICT"), nullable=False, index=True)
    book_id = Column(Integer, ForeignKey("books.id", ondelete="SET NULL"), nullable=True, index=True)
    teacher_id = Column(Integer, ForeignKey("lesson_teachers.id", ondelete="SET NULL"), nullable=True, index=True)
    theme_id = Column(Integer, ForeignKey("themes.id", ondelete="SET NULL"), nullable=True, index=True)
    is_active = Column(Boolean, default=True, nullable=False, index=True)

    # Unique constraint: lesson number must be unique within series
    __table_args__ = (
        UniqueConstraint('series_id', 'lesson_number', name='unique_lesson_number_per_series'),
    )

    # Relationships
    series = relationship("LessonSeries", back_populates="lessons")
    book = relationship("Book", back_populates="lessons")
    teacher = relationship("LessonTeacher", back_populates="lessons")
    theme = relationship("Theme", back_populates="lessons")
    bookmarks = relationship("Bookmark", back_populates="lesson", cascade="all, delete-orphan")
    test_questions = relationship("TestQuestion", back_populates="lesson")
    test_attempts = relationship("TestAttempt", back_populates="lesson")

    def __repr__(self):
        return f"<Lesson(id={self.id}, title='{self.title}', lesson_number={self.lesson_number})>"
