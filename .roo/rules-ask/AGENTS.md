# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Documentation Rules (Non-Obvious Only)

### Project Structure
- This is a dual-stack application: Flutter mobile app + FastAPI backend
- Backend uses async patterns exclusively (SQLAlchemy 2.0, asyncpg, async/await)
- Mobile app uses Riverpod for state management - not other state management solutions
- Audio streaming requires HTTP 206 Range requests for mobile player seeking

### Database Architecture
- All models inherit TimestampMixin automatically (created_at/updated_at fields)
- Database sessions auto-commit via get_db() dependency - never manual commit/rollback
- Critical cascade rules: lesson_series deletion RESTRICTED, user deletion CASCADES
- Redis uses separate databases: DB 0 for API cache, DB 1 for JWT sessions
- Audio files stored in filesystem with database references (not in database)

### Authentication Flow
- JWT tokens include "type" field (access/refresh) - verification checks this
- Mobile app stores tokens in secure storage - persists across app restarts
- Backend requires JWT_SECRET_KEY in production or fails silently
- Token refresh mechanism built into mobile app auth provider

### API Patterns
- All endpoints use `/api` prefix (configured in settings)
- Lessons API includes nested relationship data to minimize round-trips
- Audio streaming endpoints support Range requests for mobile seeking
- CORS uses regex pattern in debug mode to allow any localhost port
- Pagination pattern: `{"items": [...], "total": X, "skip": Y, "limit": Z}`

### Mobile App Specifics
- Code generation required after model changes (build_runner)
- API client uses Retrofit with code generation
- Admin routes hardcoded in main.dart but protected by auth state
- Generated files (.g.dart) should never be manually edited
- Platform-specific API URLs: localhost for web/iOS, hardcoded IP for Android

### Content Organization
- Audio files in backend/audio_files/ with original/ and processed/ subdirectories
- Content hierarchy: Theme → BookAuthor → Book → LessonSeries → Lesson
- Tests table has UNIQUE constraint on series_id (one test per series)
- Lesson model uses `audio_path` field (NOT `audio_file_path`)

### Authentication Field Mismatch
- Backend login endpoint expects `login_or_email` field (defined in UserLogin schema)
- However, actual API implementation may expect `email` field instead
- Mobile app correctly sends `login_or_email` field (LoginRequest model)
- This mismatch causes 422 Unprocessable Entity errors during login
- Check both schema definition and actual endpoint implementation for consistency