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

### Mobile App Specifics
- Code generation required after model changes (build_runner)
- API client uses Retrofit with code generation
- Admin routes hardcoded in main.dart but protected by auth state
- Generated files (.g.dart) should never be manually edited