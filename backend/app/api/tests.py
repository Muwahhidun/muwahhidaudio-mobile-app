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
    TestWithQuestionsUser,
    TestQuestionAdminResponse,
    TestQuestionCreate,
    TestQuestionUpdate,
    TestAttemptCreate,
    TestAttemptSubmit,
    TestAttemptResponse,
    SeriesStatistics,
    SeriesStatisticsDetailed,
    LessonSeriesNested,
    TeacherNested,
    LessonNested
)
from app.crud import test as test_crud
from app.crud import test_attempt as attempt_crud

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


# ============================================================
# PUBLIC USER ENDPOINTS
# ============================================================

@router.get("/series/{series_id}/test", response_model=TestWithQuestionsUser)
async def get_series_test(
    series_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get test for a series (all questions from lessons).
    Returns test without correct answers for user.

    Args:
        series_id: Series ID

    Returns:
        Test with questions (no correct answers shown)
    """
    # Find test for this series
    tests = await test_crud.get_all_tests(db, series_id=series_id, include_inactive=False)

    if not tests:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No active test found for series {series_id}"
        )

    test = tests[0]  # Should be only one test per series

    # Get all questions
    questions = await test_crud.get_all_test_questions(db, test.id)

    # Build response with relations
    test_dict = build_test_with_relations(test).model_dump()

    # Build questions without correct answers (for users)
    from app.schemas.test import TestQuestionUserResponse
    questions_list = []
    for q in questions:
        lesson_nested = None
        if q.lesson:
            lesson_nested = LessonNested(
                id=q.lesson.id,
                title=q.lesson.title,
                lesson_number=q.lesson.lesson_number,
                display_title=f"Урок {q.lesson.lesson_number}" if q.lesson.lesson_number else q.lesson.title
            )

        questions_list.append(TestQuestionUserResponse(
            id=q.id,
            test_id=q.test_id,
            lesson_id=q.lesson_id,
            question_text=q.question_text,
            options=q.options,
            order=q.order,
            points=q.points,
            lesson=lesson_nested
        ))

    return TestWithQuestionsUser(
        **test_dict,
        questions=questions_list
    )


@router.get("/lesson/{lesson_id}/test", response_model=TestWithQuestionsUser)
async def get_lesson_test(
    lesson_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get test questions for a specific lesson.
    Returns questions without correct answers.

    Args:
        lesson_id: Lesson ID

    Returns:
        Test with questions from this lesson only
    """
    # Get lesson to find its series
    from app.models import Lesson
    lesson = await db.get(Lesson, lesson_id)
    if not lesson:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Lesson with ID {lesson_id} not found"
        )

    # Find test for this series
    tests = await test_crud.get_all_tests(db, series_id=lesson.series_id, include_inactive=False)

    if not tests:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No active test found for lesson {lesson_id}"
        )

    test = tests[0]

    # Get questions only for this lesson
    questions = await test_crud.get_all_test_questions(db, test.id, lesson_id=lesson_id)

    if not questions:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No questions found for lesson {lesson_id}"
        )

    # Build response
    test_dict = build_test_with_relations(test).model_dump()

    from app.schemas.test import TestQuestionUserResponse
    questions_list = []
    for q in questions:
        lesson_nested = LessonNested(
            id=lesson.id,
            title=lesson.title,
            lesson_number=lesson.lesson_number,
            display_title=f"Урок {lesson.lesson_number}" if lesson.lesson_number else lesson.title
        )

        questions_list.append(TestQuestionUserResponse(
            id=q.id,
            test_id=q.test_id,
            lesson_id=q.lesson_id,
            question_text=q.question_text,
            options=q.options,
            order=q.order,
            points=q.points,
            lesson=lesson_nested
        ))

    return TestWithQuestionsUser(
        **test_dict,
        questions=questions_list
    )


@router.post("/{test_id}/start", response_model=TestAttemptResponse)
async def start_test(
    test_id: int,
    lesson_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Start a new test attempt.

    Args:
        test_id: Test ID
        lesson_id: Optional lesson ID (for lesson-specific tests)

    Returns:
        Created test attempt
    """
    try:
        attempt = await attempt_crud.create_test_attempt(
            db=db,
            user_id=current_user.id,
            test_id=test_id,
            lesson_id=lesson_id
        )
        return attempt
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.post("/attempts/{attempt_id}/submit", response_model=TestAttemptResponse)
async def submit_test_attempt(
    attempt_id: int,
    submission: TestAttemptSubmit,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Submit a test attempt with answers.

    Args:
        attempt_id: Attempt ID
        submission: Answers and time spent

    Returns:
        Updated attempt with score and results
    """
    # Verify attempt belongs to current user
    attempt = await attempt_crud.get_attempt_by_id(db, attempt_id)

    if not attempt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Attempt with ID {attempt_id} not found"
        )

    if attempt.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only submit your own attempts"
        )

    try:
        # Convert string keys to int for answers dict
        answers = {int(k): v for k, v in submission.answers.items()}

        updated_attempt = await attempt_crud.submit_test_attempt(
            db=db,
            attempt_id=attempt_id,
            answers=answers,
            time_spent_seconds=submission.time_spent_seconds
        )
        return updated_attempt
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/attempts/my", response_model=List[TestAttemptResponse])
async def get_my_attempts(
    series_id: Optional[int] = Query(None, description="Filter by series ID"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get current user's test attempts history.

    Args:
        series_id: Optional series ID filter
        skip: Number of records to skip
        limit: Maximum number of records

    Returns:
        List of user's test attempts
    """
    attempts = await attempt_crud.get_user_attempts(
        db=db,
        user_id=current_user.id,
        series_id=series_id,
        completed_only=True,
        skip=skip,
        limit=limit
    )
    return attempts


@router.get("/series/{series_id}/statistics", response_model=SeriesStatistics)
async def get_series_statistics(
    series_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get statistics for a series for current user.

    Args:
        series_id: Series ID

    Returns:
        Statistics including best score, attempts, etc.
    """
    try:
        stats = await attempt_crud.get_series_statistics(
            db=db,
            user_id=current_user.id,
            series_id=series_id
        )
        return SeriesStatistics(**stats)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.get("/statistics/all", response_model=List[SeriesStatisticsDetailed])
async def get_all_statistics(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get statistics for all series for current user.

    Returns:
        List of statistics for all series with tests
    """
    stats_list = await attempt_crud.get_all_series_statistics(
        db=db,
        user_id=current_user.id
    )
    return [SeriesStatisticsDetailed(**stats) for stats in stats_list]
