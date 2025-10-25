"""
Lessons API endpoints.
"""
import os
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.responses import StreamingResponse, FileResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.lesson import LessonWithRelations, LessonSeriesNested, TeacherNested, BookNested, ThemeNested
from app.crud import lesson as lesson_crud
from app.utils.audio import (
    get_audio_file_path,
    parse_range_header,
    get_content_range_header,
    get_chunk_size
)

router = APIRouter(prefix="/lessons", tags=["Lessons"])


@router.get("/{lesson_id}", response_model=LessonWithRelations)
async def get_lesson(lesson_id: int, db: AsyncSession = Depends(get_db)):
    """
    Get lesson by ID with all related info.

    Args:
        lesson_id: Lesson ID

    Returns:
        Lesson object with series, teacher, book, theme info
    """
    lesson = await lesson_crud.get_lesson_by_id(db, lesson_id)

    if not lesson:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesson not found"
        )

    # Build nested schemas
    series_nested = None
    if lesson.series:
        series_nested = LessonSeriesNested(
            id=lesson.series.id,
            name=lesson.series.name,
            year=lesson.series.year,
            display_name=f"{lesson.series.year} - {lesson.series.name}"
        )

    teacher_nested = None
    if lesson.teacher:
        teacher_nested = TeacherNested(
            id=lesson.teacher.id,
            name=lesson.teacher.name
        )

    book_nested = None
    if lesson.book:
        book_nested = BookNested(
            id=lesson.book.id,
            name=lesson.book.name
        )

    theme_nested = None
    if lesson.theme:
        theme_nested = ThemeNested(
            id=lesson.theme.id,
            name=lesson.theme.name
        )

    # Prepare lesson data excluding relationship fields
    lesson_data = {
        key: value for key, value in lesson.__dict__.items()
        if key not in ('series', 'teacher', 'book', 'theme', '_sa_instance_state')
    }

    return LessonWithRelations(
        **lesson_data,
        display_title=lesson_crud.get_display_title(lesson),
        formatted_duration=lesson_crud.format_duration(lesson.duration_seconds),
        audio_url=lesson_crud.get_audio_url(lesson.id),
        tags_list=lesson_crud.parse_tags(lesson.tags),
        series=series_nested,
        teacher=teacher_nested,
        book=book_nested,
        theme=theme_nested
    )


@router.get("/{lesson_id}/audio")
async def stream_audio(
    lesson_id: int,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    """
    Stream audio file with Range request support.

    Supports HTTP Range requests for partial content delivery,
    which is essential for audio streaming and seeking.

    Args:
        lesson_id: Lesson ID
        request: FastAPI request object (for Range header)

    Returns:
        StreamingResponse with audio/mpeg content
    """
    # Check if lesson exists
    lesson = await lesson_crud.get_lesson_by_id(db, lesson_id)
    if not lesson:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesson not found"
        )

    # Get audio file path
    audio_path = get_audio_file_path(lesson_id)
    if not audio_path:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Audio file not found"
        )

    # Get file size
    file_size = os.path.getsize(audio_path)

    # Check for Range header
    range_header = request.headers.get("Range")

    # No range request - return full file
    if not range_header:
        def iterfile():
            with open(audio_path, "rb") as f:
                chunk_size = get_chunk_size()
                while chunk := f.read(chunk_size):
                    yield chunk

        return StreamingResponse(
            iterfile(),
            media_type="audio/mpeg",
            headers={
                "Accept-Ranges": "bytes",
                "Content-Length": str(file_size),
            }
        )

    # Parse range header
    range_data = parse_range_header(range_header, file_size)
    if not range_data:
        raise HTTPException(
            status_code=status.HTTP_416_REQUESTED_RANGE_NOT_SATISFIABLE,
            detail="Invalid range"
        )

    start, end = range_data
    content_length = end - start + 1

    # Stream partial content
    def iterfile_partial():
        with open(audio_path, "rb") as f:
            f.seek(start)
            remaining = content_length
            chunk_size = get_chunk_size()

            while remaining > 0:
                read_size = min(chunk_size, remaining)
                chunk = f.read(read_size)
                if not chunk:
                    break
                remaining -= len(chunk)
                yield chunk

    return StreamingResponse(
        iterfile_partial(),
        status_code=status.HTTP_206_PARTIAL_CONTENT,
        media_type="audio/mpeg",
        headers={
            "Content-Range": get_content_range_header(start, end, file_size),
            "Accept-Ranges": "bytes",
            "Content-Length": str(content_length),
        }
    )
