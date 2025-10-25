"""
Content models: Themes, BookAuthors, Books.
Core content structure for organizing lessons.
"""
from sqlalchemy import Column, Integer, String, Text, Boolean, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.database import Base
from app.models.base import TimestampMixin


class Theme(Base, TimestampMixin):
    """Themes (Акыда, Сира, Фикх, Адаб)."""

    __tablename__ = "themes"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, unique=True)  # 'Акыда', 'Сира', 'Фикх'
    description = Column(Text, nullable=True)
    sort_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True, nullable=False, index=True)

    # Relationships
    books = relationship("Book", back_populates="theme")
    lesson_series = relationship("LessonSeries", back_populates="theme")
    lessons = relationship("Lesson", back_populates="theme")

    def __repr__(self):
        return f"<Theme(id={self.id}, name='{self.name}')>"


class BookAuthor(Base, TimestampMixin):
    """Classical Islamic scholars (book authors)."""

    __tablename__ = "book_authors"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, unique=True)  # 'Мухаммад ибн Абдуль-Ваххаб'
    biography = Column(Text, nullable=True)
    birth_year = Column(Integer, nullable=True)
    death_year = Column(Integer, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False, index=True)

    # Relationships
    books = relationship("Book", back_populates="author")

    def __repr__(self):
        return f"<BookAuthor(id={self.id}, name='{self.name}')>"


class Book(Base, TimestampMixin):
    """Islamic books being studied."""

    __tablename__ = "books"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    theme_id = Column(Integer, ForeignKey("themes.id", ondelete="SET NULL"), nullable=True, index=True)
    author_id = Column(Integer, ForeignKey("book_authors.id", ondelete="SET NULL"), nullable=True, index=True)
    sort_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True, nullable=False, index=True)

    # Unique constraint: book name must be unique per author
    __table_args__ = (
        UniqueConstraint('name', 'author_id', name='unique_book_per_author'),
    )

    # Relationships
    theme = relationship("Theme", back_populates="books")
    author = relationship("BookAuthor", back_populates="books")
    lesson_series = relationship("LessonSeries", back_populates="book")
    lessons = relationship("Lesson", back_populates="book")

    def __repr__(self):
        return f"<Book(id={self.id}, name='{self.name}')>"
