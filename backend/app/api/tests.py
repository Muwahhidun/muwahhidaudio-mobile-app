"""
Tests API endpoints.
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.api.auth import get_current_user
from app.models import User
from app.schemas.test import (
    TestWithRelations,
    TestCreate,
    TestUpdate,
    TestWithQuestions,
    TestQuestionAdminResponse,
    TestQuestionCreate,
    TestQuestionUpdate,
    LessonSeriesNested,
    TeacherNested,
    LessonNested
)
from app.crud import test as test_crud

router = APIRouter(prefix="/tests", tags=["Tests"])


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Require admin role."""
    if current_user.role.level < 2:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user


def build_test_with_relations(test) -> TestWithRelations:
    """Helper function to build TestWithRelations from Test model."""
    # Build nested schemas
    series_nested = None
    if test.series:
        series_nested = LessonSeriesNested(
            id=test.series.id,
            name=test.series.name,
            year=test.series.year,
            display_name=f"{test.series.year} - {test.series.name}"
        )

    teacher_nested = None
    if test.teacher:
        teacher_nested = TeacherNested(
            id=test.teacher.id,
            name=test.teacher.name
        )

    # Prepare test data excluding relationship fields
    test_data = {
        key: value for key, value in test.__dict__.items()
        if key not in ('series', 'teacher', 'questions', '_sa_instance_state')
    }

    return TestWithRelations(
        **test_data,
        series=series_nested,
        teacher=teacher_nested
    )


def build_question_with_lesson(question) -> TestQuestionAdminResponse:
    """Helper function to build TestQuestionAdminResponse from TestQuestion model."""
    lesson_nested = None
    if question.lesson:
        lesson_nested = LessonNested(
            id=question.lesson.id,
            title=question.lesson.title,
            lesson_number=question.lesson.lesson_number,
            display_title=f"Урок {question.lesson.lesson_number}" if question.lesson.lesson_number else question.lesson.title
        )

    # Prepare question data excluding relationship fields
    question_data = {
        key: value for key, value in question.__dict__.items()
        if key not in ('lesson', 'test', '_sa_instance_state')
    }

    return TestQuestionAdminResponse(
        **question_data,
        lesson=lesson_nested
    )


# ============================================================
# TEST ENDPOINTS
# ============================================================

@router.get("")
async def get_all_tests(
    search: Optional[str] = Query(None, description="Search by title or description"),
    series_id: Optional[int] = Query(None, description="Filter by series ID"),
    teacher_id: Optional[int] = Query(None, description="Filter by teacher ID"),
    book_id: Optional[int] = Query(None, description="Filter by book ID (via series)"),
    theme_id: Optional[int] = Query(None, description="Filter by theme ID (via series)"),
    include_inactive: bool = Query(False, description="Include inactive tests"),
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of records to return"),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Get all tests with filters and pagination (admin only).

    Returns:
        Dictionary with tests list, total count, skip, and limit
    """
    # Get total count
    total = await test_crud.count_tests(
        db,
        search=search,
        series_id=series_id,
        teacher_id=teacher_id,
        book_id=book_id,
        theme_id=theme_id,
        include_inactive=include_inactive
    )

    # Get tests
    tests = await test_crud.get_all_tests(
        db,
        search=search,
        series_id=series_id,
        teacher_id=teacher_id,
        book_id=book_id,
        theme_id=theme_id,
        skip=skip,
        limit=limit,
        include_inactive=include_inactive
    )

    return {
        "items": [build_test_with_relations(test) for test in tests],
        "total": total,
        "skip": skip,
        "limit": limit
    }


@router.post("", response_model=TestWithRelations, status_code=status.HTTP_201_CREATED)
async def create_test(
    test_data: TestCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Create a new test (admin only).
    Title and description are auto-generated if not provided.

    Args:
        test_data: Test creation data

    Returns:
        Created test with relationships
    """
    try:
        test = await test_crud.create_test(db, test_data)
        return build_test_with_relations(test)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.get("/{test_id}", response_model=TestWithQuestions)
async def get_test_by_id(
    test_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Get test by ID with all questions (admin only).

    Args:
        test_id: Test ID

    Returns:
        Test with all questions and relationships
    """
    test = await test_crud.get_test_by_id(db, test_id)

    if not test:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Test with ID {test_id} not found"
        )

    # Get all questions for this test
    questions = await test_crud.get_all_test_questions(db, test_id)

    # Build test with relations
    test_dict = build_test_with_relations(test).model_dump()

    # Build questions with lessons
    questions_list = [build_question_with_lesson(q) for q in questions]

    return TestWithQuestions(
        **test_dict,
        questions=questions_list
    )


@router.put("/{test_id}", response_model=TestWithRelations)
async def update_test(
    test_id: int,
    test_data: TestUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Update a test (admin only).

    Args:
        test_id: Test ID
        test_data: Test update data

    Returns:
        Updated test with relationships
    """
    test = await test_crud.update_test(db, test_id, test_data)

    if not test:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Test with ID {test_id} not found"
        )

    return build_test_with_relations(test)


@router.delete("/{test_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_test(
    test_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Soft delete a test (admin only).

    Args:
        test_id: Test ID

    Returns:
        No content
    """
    success = await test_crud.delete_test(db, test_id)

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Test with ID {test_id} not found"
        )


# ============================================================
# TEST QUESTION ENDPOINTS
# ============================================================

@router.get("/{test_id}/questions")
async def get_test_questions(
    test_id: int,
    lesson_id: Optional[int] = Query(None, description="Filter by lesson ID (for personal tests)"),
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(1000, ge=1, le=1000, description="Maximum number of records to return"),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Get all questions for a test (admin only).
    Can filter by lesson_id for personal lesson tests.

    Args:
        test_id: Test ID
        lesson_id: Optional lesson ID filter
        skip: Number of records to skip
        limit: Maximum number of records to return

    Returns:
        Dictionary with questions list, total count, skip, and limit
    """
    # Verify test exists
    test = await test_crud.get_test_by_id(db, test_id)
    if not test:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Test with ID {test_id} not found"
        )

    # Get total count
    total = await test_crud.count_test_questions(db, test_id, lesson_id=lesson_id)

    # Get questions
    questions = await test_crud.get_all_test_questions(
        db,
        test_id,
        lesson_id=lesson_id,
        skip=skip,
        limit=limit
    )

    return {
        "items": [build_question_with_lesson(q) for q in questions],
        "total": total,
        "skip": skip,
        "limit": limit
    }


@router.post("/{test_id}/questions", response_model=TestQuestionAdminResponse, status_code=status.HTTP_201_CREATED)
async def create_test_question(
    test_id: int,
    question_data: TestQuestionCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Create a new test question (admin only).

    Args:
        test_id: Test ID
        question_data: Question creation data

    Returns:
        Created question with relationships
    """
    # Verify test exists
    test = await test_crud.get_test_by_id(db, test_id)
    if not test:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Test with ID {test_id} not found"
        )

    # Ensure test_id matches
    if question_data.test_id != test_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Test ID in URL does not match test_id in request body"
        )

    # Validate correct_answer_index
    if question_data.correct_answer_index >= len(question_data.options):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="correct_answer_index must be less than the number of options"
        )

    question = await test_crud.create_test_question(db, question_data)
    return build_question_with_lesson(question)


@router.get("/{test_id}/questions/{question_id}", response_model=TestQuestionAdminResponse)
async def get_test_question_by_id(
    test_id: int,
    question_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Get test question by ID (admin only).

    Args:
        test_id: Test ID
        question_id: Question ID

    Returns:
        Question with relationships
    """
    question = await test_crud.get_test_question_by_id(db, question_id)

    if not question:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Question with ID {question_id} not found"
        )

    # Verify question belongs to test
    if question.test_id != test_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Question {question_id} does not belong to test {test_id}"
        )

    return build_question_with_lesson(question)


@router.put("/{test_id}/questions/{question_id}", response_model=TestQuestionAdminResponse)
async def update_test_question(
    test_id: int,
    question_id: int,
    question_data: TestQuestionUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Update a test question (admin only).

    Args:
        test_id: Test ID
        question_id: Question ID
        question_data: Question update data

    Returns:
        Updated question with relationships
    """
    # Get existing question
    existing_question = await test_crud.get_test_question_by_id(db, question_id)

    if not existing_question:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Question with ID {question_id} not found"
        )

    # Verify question belongs to test
    if existing_question.test_id != test_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Question {question_id} does not belong to test {test_id}"
        )

    # Validate correct_answer_index if provided
    if question_data.correct_answer_index is not None:
        # Get options (use updated if provided, otherwise existing)
        options = question_data.options if question_data.options is not None else existing_question.options
        if question_data.correct_answer_index >= len(options):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="correct_answer_index must be less than the number of options"
            )

    question = await test_crud.update_test_question(db, question_id, question_data)
    return build_question_with_lesson(question)


@router.delete("/{test_id}/questions/{question_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_test_question(
    test_id: int,
    question_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Delete a test question (admin only).

    Args:
        test_id: Test ID
        question_id: Question ID

    Returns:
        No content
    """
    # Get existing question
    existing_question = await test_crud.get_test_question_by_id(db, question_id)

    if not existing_question:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Question with ID {question_id} not found"
        )

    # Verify question belongs to test
    if existing_question.test_id != test_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Question {question_id} does not belong to test {test_id}"
        )

    success = await test_crud.delete_test_question(db, question_id)

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Question with ID {question_id} not found"
        )
