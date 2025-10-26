"""
Lessons API endpoints.
"""
import os
import tempfile
import shutil
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Request, Query, UploadFile, File
from fastapi.responses import StreamingResponse, FileResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.api.auth import get_current_user
from app.models import User
from app.schemas.lesson import (
    LessonWithRelations,
    LessonSeriesNested,
    TeacherNested,
    BookNested,
    ThemeNested,
    LessonCreate,
    LessonUpdate
)
from app.crud import lesson as lesson_crud
from app.utils.audio import (
    get_audio_file_path,
    parse_range_header,
    get_content_range_header,
    get_chunk_size
)
from app.utils.audio_processing import (
    process_audio_file,
    delete_audio_files
)

router = APIRouter(prefix="/lessons", tags=["Lessons"])


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Require admin role."""
    if current_user.role.level < 2:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user


def build_lesson_with_relations(lesson) -> LessonWithRelations:
    """Helper function to build LessonWithRelations from Lesson model."""
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


@router.get("")
async def get_all_lessons(
    search: Optional[str] = Query(None, description="Search by title, description or tags"),
    series_id: Optional[int] = Query(None, description="Filter by series ID"),
    teacher_id: Optional[int] = Query(None, description="Filter by teacher ID"),
    book_id: Optional[int] = Query(None, description="Filter by book ID"),
    theme_id: Optional[int] = Query(None, description="Filter by theme ID"),
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(10, ge=1, le=1000, description="Maximum number of records to return"),
    include_inactive: bool = Query(False, description="Include inactive lessons (admin only)"),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all active lessons with filters and pagination.

    Returns:
        Dictionary with lessons list, total count, skip, and limit
    """
    # Get total count
    total = await lesson_crud.count_lessons(
        db,
        search=search,
        series_id=series_id,
        teacher_id=teacher_id,
        book_id=book_id,
        theme_id=theme_id,
        include_inactive=include_inactive
    )

    # Get lessons
    lessons = await lesson_crud.get_all_lessons(
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
        "items": [build_lesson_with_relations(lesson) for lesson in lessons],
        "total": total,
        "skip": skip,
        "limit": limit
    }


@router.post("", response_model=LessonWithRelations, status_code=status.HTTP_201_CREATED)
async def create_lesson(
    lesson_data: LessonCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Create a new lesson (admin only).

    Args:
        lesson_data: Lesson creation data

    Returns:
        Created lesson object with relationships
    """
    lesson = await lesson_crud.create_lesson(db, lesson_data)
    return build_lesson_with_relations(lesson)


@router.put("/{lesson_id}", response_model=LessonWithRelations)
async def update_lesson(
    lesson_id: int,
    lesson_data: LessonUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Update a lesson (admin only).

    Args:
        lesson_id: Lesson ID
        lesson_data: Lesson update data

    Returns:
        Updated lesson object with relationships
    """
    lesson = await lesson_crud.update_lesson(db, lesson_id, lesson_data)

    if not lesson:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesson not found"
        )

    return build_lesson_with_relations(lesson)


@router.delete("/{lesson_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_lesson(
    lesson_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Delete a lesson (admin only).

    Args:
        lesson_id: Lesson ID

    Returns:
        No content
    """
    deleted = await lesson_crud.delete_lesson(db, lesson_id)

    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesson not found"
        )


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

    return build_lesson_with_relations(lesson)


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


# ============================================
# Audio Upload/Management Endpoints
# ============================================

@router.post("/{lesson_id}/audio", status_code=status.HTTP_200_OK)
async def upload_lesson_audio(
    lesson_id: int,
    audio_file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """
    Upload and process audio file for a lesson (Admin only).

    Maximum file size: 200 MB
    Supported formats: mp3, wav, m4a, ogg, flac, etc.

    Processing:
    - Saves original file to original/ directory
    - Converts to MP3, mono, 64 kbps
    - Normalizes volume
    - Auto-detects duration
    - Saves processed file to processed/ directory
    """
    # Check lesson exists
    lesson = await lesson_crud.get_lesson_by_id(db, lesson_id)
    if not lesson:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesson not found"
        )

    # Validate file size (200 MB max)
    MAX_FILE_SIZE = 200 * 1024 * 1024  # 200 MB in bytes

    # Save uploaded file to temporary location
    with tempfile.NamedTemporaryFile(delete=False, suffix=f"_{audio_file.filename}") as temp_file:
        try:
            # Read and write in chunks to handle large files
            file_size = 0
            chunk_size = 1024 * 1024  # 1 MB chunks

            while True:
                chunk = await audio_file.read(chunk_size)
                if not chunk:
                    break
                file_size += len(chunk)

                # Check file size during upload
                if file_size > MAX_FILE_SIZE:
                    temp_file.close()
                    os.unlink(temp_file.name)
                    raise HTTPException(
                        status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                        detail=f"File too large. Maximum size is 200 MB"
                    )

                temp_file.write(chunk)

            temp_file_path = temp_file.name
        except Exception as e:
            temp_file.close()
            if os.path.exists(temp_file.name):
                os.unlink(temp_file.name)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error uploading file: {str(e)}"
            )

    try:
        # Delete old audio files if they exist
        if lesson.original_audio_path or lesson.audio_path:
            delete_audio_files(lesson.original_audio_path, lesson.audio_path)

        # Process audio file
        original_path, processed_path, duration = process_audio_file(
            temp_file_path,
            audio_file.filename
        )

        # Update lesson in database
        lesson_update = LessonUpdate(
            original_audio_path=original_path,
            audio_path=processed_path,
            duration_seconds=duration
        )
        updated_lesson = await lesson_crud.update_lesson(db, lesson_id, lesson_update)

        return {
            "message": "Audio uploaded and processed successfully",
            "original_path": original_path,
            "processed_path": processed_path,
            "duration_seconds": duration,
            "lesson_id": lesson_id
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error processing audio: {str(e)}"
        )
    finally:
        # Clean up temporary file
        if os.path.exists(temp_file_path):
            os.unlink(temp_file_path)


@router.put("/{lesson_id}/audio", status_code=status.HTTP_200_OK)
async def replace_lesson_audio(
    lesson_id: int,
    audio_file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """
    Replace existing audio file for a lesson (Admin only).

    Same as upload - deletes old files and processes new ones.
    """
    # This is identical to upload, so just call it
    return await upload_lesson_audio(lesson_id, audio_file, db, current_user)


@router.delete("/{lesson_id}/audio", status_code=status.HTTP_200_OK)
async def delete_lesson_audio(
    lesson_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """
    Delete audio files for a lesson (Admin only).

    Removes both original and processed audio files.
    Updates lesson to remove audio paths and duration.
    """
    # Check lesson exists
    lesson = await lesson_crud.get_lesson_by_id(db, lesson_id)
    if not lesson:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesson not found"
        )

    # Check if lesson has audio
    if not lesson.audio_path and not lesson.original_audio_path:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lesson has no audio files"
        )

    try:
        # Delete audio files
        delete_audio_files(lesson.original_audio_path, lesson.audio_path)

        # Update lesson in database
        lesson_update = LessonUpdate(
            original_audio_path=None,
            audio_path=None,
            duration_seconds=None
        )
        await lesson_crud.update_lesson(db, lesson_id, lesson_update)

        return {
            "message": "Audio files deleted successfully",
            "lesson_id": lesson_id
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deleting audio: {str(e)}"
        )
