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

### Mobile App Architecture
- Code generation required after model changes (build_runner) - compilation requirement
- API client uses Retrofit with code generation - architectural pattern for type safety
- Admin routes hardcoded in main.dart but protected by auth state (security layering)
- Generated files (.g.dart) should never be manually edited (build system constraint)