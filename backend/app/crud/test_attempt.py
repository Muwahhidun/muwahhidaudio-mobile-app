"""
CRUD operations for TestAttempt model.
"""
from typing import List, Optional, Dict
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, desc
from sqlalchemy.orm import selectinload

from app.models import TestAttempt, Test, LessonSeries, Lesson, User


# ============================================================
# TEST ATTEMPT CRUD OPERATIONS
# ============================================================

async def create_test_attempt(
    db: AsyncSession,
    user_id: int,
    test_id: int,
    lesson_id: Optional[int] = None
) -> TestAttempt:
    """
    Create a new test attempt (when user starts a test).

    Args:
        db: Database session
        user_id: ID of the user taking the test
        test_id: ID of the test
        lesson_id: Optional lesson ID (for lesson-specific tests)

    Returns:
        Created TestAttempt object
    """
    # Get the test to determine max_score
    test = await db.get(Test, test_id, options=[selectinload(Test.questions)])
    if not test:
        raise ValueError(f"Test with ID {test_id} not found")

    max_score = sum(q.points for q in test.questions)

    attempt = TestAttempt(
        user_id=user_id,
        test_id=test_id,
        lesson_id=lesson_id,
        started_at=datetime.utcnow(),
        max_score=max_score,
        score=0,
        passed=False
    )

    db.add(attempt)
    await db.commit()
    await db.refresh(attempt)

    return attempt


async def submit_test_attempt(
    db: AsyncSession,
    attempt_id: int,
    answers: Dict[int, int],  # {question_id: selected_option_index}
    time_spent_seconds: int
) -> TestAttempt:
    """
    Submit a test attempt with answers and calculate score.

    Args:
        db: Database session
        attempt_id: ID of the attempt
        answers: Dictionary mapping question_id to selected answer index
        time_spent_seconds: Time spent on the test in seconds

    Returns:
        Updated TestAttempt object with score
    """
    # Get the attempt with related test and questions
    stmt = select(TestAttempt).where(TestAttempt.id == attempt_id).options(
        selectinload(TestAttempt.test).selectinload(Test.questions)
    )
    result = await db.execute(stmt)
    attempt = result.scalar_one_or_none()

    if not attempt:
        raise ValueError(f"Test attempt with ID {attempt_id} not found")

    if attempt.completed_at is not None:
        raise ValueError("Test attempt already submitted")

    # Calculate score
    total_score = 0
    max_score = 0
    for question in attempt.test.questions:
        max_score += question.points
        user_answer = answers.get(question.id)
        if user_answer is not None and user_answer == question.correct_answer_index:
            total_score += question.points

    # Get passing score from test
    passing_score_percent = attempt.test.passing_score
    passed = (total_score / max_score * 100) >= passing_score_percent if max_score > 0 else False

    # Update attempt
    attempt.completed_at = datetime.utcnow()
    attempt.score = total_score
    attempt.max_score = max_score
    attempt.passed = passed
    attempt.answers = {str(k): v for k, v in answers.items()}  # Convert keys to strings for JSON
    attempt.time_spent_seconds = time_spent_seconds

    await db.commit()
    await db.refresh(attempt)

    return attempt


async def get_attempt_by_id(
    db: AsyncSession,
    attempt_id: int
) -> Optional[TestAttempt]:
    """
    Get a test attempt by ID.

    Args:
        db: Database session
        attempt_id: ID of the attempt

    Returns:
        TestAttempt object or None
    """
    stmt = select(TestAttempt).where(TestAttempt.id == attempt_id).options(
        selectinload(TestAttempt.test),
        selectinload(TestAttempt.user)
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def get_user_attempts(
    db: AsyncSession,
    user_id: int,
    test_id: Optional[int] = None,
    series_id: Optional[int] = None,
    completed_only: bool = True,
    skip: int = 0,
    limit: int = 100
) -> List[TestAttempt]:
    """
    Get all attempts for a user, optionally filtered by test or series.

    Args:
        db: Database session
        user_id: ID of the user
        test_id: Optional test ID filter
        series_id: Optional series ID filter
        completed_only: If True, only return completed attempts
        skip: Number of records to skip
        limit: Maximum number of records to return

    Returns:
        List of TestAttempt objects
    """
    query = select(TestAttempt).where(TestAttempt.user_id == user_id).options(
        selectinload(TestAttempt.test).selectinload(Test.series),
        selectinload(TestAttempt.lesson)
    )

    if completed_only:
        query = query.where(TestAttempt.completed_at.isnot(None))

    if test_id:
        query = query.where(TestAttempt.test_id == test_id)

    if series_id:
        # Join with Test to filter by series
        query = query.join(TestAttempt.test).where(Test.series_id == series_id)

    # Order by most recent first
    query = query.order_by(desc(TestAttempt.completed_at))
    query = query.offset(skip).limit(limit)

    result = await db.execute(query)
    return list(result.scalars().all())


async def get_user_best_attempt(
    db: AsyncSession,
    user_id: int,
    test_id: int
) -> Optional[TestAttempt]:
    """
    Get the best (highest scoring) completed attempt for a user on a specific test.

    Args:
        db: Database session
        user_id: ID of the user
        test_id: ID of the test

    Returns:
        Best TestAttempt object or None
    """
    query = select(TestAttempt).where(
        and_(
            TestAttempt.user_id == user_id,
            TestAttempt.test_id == test_id,
            TestAttempt.completed_at.isnot(None)
        )
    ).order_by(desc(TestAttempt.score)).limit(1)

    result = await db.execute(query)
    return result.scalar_one_or_none()


async def get_series_statistics(
    db: AsyncSession,
    user_id: int,
    series_id: int
) -> Dict:
    """
    Get statistics for a user on a specific series.

    Args:
        db: Database session
        user_id: ID of the user
        series_id: ID of the series

    Returns:
        Dictionary with statistics:
        - total_audio_duration: Total duration of all lessons in seconds
        - total_questions: Total number of questions across all tests
        - best_score_percent: Best score percentage (or None if no attempts)
        - total_attempts: Number of attempts
        - passed_count: Number of passed attempts
        - last_attempt_date: Date of last attempt (or None)
    """
    # Get series with lessons
    series_stmt = select(LessonSeries).where(LessonSeries.id == series_id).options(
        selectinload(LessonSeries.lessons),
        selectinload(LessonSeries.tests).selectinload(Test.questions)
    )
    series_result = await db.execute(series_stmt)
    series = series_result.scalar_one_or_none()

    if not series:
        raise ValueError(f"Series with ID {series_id} not found")

    # Calculate total audio duration
    total_duration = sum(lesson.duration_seconds or 0 for lesson in series.lessons)

    # Calculate total questions across all tests in series
    total_questions = sum(len(test.questions) for test in series.tests)

    # Get user's attempts for tests in this series
    test_ids = [test.id for test in series.tests]
    if test_ids:
        attempts_stmt = select(TestAttempt).where(
            and_(
                TestAttempt.user_id == user_id,
                TestAttempt.test_id.in_(test_ids),
                TestAttempt.completed_at.isnot(None)
            )
        )
        attempts_result = await db.execute(attempts_stmt)
        attempts = list(attempts_result.scalars().all())

        if attempts:
            # Calculate best score percentage
            best_attempt = max(attempts, key=lambda a: (a.score / a.max_score) if a.max_score > 0 else 0)
            best_score_percent = (best_attempt.score / best_attempt.max_score * 100) if best_attempt.max_score > 0 else 0

            # Count passed attempts
            passed_count = sum(1 for a in attempts if a.passed)

            # Get last attempt date
            last_attempt = max(attempts, key=lambda a: a.completed_at)
            last_attempt_date = last_attempt.completed_at
        else:
            best_score_percent = None
            passed_count = 0
            last_attempt_date = None

        total_attempts = len(attempts)
    else:
        best_score_percent = None
        total_attempts = 0
        passed_count = 0
        last_attempt_date = None

    return {
        "series_id": series_id,
        "total_audio_duration": total_duration,
        "total_questions": total_questions,
        "best_score_percent": best_score_percent,
        "total_attempts": total_attempts,
        "passed_count": passed_count,
        "last_attempt_date": last_attempt_date,
        "has_attempts": total_attempts > 0
    }


async def get_all_series_statistics(
    db: AsyncSession,
    user_id: int
) -> List[Dict]:
    """
    Get statistics for all series that have tests.

    Args:
        db: Database session
        user_id: ID of the user

    Returns:
        List of dictionaries with statistics for each series
    """
    # Get all series that have tests
    stmt = select(LessonSeries).where(
        LessonSeries.tests.any()
    ).options(
        selectinload(LessonSeries.lessons),
        selectinload(LessonSeries.tests).selectinload(Test.questions),
        selectinload(LessonSeries.book),
        selectinload(LessonSeries.teacher)
    )
    result = await db.execute(stmt)
    all_series = list(result.scalars().all())

    statistics = []
    for series in all_series:
        # Calculate total audio duration
        total_duration = sum(lesson.duration_seconds or 0 for lesson in series.lessons)

        # Calculate total questions
        total_questions = sum(len(test.questions) for test in series.tests)

        # Get user's attempts for tests in this series
        test_ids = [test.id for test in series.tests]
        if test_ids:
            attempts_stmt = select(TestAttempt).where(
                and_(
                    TestAttempt.user_id == user_id,
                    TestAttempt.test_id.in_(test_ids),
                    TestAttempt.completed_at.isnot(None)
                )
            )
            attempts_result = await db.execute(attempts_stmt)
            attempts = list(attempts_result.scalars().all())

            if attempts:
                # Calculate best score percentage
                best_attempt = max(attempts, key=lambda a: (a.score / a.max_score) if a.max_score > 0 else 0)
                best_score_percent = (best_attempt.score / best_attempt.max_score * 100) if best_attempt.max_score > 0 else 0

                # Count passed attempts
                passed_count = sum(1 for a in attempts if a.passed)

                # Get last attempt date
                last_attempt = max(attempts, key=lambda a: a.completed_at)
                last_attempt_date = last_attempt.completed_at
            else:
                best_score_percent = None
                passed_count = 0
                last_attempt_date = None

            total_attempts = len(attempts)
        else:
            best_score_percent = None
            total_attempts = 0
            passed_count = 0
            last_attempt_date = None

        statistics.append({
            "series_id": series.id,
            "series_name": series.name,
            "series_year": series.year,
            "book_name": series.book.name if series.book else None,
            "teacher_name": series.teacher.name if series.teacher else None,
            "total_audio_duration": total_duration,
            "total_questions": total_questions,
            "best_score_percent": best_score_percent,
            "total_attempts": total_attempts,
            "passed_count": passed_count,
            "last_attempt_date": last_attempt_date,
            "has_attempts": total_attempts > 0
        })

    return statistics


async def count_user_attempts(
    db: AsyncSession,
    user_id: int,
    test_id: Optional[int] = None,
    completed_only: bool = True
) -> int:
    """
    Count total number of attempts for a user.

    Args:
        db: Database session
        user_id: ID of the user
        test_id: Optional test ID filter
        completed_only: If True, only count completed attempts

    Returns:
        Total count of attempts
    """
    query = select(func.count(TestAttempt.id)).where(TestAttempt.user_id == user_id)

    if completed_only:
        query = query.where(TestAttempt.completed_at.isnot(None))

    if test_id:
        query = query.where(TestAttempt.test_id == test_id)

    result = await db.execute(query)
    return result.scalar() or 0
