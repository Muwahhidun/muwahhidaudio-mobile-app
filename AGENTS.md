# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Build/Test Commands

### Backend
```bash
cd backend
docker-compose up -d                    # Start all services (PostgreSQL, Redis, API)
docker-compose exec api alembic revision --autogenerate -m "Description"  # Create migration
docker-compose exec api alembic upgrade head  # Apply migrations
docker-compose exec api python -m app.seed  # Seed test data
python test_api.py                       # Run API tests
python test_audio_streaming.py           # Test audio streaming with Range requests
```

### Mobile App
```bash
cd mobile_app
flutter pub get                         # Install dependencies
flutter pub run build_runner build --delete-conflicting-outputs  # Generate code
flutter run                             # Run on device/emulator
flutter test                            # Run widget tests
flutter analyze                         # Run static analysis
```

## Project Coding Rules (Non-Obvious Only)

### Backend
- Database sessions auto-commit via `get_db()` dependency - never call commit/rollback manually
- All models inherit `TimestampMixin` for created_at/updated_at (not explicit in model files)
- JWT tokens must include "type" field (access/refresh) - verification checks this field
- Use asyncpg driver (`postgresql+asyncpg://`) - sync drivers will fail
- Audio streaming endpoints must support Range requests (HTTP 206) for mobile seeking
- Audio file path stored in `Lesson.audio_path` field (NOT `audio_file_path`)
- Database migrations must be run from backend directory, not project root
- Redis uses separate databases: DB 0 for API cache, DB 1 for JWT sessions

### Mobile App
- Riverpod providers require code generation after model changes (`flutter packages pub run build_runner build`)
- API client uses Retrofit with code generation - modify `api_client.dart` then regenerate
- Authentication state persists via secure storage - tokens survive app restarts
- Audio player must use Range requests for seeking - backend requires HTTP 206 support
- Admin routes are hardcoded in main.dart but protected by auth state
- Android device uses local network IP (192.168.3.216:8000) - not localhost
- Generated files (.g.dart) should never be manually edited

### Code Generation Requirements
- After any model changes in mobile app, run: `flutter packages pub run build_runner build`
- API client regeneration required after modifying `api_client.dart`
- Backend Alembic autogenerate requires models imported in `app/models/__init__.py`

## Critical Architecture Patterns

### Audio Streaming
- Backend Range request support mandatory for mobile audio seeking
- Audio files stored in `backend/audio_files/` with original/ and processed/ subdirectories
- Mobile audio handler integrates audio_service with just_audio for background playback
- Audio URLs constructed as `${ApiConfig.baseUrl}${lesson.audioUrl}`

### Database Schema
- Tests table has UNIQUE constraint on `series_id` (one test per series)
- Critical cascade rules: lesson_series deletion RESTRICTED, user deletion CASCADES
- All list endpoints use pagination pattern: `{"items": [...], "total": X, "skip": Y, "limit": Z}`

### Authentication Flow
- JWT tokens include "type" field (access/refresh) - verification requires this
- Backend requires JWT_SECRET_KEY in production or fails silently
- Token refresh mechanism built into mobile app auth provider

## Critical API Issues

### Authentication Field Mismatch
- Backend login endpoint expects `login_or_email` field (defined in UserLogin schema)
- However, actual API implementation may expect `email` field instead
- Mobile app correctly sends `login_or_email` field (LoginRequest model)
- This mismatch causes 422 Unprocessable Entity errors during login
- Check both schema definition and actual endpoint implementation for consistency