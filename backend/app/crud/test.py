"""
CRUD operations for Test and TestQuestion models.
"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, func
from sqlalchemy.orm import selectinload

from app.models import Test, TestQuestion, LessonSeries, Book
from app.schemas.test import (
    TestCreate, TestUpdate,
    TestQuestionCreate, TestQuestionUpdate
)


# ============================================================
# TEST CRUD OPERATIONS
# ============================================================

async def get_all_tests(
    db: AsyncSession,
    search: Optional[str] = None,
    series_id: Optional[int] = None,
    teacher_id: Optional[int] = None,
    book_id: Optional[int] = None,
    theme_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 100,
    include_inactive: bool = False
) -> List[Test]:
    """
    Get all tests with filters.

    Args:
        db: Database session
        search: Search query for title or description
        series_id: Filter by series ID
        teacher_id: Filter by teacher ID
        book_id: Filter by book ID (via series)
        theme_id: Filter by theme ID (via series)
        skip: Number of records to skip
        limit: Maximum number of records to return
        include_inactive: Include inactive tests (for admin)

    Returns:
        List of tests
    """
    query = select(Test).options(
        selectinload(Test.series),
        selectinload(Test.teacher)
    )

    if not include_inactive:
        query = query.where(Test.is_active == True)

    # Apply filters
    if search:
        search_term = f"%{search}%"
        query = query.where(
            or_(
                Test.title.ilike(search_term),
                Test.description.ilike(search_term)
            )
        )

    if series_id:
        query = query.where(Test.series_id == series_id)

    if teacher_id:
        query = query.where(Test.teacher_id == teacher_id)

    # For book and theme filters, join with series
    if book_id or theme_id:
        query = query.join(Test.series)
        if book_id:
            query = query.where(LessonSeries.book_id == book_id)
        if theme_id:
            query = query.where(LessonSeries.theme_id == theme_id)

    # Order by series and order field
    query = query.order_by(Test.series_id, Test.order)

    # Apply pagination
    query = query.offset(skip).limit(limit)

    result = await db.execute(query)
    return list(result.scalars().all())


async def count_tests(
    db: AsyncSession,
    search: Optional[str] = None,
    series_id: Optional[int] = None,
    teacher_id: Optional[int] = None,
    book_id: Optional[int] = None,
    theme_id: Optional[int] = None
) -> int:
    """
    Count total number of active tests with filters.

    Args:
        db: Database session
        search: Search query for title or description
        series_id: Filter by series ID
        teacher_id: Filter by teacher ID
        book_id: Filter by book ID (via series)
        theme_id: Filter by theme ID (via series)

    Returns:
        Total count of tests matching filters
    """
    query = select(func.count(Test.id)).where(Test.is_active == True)

    # Apply same filters as get_all_tests
    if search:
        search_term = f"%{search}%"
        query = query.where(
            or_(
                Test.title.ilike(search_term),
                Test.description.ilike(search_term)
            )
        )

    if series_id:
        query = query.where(Test.series_id == series_id)

    if teacher_id:
        query = query.where(Test.teacher_id == teacher_id)

    # For book and theme filters, join with series
    if book_id or theme_id:
        query = query.join(Test.series)
        if book_id:
            query = query.where(LessonSeries.book_id == book_id)
        if theme_id:
            query = query.where(LessonSeries.theme_id == theme_id)

    result = await db.execute(query)
    return result.scalar_one()


async def get_test_by_id(db: AsyncSession, test_id: int) -> Optional[Test]:
    """
    Get test by ID with all relationships.

    Args:
        db: Database session
        test_id: Test ID

    Returns:
        Test object if found, None otherwise
    """
    result = await db.execute(
        select(Test)
        .options(
            selectinload(Test.series),
            selectinload(Test.teacher)
        )
        .where(Test.id == test_id, Test.is_active == True)
    )
    return result.scalar_one_or_none()


async def create_test(db: AsyncSession, test_data: TestCreate) -> Test:
    """
    Create a new test with auto-generated title and description if not provided.

    Args:
        db: Database session
        test_data: Test creation data

    Returns:
        Created test object
    """
    # Get series and book info for auto-generation
    series_result = await db.execute(
        select(LessonSeries)
        .options(selectinload(LessonSeries.book))
        .where(LessonSeries.id == test_data.series_id)
    )
    series = series_result.scalar_one_or_none()

    if not series:
        raise ValueError(f"Series with ID {test_data.series_id} not found")

    # Prepare test data
    test_dict = test_data.model_dump()

    # Auto-generate title if not provided
    if not test_dict.get('title'):
        series_name = f"{series.year} - {series.name}"
        if series.book:
            book_name = series.book.name
            test_dict['title'] = f"Тест по '{book_name}' - {series_name}"
        else:
            test_dict['title'] = f"Тест по {series_name}"

    # Create test
    test = Test(**test_dict)
    db.add(test)
    await db.commit()
    await db.refresh(test)

    # Load relationships
    await db.refresh(test, ["series", "teacher"])

    return test


async def update_test(
    db: AsyncSession,
    test_id: int,
    test_data: TestUpdate
) -> Optional[Test]:
    """
    Update a test.

    Args:
        db: Database session
        test_id: Test ID
        test_data: Test update data

    Returns:
        Updated test object or None if not found
    """
    test = await get_test_by_id(db, test_id)

    if not test:
        return None

    # Update only provided fields
    update_data = test_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(test, field, value)

    await db.commit()
    await db.refresh(test)

    # Load relationships
    await db.refresh(test, ["series", "teacher"])

    return test


async def delete_test(db: AsyncSession, test_id: int) -> bool:
    """
    Soft delete a test (set is_active to False).

    Args:
        db: Database session
        test_id: Test ID

    Returns:
        True if deleted, False if not found
    """
    test = await get_test_by_id(db, test_id)

    if not test:
        return False

    test.is_active = False
    await db.commit()

    return True


async def update_test_questions_count(db: AsyncSession, test_id: int) -> None:
    """
    Update the questions_count field for a test.

    Args:
        db: Database session
        test_id: Test ID
    """
    count_result = await db.execute(
        select(func.count(TestQuestion.id))
        .where(TestQuestion.test_id == test_id)
    )
    count = count_result.scalar_one()

    await db.execute(
        select(Test)
        .where(Test.id == test_id)
    )
    test = await get_test_by_id(db, test_id)
    if test:
        test.questions_count = count
        await db.commit()


# ============================================================
# TEST QUESTION CRUD OPERATIONS
# ============================================================

async def get_all_test_questions(
    db: AsyncSession,
    test_id: int,
    lesson_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 1000
) -> List[TestQuestion]:
    """
    Get all questions for a test.

    Args:
        db: Database session
        test_id: Test ID
        lesson_id: Optional filter by lesson ID (for personal tests)
        skip: Number of records to skip
        limit: Maximum number of records to return

    Returns:
        List of test questions
    """
    query = select(TestQuestion).options(
        selectinload(TestQuestion.lesson)
    ).where(TestQuestion.test_id == test_id)

    if lesson_id:
        query = query.where(TestQuestion.lesson_id == lesson_id)

    # Order by lesson_id and order
    query = query.order_by(TestQuestion.lesson_id, TestQuestion.order)

    # Apply pagination
    query = query.offset(skip).limit(limit)

    result = await db.execute(query)
    return list(result.scalars().all())


async def count_test_questions(
    db: AsyncSession,
    test_id: int,
    lesson_id: Optional[int] = None
) -> int:
    """
    Count total number of questions for a test.

    Args:
        db: Database session
        test_id: Test ID
        lesson_id: Optional filter by lesson ID

    Returns:
        Total count of questions
    """
    query = select(func.count(TestQuestion.id)).where(TestQuestion.test_id == test_id)

    if lesson_id:
        query = query.where(TestQuestion.lesson_id == lesson_id)

    result = await db.execute(query)
    return result.scalar_one()


async def get_test_question_by_id(
    db: AsyncSession,
    question_id: int
) -> Optional[TestQuestion]:
    """
    Get test question by ID with relationships.

    Args:
        db: Database session
        question_id: Question ID

    Returns:
        TestQuestion object if found, None otherwise
    """
    result = await db.execute(
        select(TestQuestion)
        .options(selectinload(TestQuestion.lesson))
        .where(TestQuestion.id == question_id)
    )
    return result.scalar_one_or_none()


async def create_test_question(
    db: AsyncSession,
    question_data: TestQuestionCreate
) -> TestQuestion:
    """
    Create a new test question.

    Args:
        db: Database session
        question_data: Question creation data

    Returns:
        Created question object
    """
    question = TestQuestion(**question_data.model_dump())
    db.add(question)
    await db.commit()
    await db.refresh(question)

    # Load relationships
    await db.refresh(question, ["lesson"])

    # Update test questions count
    await update_test_questions_count(db, question.test_id)

    return question


async def update_test_question(
    db: AsyncSession,
    question_id: int,
    question_data: TestQuestionUpdate
) -> Optional[TestQuestion]:
    """
    Update a test question.

    Args:
        db: Database session
        question_id: Question ID
        question_data: Question update data

    Returns:
        Updated question object or None if not found
    """
    question = await get_test_question_by_id(db, question_id)

    if not question:
        return None

    # Update only provided fields
    update_data = question_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(question, field, value)

    await db.commit()
    await db.refresh(question)

    # Load relationships
    await db.refresh(question, ["lesson"])

    return question


async def delete_test_question(db: AsyncSession, question_id: int) -> bool:
    """
    Delete a test question (hard delete).

    Args:
        db: Database session
        question_id: Question ID

    Returns:
        True if deleted, False if not found
    """
    question = await get_test_question_by_id(db, question_id)

    if not question:
        return False

    test_id = question.test_id
    await db.delete(question)
    await db.commit()

    # Update test questions count
    await update_test_questions_count(db, test_id)

    return True
