# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Architecture Rules (Non-Obvious Only)

### System Architecture
- Dual-stack application: Flutter mobile app + FastAPI backend with PostgreSQL + Redis
- Backend uses async patterns exclusively (SQLAlchemy 2.0, asyncpg, async/await)
- Mobile app uses Riverpod for state management - architectural decision, not configurable
- Audio streaming requires HTTP 206 Range requests for mobile player seeking capability

### Database Architecture Constraints
- All models inherit TimestampMixin automatically (created_at/updated_at fields)
- Database sessions auto-commit via get_db() dependency - manual commit/rollback breaks architecture
- Critical cascade rules: lesson_series deletion RESTRICTED, user deletion CASCADES
- Redis uses separate databases: DB 0 for API cache, DB 1 for JWT sessions (architectural separation)
- Audio files stored in filesystem with database references (not BLOB storage)

### Authentication Architecture
- JWT tokens include "type" field (access/refresh) - verification requires this field
- Mobile app stores tokens in secure storage - persists across app restarts by design
- Backend requires JWT_SECRET_KEY in production or fails silently (security constraint)
- Token refresh mechanism built into mobile app auth provider (state management pattern)

### API Architecture Patterns
- All endpoints use `/api` prefix (configured in settings)
- Lessons API includes nested relationship data to minimize round-trips (performance decision)
- Audio streaming endpoints support Range requests for mobile seeking (mobile requirement)
- CORS uses regex pattern in debug mode to allow any localhost port (development flexibility)
- Pagination pattern: `{"items": [...], "total": X, "skip": Y, "limit": Z}` across all list endpoints

### Mobile App Architecture
- Code generation required after model changes (build_runner) - compilation requirement
- API client uses Retrofit with code generation - architectural pattern for type safety
- Admin routes hardcoded in main.dart but protected by auth state (security layering)
- Generated files (.g.dart) should never be manually edited (build system constraint)
- Audio handler integrates audio_service with just_audio for background playback
- Platform-specific API URLs: localhost for web/iOS, hardcoded IP for Android device

### Content Hierarchy Architecture
- Theme → BookAuthor → Book → LessonSeries → Lesson (strict hierarchical relationship)
- Tests table has UNIQUE constraint on series_id (one test per series rule)
- Lesson model denormalizes references to Book, Theme, Teacher for query performance
- Audio files organized in original/ and processed/ subdirectories for workflow separation

### Authentication Architecture Issues
- Backend login endpoint expects `login_or_email` field (defined in UserLogin schema)
- However, actual API implementation may expect `email` field instead
- Mobile app correctly sends `login_or_email` field (LoginRequest model)
- This mismatch causes 422 Unprocessable Entity errors during login
- Check both schema definition and actual endpoint implementation for consistency