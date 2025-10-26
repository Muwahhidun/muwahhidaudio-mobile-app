# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Coding Rules (Non-Obvious Only)

### Backend
- Database sessions auto-commit via `get_db()` dependency - never call commit/rollback manually
- All models inherit `TimestampMixin` for created_at/updated_at (not explicit in model files)
- JWT tokens must include "type" field (access/refresh) - verification checks this field
- Use asyncpg driver (`postgresql+asyncpg://`) - sync drivers will fail
- Audio streaming endpoints must support Range requests (HTTP 206) for mobile seeking

### Mobile App
- Riverpod providers require code generation after model changes (`flutter packages pub run build_runner build`)
- API client uses Retrofit with code generation - modify `api_client.dart` then regenerate
- Authentication state persists via secure storage - tokens survive app restarts
- Audio player must use Range requests for seeking - backend requires HTTP 206 support
- Admin routes are hardcoded in main.dart but protected by auth state

### Code Generation Requirements
- After any model changes in mobile app, run: `flutter packages pub run build_runner build`
- Generated files (.g.dart) should never be manually edited
- API client regeneration required after modifying `api_client.dart`