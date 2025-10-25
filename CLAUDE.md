# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Islamic Audio Lessons application - a monorepo containing a Flutter mobile app and FastAPI backend for streaming Islamic educational audio content.

## Repository Structure

```
muwahhidAudioApp/
├── backend/          # Python FastAPI REST API
└── mobile_app/       # Flutter mobile application
```

## Backend (FastAPI)

### Technology Stack
- FastAPI + uvicorn
- SQLAlchemy 2.0 (async) with asyncpg
- PostgreSQL 15
- Redis for caching
- Alembic for database migrations
- JWT authentication with python-jose

### Running Backend

```bash
cd backend

# Using Docker Compose (recommended)
docker-compose up -d              # Start all services (PostgreSQL, Redis, API)
docker-compose logs -f api        # View logs
docker-compose down               # Stop services

# Local development
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Database Migrations

```bash
# Create new migration
docker-compose exec api alembic revision --autogenerate -m "Description"

# Apply migrations
docker-compose exec api alembic upgrade head

# Rollback last migration
docker-compose exec api alembic downgrade -1

# View migration history
docker-compose exec api alembic history
```

### Seed Test Data

```bash
docker-compose exec api python -m app.seed
```

### Backend Architecture

**Layered Structure:**
- `app/main.py` - FastAPI application entry point, router registration
- `app/config.py` - Settings and environment variables
- `app/database.py` - SQLAlchemy async engine and session management
- `app/models/` - SQLAlchemy ORM models
- `app/schemas/` - Pydantic request/response schemas
- `app/crud/` - Database query functions (CRUD operations)
- `app/api/` - FastAPI route handlers
- `app/auth/` - JWT authentication logic and dependencies
- `alembic/` - Database migration files

**Content Hierarchy:**
The data model follows this hierarchy:
- **Theme** (e.g., Акыда, Сира, Фикх, Адаб)
  - **BookAuthor** (classical Islamic scholars)
    - **Book** (Islamic books being studied)
      - **LessonSeries** (taught by a LessonTeacher in a specific year)
        - **Lesson** (individual audio lesson with MP3 file)

Key relationships:
- Books belong to Themes and BookAuthors
- LessonSeries belong to Books, Themes, and LessonTeachers
- Lessons belong to LessonSeries (and denormalized to Book, Theme, Teacher for faster queries)

**Important Models:**
- `content.py` - Theme, BookAuthor, Book
- `lesson.py` - LessonTeacher, LessonSeries, Lesson
- `user.py` - User authentication
- `bookmark.py` - User bookmarks for lessons
- `test.py` - Tests and questions for lessons
- `feedback.py` - User feedback

**API Endpoints:**
- Authentication: `/api/auth/*` - register, login, user profile
- Content: `/api/themes`, `/api/books`, `/api/book-authors`
- Lessons: `/api/teachers`, `/api/series`, `/api/lessons`
- Audio: `/api/lessons/{id}/audio` - streaming with Range request support
- Admin: `/api/migration/*` - migration utilities

### Testing Backend

```bash
# Test API endpoints
python test_api.py
python test_content_api.py
python test_audio_streaming.py
```

## Mobile App (Flutter)

### Technology Stack
- Flutter SDK 3.8.1+
- Riverpod for state management
- Retrofit + Dio for HTTP/API
- just_audio + audio_service for audio playback
- flutter_secure_storage for token storage
- Hive for local caching

### Running Mobile App

```bash
cd mobile_app

# Install dependencies
flutter pub get

# Generate code (for Riverpod, Retrofit, JSON serialization, Hive)
flutter pub run build_runner build --delete-conflicting-outputs

# Run on connected device/emulator
flutter run

# Build APK
flutter build apk --release

# Run tests
flutter test
```

### Mobile App Architecture

**Clean Architecture with Feature-based Organization:**
- `lib/main.dart` - App entry point, ProviderScope wrapper, routing
- `lib/config/` - API configuration and app constants
- `lib/core/theme/` - App theming
- `lib/data/` - Data layer
  - `api/` - Retrofit API client definitions
  - `models/` - JSON serializable data models
  - `repositories/` (not yet implemented)
- `lib/presentation/` - Presentation layer
  - `providers/` - Riverpod providers for state management
  - `screens/` - UI screens organized by feature
    - `auth/` - Login, register screens
    - `home/` - Home screen
    - `themes/` - Theme browsing
    - `admin/` - Admin panel for content management
  - `widgets/` (not yet implemented)

**Key Patterns:**
- Riverpod providers manage API calls and state
- Retrofit generates type-safe API clients
- Models use json_serializable for JSON conversion
- Authentication state is managed globally via `authProvider`
- Conditional routing: authenticated users see HomeScreen, others see LoginScreen

**Admin Features:**
The app includes an admin panel (`/admin` route) for managing:
- Themes
- Books and Book Authors
- Teachers
- Lesson Series

### Code Generation

The mobile app uses code generation for:
- Riverpod providers (riverpod_generator)
- JSON serialization (json_serializable)
- Retrofit API clients (retrofit_generator)
- Hive type adapters (hive_generator)

Always run `flutter pub run build_runner build --delete-conflicting-outputs` after:
- Adding/modifying Riverpod providers with annotations
- Changing data models with @JsonSerializable
- Updating Retrofit API interface
- Creating new Hive type adapters

## Development Workflow

### Adding New API Endpoint

1. Backend:
   - Define Pydantic schemas in `backend/app/schemas/`
   - Add CRUD functions in `backend/app/crud/`
   - Create route handler in `backend/app/api/`
   - Register router in `backend/app/main.py`

2. Mobile:
   - Add endpoint to Retrofit client in `mobile_app/lib/data/api/api_client.dart`
   - Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`
   - Create/update provider in `mobile_app/lib/presentation/providers/`
   - Use provider in UI screens

### Database Schema Changes

1. Modify models in `backend/app/models/`
2. Ensure models are imported in `backend/app/models/__init__.py`
3. Create migration: `docker-compose exec api alembic revision --autogenerate -m "Description"`
4. Review generated migration in `backend/alembic/versions/`
5. Apply migration: `docker-compose exec api alembic upgrade head`
6. Update corresponding Pydantic schemas and Flutter models

## API Documentation

Backend API docs are available when the server is running:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Environment Configuration

Backend uses `.env` file (copy from `.env.example`):
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_HOST`, `REDIS_PORT` - Redis configuration
- `JWT_SECRET_KEY` - Secret for JWT tokens
- `ALLOWED_ORIGINS` - CORS allowed origins

Mobile app uses `lib/config/api_config.dart` for API base URL configuration.

## Database Access

```bash
# PostgreSQL
docker-compose exec db psql -U postgres -d audio_lessons

# Redis
docker-compose exec redis redis-cli
```

## Utility Scripts

Backend includes utility scripts in the root:
- `apply_migration.py` - Apply migrations programmatically
- `apply_migration_direct.py` - Direct migration application
- `fix_series_data.py` - Data cleanup scripts
- `clean_duplicates.py` - Remove duplicate entries
- `generate_test_audio.py` - Generate test audio files

## Audio Files

Audio lessons are stored in `backend/audio_files/` and served via streaming endpoint with Range request support for seeking.
