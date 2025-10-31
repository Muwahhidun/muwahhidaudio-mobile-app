# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Debug Rules (Non-Obvious Only)

### Backend Debugging
- Database URL must use `postgresql+asyncpg://` protocol - sync drivers fail silently
- JWT_SECRET_KEY must be set in production or auth fails without error messages
- Redis connections fail silently if REDIS_HOST/PORT not configured
- Audio streaming Range requests return 200 instead of 206 if file not found
- Database sessions auto-commit - manual commit/rollback will cause errors
- CORS allows extensive localhost ports (3000-3139, 4000-4030) - check if your port is included
- Alembic migrations require models imported in `app/models/__init__.py` or changes won't be detected

### Mobile App Debugging
- Code generation must be run after model changes or runtime errors occur
- API client regeneration required after modifying api_client.dart interface
- Authentication state persists across app restarts via secure storage
- Audio player seeking fails without proper Range request support from backend
- Admin routes exist in main.dart but are protected by auth state
- Android device uses hardcoded IP (192.168.3.216:8000) - won't work with localhost
- Web platform uses different audio service initialization (disabled in main.dart)

### Test Debugging
- Backend tests are standalone scripts, not unit tests - run directly with Python
- Audio streaming tests require actual audio files in `audio_files/` directory
- API tests assume test user exists (test@example.com/password123)
- Mobile app widget tests use basic template - need expansion for actual testing
- Docker containers must be healthy before running integration tests
- Database migrations must be applied before running API tests

### Common Issues
- Backend returns 500 errors if `Lesson.audio_path` field name is incorrect
- Mobile app crashes on audio playback if backend doesn't support Range requests
- Admin screens won't load data without proper authentication headers
- Code generation fails if models have circular dependencies
- Alembic doesn't detect model changes without proper imports in __init__.py

### Authentication Field Mismatch
- Backend login endpoint expects `login_or_email` field (defined in UserLogin schema)
- However, actual API implementation may expect `email` field instead
- Mobile app correctly sends `login_or_email` field (LoginRequest model)
- This mismatch causes 422 Unprocessable Entity errors during login
- Check both schema definition and actual endpoint implementation for consistency