# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Debug Rules (Non-Obvious Only)

### Backend Debugging
- Database URL must use `postgresql+asyncpg://` protocol - sync drivers fail silently
- JWT_SECRET_KEY must be set in production or auth fails without error messages
- Redis connections fail silently if REDIS_HOST/PORT not configured
- Audio streaming Range requests return 200 instead of 206 if file not found
- Database sessions auto-commit - manual commit/rollback will cause errors

### Mobile App Debugging
- Code generation must be run after model changes or runtime errors occur
- API client regeneration required after modifying api_client.dart interface
- Authentication state persists across app restarts via secure storage
- Audio player seeking fails without proper Range request support from backend
- Admin routes exist in main.dart but are protected by auth state

### Test Debugging
- Backend tests are standalone scripts, not unit tests - run directly with Python
- Audio streaming tests require actual audio files in `audio_files/` directory
- API tests assume test user exists (test@example.com/password123)
- Mobile app widget tests use basic template - need expansion for actual testing