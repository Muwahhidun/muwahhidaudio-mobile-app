"""
Pydantic schemas for Test and TestQuestion models.
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field


# ============================================================
# NESTED SCHEMAS (to avoid circular imports)
# ============================================================

class LessonSeriesNested(BaseModel):
    """Nested series info for test responses."""
    id: int
    name: str
    year: int
    display_name: Optional[str] = None

    class Config:
        from_attributes = True


class TeacherNested(BaseModel):
    """Nested teacher info for test responses."""
    id: int
    name: str

    class Config:
        from_attributes = True


class LessonNested(BaseModel):
    """Nested lesson info for question responses."""
    id: int
    title: str
    lesson_number: int
    display_title: Optional[str] = None

    class Config:
        from_attributes = True


# ============================================================
# TEST QUESTION SCHEMAS
# ============================================================

class TestQuestionBase(BaseModel):
    """Base test question schema with common fields."""
    question_text: str = Field(..., min_length=1)
    options: List[str] = Field(..., min_length=2, max_length=6)
    correct_answer_index: int = Field(..., ge=0)
    explanation: Optional[str] = None
    order: int = 0
    points: int = Field(default=1, ge=1)


class TestQuestionCreate(TestQuestionBase):
    """Schema for creating a test question."""
    test_id: int
    lesson_id: int


class TestQuestionUpdate(BaseModel):
    """Schema for updating a test question."""
    question_text: Optional[str] = Field(None, min_length=1)
    options: Optional[List[str]] = Field(None, min_length=2, max_length=6)
    correct_answer_index: Optional[int] = Field(None, ge=0)
    explanation: Optional[str] = None
    order: Optional[int] = None
    points: Optional[int] = Field(None, ge=1)
    lesson_id: Optional[int] = None


class TestQuestionResponse(TestQuestionBase):
    """Schema for test question responses."""
    id: int
    test_id: int
    lesson_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class TestQuestionWithLesson(TestQuestionResponse):
    """Test question response with nested lesson data."""
    lesson: Optional[LessonNested] = None


# For admin (includes correct answer)
class TestQuestionAdminResponse(TestQuestionResponse):
    """Admin view with all question details including correct answer."""
    lesson: Optional[LessonNested] = None


# For users (hides correct answer)
class TestQuestionUserResponse(BaseModel):
    """User view - hides correct answer and explanation until after attempt."""
    id: int
    test_id: int
    lesson_id: int
    question_text: str
    options: List[str]
    order: int
    points: int
    lesson: Optional[LessonNested] = None

    class Config:
        from_attributes = True


# ============================================================
# TEST SCHEMAS
# ============================================================

class TestBase(BaseModel):
    """Base test schema with common fields."""
    title: str = Field(..., max_length=255)
    description: Optional[str] = None
    passing_score: int = Field(default=80, ge=0, le=100)
    time_per_question_seconds: int = Field(default=30, ge=1)
    is_active: bool = True
    order: int = 0


class TestCreate(BaseModel):
    """Schema for creating a test."""
    title: Optional[str] = Field(None, max_length=255)  # Auto-generated if not provided
    description: Optional[str] = None  # Auto-generated if not provided
    series_id: int
    teacher_id: int
    passing_score: int = Field(default=80, ge=0, le=100)
    time_per_question_seconds: int = Field(default=30, ge=1)
    is_active: bool = True
    order: int = 0


class TestUpdate(BaseModel):
    """Schema for updating a test."""
    title: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = None
    series_id: Optional[int] = None
    teacher_id: Optional[int] = None
    passing_score: Optional[int] = Field(None, ge=0, le=100)
    time_per_question_seconds: Optional[int] = Field(None, ge=1)
    is_active: Optional[bool] = None
    order: Optional[int] = None


class TestResponse(TestBase):
    """Schema for test responses."""
    id: int
    series_id: int
    teacher_id: int
    questions_count: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class TestWithRelations(TestResponse):
    """Test response with nested series and teacher data."""
    series: Optional[LessonSeriesNested] = None
    teacher: Optional[TeacherNested] = None


class TestWithQuestions(TestWithRelations):
    """Test response with all questions (admin view)."""
    questions: List[TestQuestionAdminResponse] = []


class TestWithQuestionsUser(TestWithRelations):
    """Test response with questions for user (no correct answers)."""
    questions: List[TestQuestionUserResponse] = []


# ============================================================
# TEST ATTEMPT SCHEMAS (for future user functionality)
# ============================================================

class TestAttemptCreate(BaseModel):
    """Schema for creating a test attempt."""
    test_id: int
    lesson_id: Optional[int] = None  # None = overall test, set = personal lesson test


class TestAttemptAnswer(BaseModel):
    """Schema for submitting an answer."""
    question_id: int
    selected_answer_index: int
    time_spent_seconds: int


class TestAttemptSubmit(BaseModel):
    """Schema for submitting a test attempt."""
    answers: List[TestAttemptAnswer]


class TestAttemptResponse(BaseModel):
    """Schema for test attempt responses."""
    id: int
    test_id: int
    user_id: int
    lesson_id: Optional[int] = None
    score: int
    passed: bool
    total_time_seconds: int
    answers_data: dict
    created_at: datetime

    class Config:
        from_attributes = True
