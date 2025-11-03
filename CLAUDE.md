# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Islamic Audio Lessons application - a monorepo containing a Flutter mobile app and FastAPI backend for streaming Islamic educational audio content.

## Development Tools

### MCP Servers

This project uses multiple MCP servers for enhanced AI-assisted development:

**Configuration:** `.mcp.json` (in project root)
```json
{
  "mcpServers": {
    "dart": {
      "command": "dart",
      "args": ["mcp-server", "--force-roots-fallback"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp", "--api-key", "..."]
    }
  }
}
```

**Dart MCP Server** ([docs](https://docs.flutter.dev/ai/mcp-server)):
- Requirements: Dart SDK 3.9.2+, Flutter 3.35.7+
- Code analysis and error fixing
- Symbol resolution and navigation
- Application introspection
- Package search on pub.dev
- Dependency management
- Test execution and analysis
- Dart code formatting

**Context7 MCP Server**:
- Retrieves up-to-date documentation for any library
- Use when working with unfamiliar packages or APIs

**Note:** MCP configuration is committed for team-wide use. Local settings (`.claude/settings.local.json`) are gitignored.

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
- Admin: `/api/migration/*` - migration utilities, `/api/statistics` - admin dashboard statistics
- Tests: `/api/tests` - tests and questions for lesson series (one test per series)

**Pagination Architecture:**

All list API endpoints support pagination with a consistent pattern:

Backend:
- All CRUD modules have `count_*()` methods using `func.count()`
- All `get_all_*()` methods accept `skip` and `limit` parameters
- Endpoints return: `{"items": [...], "total": X, "skip": Y, "limit": Z}`
- Query parameters: `skip` (offset, default 0), `limit` (max records, default 100)

Example CRUD pattern:
```python
async def count_themes(db, search=None, include_inactive=False) -> int:
    query = select(func.count(Theme.id))
    # Apply filters
    return await db.scalar(query)

async def get_all_themes(db, search=None, include_inactive=False, skip=0, limit=100):
    query = select(Theme)
    # Apply filters
    query = query.offset(skip).limit(limit)
    return await db.scalars(query)
```

Frontend:
- Generic `PaginatedResponse<T>` model in `lib/data/models/paginated_response.dart`
- Retrofit API client returns `Future<PaginatedResponse<Model>>`
- Providers extract `.items` from paginated response
- Admin screens use direct Dio calls with pagination state management

**Business Rules:**
- Tests table has UNIQUE constraint on `series_id` (one test per series)
- Lesson model uses `audio_path` field (NOT `audio_file_path`)

### Testing Backend

```bash
# Test API endpoints
python test_api.py
python test_content_api.py
python test_audio_streaming.py
```

## Mobile App (Flutter)

### Technology Stack
- Flutter SDK 3.35.7+ (Dart SDK 3.9.2+)
- Riverpod for state management (riverpod_generator for code generation)
- Retrofit + Dio for HTTP/API (retrofit_generator for code generation)
- just_audio + audio_service for background audio playback
- sqflite for local SQLite database (offline mode)
- path_provider for file system access
- flutter_secure_storage for JWT token storage
- shared_preferences for user preferences
- json_serializable for model serialization
- logger for structured logging
- file_picker + permission_handler for file operations
- flutter_local_notifications for download progress notifications
- app_badge_plus for app badge counter (shows active downloads)

### Running Mobile App

```bash
cd mobile_app

# Install dependencies
flutter pub get

# Generate code (for Riverpod, Retrofit, JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs

# Run on connected device/emulator
flutter run

# Run on Chrome (web) with custom port
flutter run -d chrome --web-port=3064

# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Run tests
flutter test

# Run static analysis
flutter analyze
```

### Android Build Configuration

Key settings in `mobile_app/android/app/build.gradle.kts`:
- `minSdk = 24` - Required for audio_service package
- `compileSdk` and `targetSdk` - Inherited from Flutter settings
- Java/Kotlin compatibility: `JavaVersion.VERSION_11`
- Core library desugaring enabled for newer Java APIs on older Android versions
- ProGuard/R8 disabled in release builds (`isMinifyEnabled = false`) to prevent notification icon stripping
- NDK version: 27.0.12077973

Important: The app uses Kotlin Gradle DSL (`.gradle.kts` files) instead of Groovy (`.gradle`).

### Mobile App Architecture

**Clean Architecture with Feature-based Organization:**
- `lib/main.dart` - App entry point, ProviderScope wrapper, routing, global audio handler
- `lib/config/` - API configuration and app constants
- `lib/core/` - Core functionality
  - `theme/` - App theming with light/dark modes
  - `audio/` - Audio playback system (see Audio Architecture below)
  - `database/` - SQLite database helper (singleton pattern)
  - `download/` - Download manager for offline audio files
  - `notifications/` - Notification service for download progress and app badges
  - `constants/` - App-wide constants including `app_icons.dart`
  - `logger.dart` - Structured logging using logger package
- `lib/data/` - Data layer
  - `api/` - Retrofit API client definitions
  - `models/` - JSON serializable data models including `downloaded_lesson.dart`
  - `repositories/` (not yet implemented)
- `lib/presentation/` - Presentation layer
  - `providers/` - Riverpod providers for state management
  - `screens/` - UI screens organized by feature
    - `auth/` - Login, register screens
    - `home/` - Home screen
    - `themes/` - Theme browsing
    - `admin/` - Admin panel for content management
    - `lessons/` - Lessons list with download functionality
    - `series/` - Series list with bulk download
  - `widgets/` - Reusable UI components including `mini_player.dart`

**Key Patterns:**
- Riverpod providers manage API calls and state
- Retrofit generates type-safe API clients
- Models use json_serializable for JSON conversion
- Authentication state is managed globally via `authProvider`
- Theme switching via `themeProvider` (light/dark modes)
- Conditional routing: authenticated users see HomeScreen, others see LoginScreen
- **UI Icons Pattern**: All icons defined in `lib/core/constants/app_icons.dart`
  - Use `AppIcons.theme`, `AppIcons.book`, `AppIcons.teacher` (mic icon), etc.
  - Each model has associated icon + color constant
  - Ensures UI consistency across the app

**Audio Architecture:**

The app uses a cross-platform audio system with platform-specific implementations:

- **Mobile (Android/iOS)**: `audio_service` + `just_audio`
  - Background playback with system media controls
  - Global `audioHandler` instance in `main.dart`
  - **Eager initialization**: `AudioService.init()` called in `main()` before `runApp()` to ensure notification infrastructure is ready
  - Initial playback state set with Play button to enable Android 12+ notification display
  - `LessonAudioHandler` (extends `BaseAudioHandler`) in `lib/core/audio/audio_handler_mobile.dart`:
    - Manages playlist and current lesson index
    - Handles play/pause, seek, skip, rewind/forward (10s)
    - Auto-plays next lesson on completion
    - Broadcasts state to system media controls
    - Custom notification with lesson metadata (book, teacher, lesson number)
    - Requests notification permission for Android 13+
  - System controls: Previous, Rewind 10s, Play/Pause, Forward 10s, Next, Close (stop)

- **Web**: Custom implementation using browser MediaSession API
  - `lib/core/audio/audio_service_web.dart` provides web-compatible audio service
  - `lib/core/audio/media_session_web.dart` for browser media controls

- **Common Pattern**:
  - Call `playLesson(lesson: lesson, playlist: allLessons)` to start playback
  - Audio streams from backend: `${ApiConfig.baseUrl}${lesson.audioUrl}`
  - **Offline playback priority**: Audio handler checks for local files first via `DownloadManager.getLocalFilePath()`, falls back to streaming if not downloaded
  - MiniPlayer widget (`lib/presentation/widgets/mini_player.dart`) shows on all screens when audio is playing
  - MiniPlayer uses global `RouteObserver` to persist across navigation

**Offline Mode Architecture:**

The app supports full offline functionality with local audio file downloads and SQLite storage:

- **SQLite Database** (`lib/core/database/database_helper.dart`):
  - Singleton pattern with `muwahhid_audio.db` in app documents directory
  - Table: `downloaded_lessons` (lesson_id, file_path, file_size, download_date, status)
  - Tracks download metadata and completion status
  - Methods: `insertDownloadedLesson()`, `getDownloadedLesson()`, `getAllDownloadedLessons()`, `isLessonDownloaded()`, `deleteDownloadedLesson()`

- **Download Manager** (`lib/core/download/download_manager.dart`):
  - Handles file downloads using Dio with progress callbacks
  - Stores audio files in `ApplicationDocumentsDirectory/downloaded_lessons/lesson_{id}.mp3`
  - Returns `Stream<DownloadProgress>` for real-time progress updates
  - Supports cancellation via `CancelToken`
  - Methods: `downloadLesson()`, `cancelDownload()`, `deleteDownload()`, `getLocalFilePath()`, `isLessonDownloaded()`

- **Download Provider** (`lib/presentation/providers/download_provider.dart`):
  - Riverpod state management for downloads
  - Tracks active downloads with progress: `Map<int, DownloadProgress> activeDownloads`
  - Tracks completed downloads: `Map<int, bool> downloadedLessons`
  - Series operations: `downloadSeries()`, `cancelSeriesDownload()`, `deleteSeriesDownload()`, `getSeriesDownloadStats()`
  - Helper providers: `isLessonDownloadedProvider`, `isLessonDownloadingProvider`, `downloadProgressProvider`

- **Download UI Pattern**:
  - **Individual lessons**: Download button on each lesson card with progress indicator
  - **Series download**: Download button on series cards (downloads all lessons in series)
  - **Bulk download**: AppBar button in LessonsScreen with badge showing downloaded count
  - **Download states**: Download icon → CircularProgressIndicator with cancel button → Download_done icon (green)
  - **Critical performance fix**: Avoid eager loading in list builders (caused SeriesScreen freeze). Load lessons only when user taps download button.

- **Metadata Caching** (`lib/core/database/database_helper.dart`):
  - **Cached Tables**: `cached_themes`, `cached_book_authors`, `cached_books`, `cached_teachers`, `cached_series`, `cached_lessons`
  - **Purpose**: Cache lightweight metadata (not audio files) for offline browsing
  - **Cache Methods**: `cacheTheme()`, `cacheBook()`, `cacheTeacher()`, `cacheSeries()`, `cacheLessonsBatch()`
  - **Query Methods**: `getCachedThemes()`, `getCachedBooks()`, `getCachedTeachers()`, `getCachedSeries()`, `getCachedLessonsForSeries()`
  - **Cache Management**: `hasCachedData()`, `clearAllCache()`
  - **Important**: Lesson API doesn't include `series_id` field - must be injected from context before caching

- **Synchronization Service** (`lib/core/sync/sync_service.dart`):
  - Singleton service for syncing metadata from API to local SQLite cache
  - **syncAllData()**: Downloads all themes, books, authors, teachers, series, and lesson metadata
  - **syncSeriesLessons(seriesId)**: Sync lessons for a specific series
  - **API Note**: `/series/{id}/lessons` endpoint returns direct List `[...]`, not paginated `{"items": []}`
  - **Auto-sync Triggers**: App start (if authenticated), connectivity restore (if cache empty)
  - **Progress Callbacks**: Provides step-by-step progress updates (e.g., "Синхронизация тем...")

- **Sync Provider** (`lib/presentation/providers/sync_provider.dart`):
  - Manages synchronization state and lifecycle
  - **performInitialSync()**: Blocking sync for first app launch (requires internet)
  - **performBackgroundSync()**: Silent sync for subsequent launches (doesn't block UI)
  - **Auto-sync on Start**: Automatically syncs metadata when app starts with internet
  - **Auto-sync on Connectivity Restore**: Listens to connectivity changes and syncs when internet restored
  - **needsInitialSync()**: Checks if cache is empty and initial sync required

- **Connectivity Monitoring** (`lib/core/connectivity/connectivity_service.dart`, `lib/presentation/providers/connectivity_provider.dart`):
  - Singleton service for checking internet connectivity
  - **hasInternet()**: Checks connectivity via DNS lookup (google.com) or backend ping
  - **onConnectivityChanged**: Stream that emits connectivity changes
  - **ConnectivityProvider**: Riverpod provider exposing connectivity state to UI
  - **5-second cache**: Connectivity checks are cached for 5 seconds to reduce overhead
  - **Offline Indicator**: `OfflineIndicator` widget in AppBar shows "Offline" badge when no internet

- **Cache Fallback Pattern** (in all data providers):
  - Primary: Try API call
  - Fallback: If API fails (network error), load from local cache
  - Example pattern:
    ```dart
    try {
      // Try API
      final response = await apiClient.getThemes();
      return response.items;
    } catch (e) {
      // Fallback to cache
      logger.w('Network error, falling back to cache');
      final cached = await db.getCachedThemes();
      return cached.map((e) => Theme.fromJson(e)).toList();
    }
    ```
  - All providers (`themes_provider.dart`, `books_provider.dart`, `teachers_provider.dart`, `series_provider.dart`, `lessons_provider.dart`) implement this pattern

**Notification System:**

The app includes a notification service for download progress tracking:

- **NotificationService** (`lib/core/notifications/notification_service.dart`):
  - Singleton pattern for managing download notifications
  - Shows progress notifications with percentage and size (e.g., "5.2 MB из 12.0 MB (43%)")
  - Silent notifications (low importance, no sound/vibration) for downloads
  - Auto-dismissing completion notifications (3 second timeout)
  - Error notifications with custom error messages
  - Methods: `showDownloadProgress()`, `showDownloadCompleted()`, `showDownloadFailed()`, `cancelDownloadNotification()`

- **App Badge Integration**:
  - Displays count of active downloads on app icon (iOS/Android)
  - Uses `app_badge_plus` package for cross-platform badge support
  - Badge automatically updates as downloads start/complete/fail
  - Badge cleared when no active downloads remain

- **Android Notification Configuration**:
  - Notification channel: "downloads" with low importance
  - Ongoing notifications during download (cannot be dismissed)
  - Auto-cancel notifications after completion
  - Requires `POST_NOTIFICATIONS` permission (Android 13+)
  - Icon: `@drawable/ic_stat_music_note`

**Routing:**

The app uses named routes defined in `lib/main.dart`:
- `/` (root) - SplashScreen shown during authentication check, then redirects to HomeScreen or LoginScreen
- `/admin` - Admin panel (requires admin role level >= 2)
- `/admin/themes`, `/admin/books`, `/admin/authors` - Content management
- `/admin/teachers`, `/admin/series`, `/admin/lessons` - Lesson management
- `/admin/tests` - Test/quiz management
- `/admin/users`, `/admin/feedbacks` - User management
- `/admin/statistics` - Analytics dashboard
- `/admin/system-settings`, `/admin/smtp-settings`, `/admin/sender-settings` - System configuration
- `/admin/help` - Admin help screen
- `/themes` - Theme browsing (public)
- `/email-verified?token=xxx` - Dynamic route for email verification

**Admin Features:**
The app includes an admin panel for managing:
- Themes (Islamic topics like Акыда, Сира, Фикх, Адаб)
- Books and Book Authors (classical Islamic scholars)
- Teachers (lesson instructors)
- Lesson Series (course sequences)
- Lessons (individual audio files)
- Tests (quizzes for series)
- Users and Feedbacks
- System settings (SMTP, sender configuration)

**Admin Management Screens Pattern:**
Admin screens (`lib/presentation/screens/admin/*_management_screen.dart`) follow a consistent pattern:
- Use direct Dio API calls instead of Riverpod providers
- Local state management with StatefulWidget
- Pagination state: `_currentPage`, `_totalItems`, `_itemsPerPage = 10`
- Standard features: search, add, edit, delete, toggle active status
- Pagination UI at bottom with page navigation controls

Example pagination implementation:
```dart
int _currentPage = 0;
int _totalItems = 0;
final int _itemsPerPage = 10;

Future<void> _loadItems({bool resetPage = false}) async {
  final dio = DioProvider.getDio();
  final response = await dio.get('/endpoint', queryParameters: {
    'include_inactive': true,
    'skip': _currentPage * _itemsPerPage,
    'limit': _itemsPerPage,
  });
  final data = response.data as Map<String, dynamic>;
  setState(() {
    _items = (data['items'] as List).map((e) => Model.fromJson(e)).toList();
    _totalItems = data['total'] as int;
  });
}
```

### Code Generation

The mobile app uses code generation for:
- Riverpod providers (riverpod_generator)
- JSON serialization (json_serializable)
- Retrofit API clients (retrofit_generator)

Always run `flutter pub run build_runner build --delete-conflicting-outputs` after:
- Adding/modifying Riverpod providers with annotations
- Changing data models with @JsonSerializable
- Updating Retrofit API interface

**Important Notes:**
- Generated files have `.g.dart` suffix and should not be manually edited
- Use `--delete-conflicting-outputs` flag to resolve conflicts
- For Hive: No longer using Hive type adapters (removed from dependencies)

## Development Workflow

### Data Flow Pattern

**Standard User Features** (uses Riverpod providers):
1. UI Screen → Riverpod Provider → Retrofit API Client → Backend
2. Backend returns data → Provider updates state → UI rebuilds automatically
3. Example: `ThemesScreen` uses `themesProvider` which calls `apiClient.getThemes()`

**Admin Features** (uses direct Dio calls):
1. UI Screen → Direct Dio API call → Backend
2. Backend returns data → setState() updates local state → UI rebuilds
3. Example: Admin screens manage their own pagination state locally
4. Rationale: Admin features are less frequently used and don't need global state

### Adding New API Endpoint

1. Backend:
   - Define Pydantic schemas in `backend/app/schemas/`
   - Add CRUD functions in `backend/app/crud/`
   - Create route handler in `backend/app/api/`
   - Register router in `backend/app/main.py`

2. Mobile (for standard features):
   - Add endpoint to Retrofit client in `mobile_app/lib/data/api/api_client.dart`
   - Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`
   - Create/update provider in `mobile_app/lib/presentation/providers/`
   - Use provider in UI screens

3. Mobile (for admin features):
   - Use direct Dio calls via `DioProvider.getDio()`
   - Manage state locally with StatefulWidget
   - Follow admin screen pagination pattern (see Admin Management Screens Pattern)

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

## Troubleshooting

### Backend Issues

**Database not creating:**
```bash
docker-compose down -v  # Remove volumes
docker-compose up -d    # Recreate
```

**Alembic not detecting changes:**
```bash
# Ensure models are imported in app/models/__init__.py
docker-compose restart api
docker-compose exec api alembic revision --autogenerate -m "Description"
```

**500 errors on API endpoints:**
- Check field names match model definitions (e.g., `Lesson.audio_path` not `audio_file_path`)
- Verify migrations are applied: `docker-compose exec api alembic current`
- Check API logs: `docker-compose logs -f api`

### Frontend Issues

**Code generation errors:**
```bash
# Clean generated files and rebuild
cd mobile_app
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**Type mismatch errors with API responses:**
- Verify API returns paginated format: `{"items": [], "total": 0, "skip": 0, "limit": 100}`
- Check Retrofit client returns `PaginatedResponse<Model>`
- Ensure providers extract `.items` from response

**Admin screens not loading data:**
- Verify user has admin role (level >= 2)
- Check `include_inactive: true` is set in query parameters
- Verify pagination parameters are correct: `skip = page * itemsPerPage`

**Audio playback issues on Android:**
- Ensure notification icons exist in `android/app/src/main/res/drawable/`
- Required icons: `ic_stat_music_note.png`, `ic_play_arrow.png`, `ic_pause.png`, `ic_skip_next.png`, `ic_skip_previous.png`, `ic_fast_forward.png`, `ic_rewind.png`, `ic_action_cancel.png`
- Audio service is eagerly initialized in `main()` before `runApp()`
- Verify minSdk is set to 24 or higher in `android/app/build.gradle.kts`
- Check AndroidManifest.xml for required permissions:
  - `FOREGROUND_SERVICE` - Required for background audio
  - `FOREGROUND_SERVICE_MEDIA_PLAYBACK` - Android 14+ requirement
  - `FOREGROUND_SERVICE_DATA_SYNC` - Required for download service
  - `POST_NOTIFICATIONS` - Android 13+ requirement
- ProGuard/R8 settings: `isMinifyEnabled = false`, `isShrinkResources = false` to prevent icon stripping in release builds

**Performance issues with list screens:**
- **CRITICAL**: Never use FutureBuilder or async data loading in `itemBuilder` callbacks of ListView.builder
- This causes multiple simultaneous API calls for each item in the list
- Example: SeriesScreen was frozen because it loaded lessons for every series card
- **Solution**: Show simple UI by default, load data only when user interacts (e.g., taps download button)
- Use provider watchers outside of list builders, not inside

**Download functionality issues:**
- Check SQLite database is initialized: `DatabaseHelper().database`
- Verify download directory permissions: `getApplicationDocumentsDirectory()`
- Download progress not updating: Ensure `DownloadProvider` is watching activeDownloads map
- Downloaded lessons not persisting: Check SQLite table creation in `_createDatabase()`
- Notifications not showing: Initialize `NotificationService` and check `POST_NOTIFICATIONS` permission
- Badge not displaying: Verify `AppBadgePlus.isSupported()` returns true on device
- Silent notification not working: Ensure notification channel uses `Importance.low` (no sound/vibration)

**Deprecated API warnings:**
- Project uses latest Flutter SDK and has migrated deprecated APIs
- Check recent commits for deprecation fixes (e.g., `MediaQuery.of(context).size` migrations)
- Use `logger` package instead of `print()` for debugging
