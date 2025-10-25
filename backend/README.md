# Backend - Islamic Audio Lessons API

FastAPI REST API для мобильного приложения исламских аудио-уроков.

## Быстрый старт

### 1. Настройка окружения

Скопируйте `.env.example` в `.env` и настройте переменные:
```bash
cp .env.example .env
```

### 2. Запуск через Docker Compose

```bash
# Запустить все сервисы (PostgreSQL, Redis, FastAPI)
docker-compose up -d

# Посмотреть логи
docker-compose logs -f api

# Остановить
docker-compose down
```

### 3. Создание и применение миграций

```bash
# Создать миграцию (autogenerate)
docker-compose exec api alembic revision --autogenerate -m "Initial migration"

# Применить миграции
docker-compose exec api alembic upgrade head

# Откатить последнюю миграцию
docker-compose exec api alembic downgrade -1

# Посмотреть историю миграций
docker-compose exec api alembic history
```

### 4. Заполнение тестовыми данными

```bash
# После применения миграций запустите seed скрипт
docker-compose exec api python -m app.seed
```

## API Документация

После запуска доступна по адресам:
- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc

## Структура проекта

```
backend/
├── app/
│   ├── main.py           # FastAPI приложение
│   ├── config.py         # Настройки
│   ├── database.py       # SQLAlchemy setup
│   ├── models/           # ORM модели
│   ├── schemas/          # Pydantic schemas
│   ├── api/              # API endpoints
│   ├── crud/             # Database queries
│   ├── auth/             # JWT authentication
│   └── utils/            # Utilities
├── alembic/              # Database migrations
├── audio_files/          # MP3 файлы уроков
├── requirements.txt
├── Dockerfile
└── docker-compose.yml
```

## Разработка

### Локальная разработка без Docker

```bash
# Установить зависимости
pip install -r requirements.txt

# Запустить сервер
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Подключение к PostgreSQL

```bash
# Через Docker
docker-compose exec db psql -U postgres -d audio_lessons

# Локально
psql -h localhost -U postgres -d audio_lessons
```

### Подключение к Redis

```bash
# Через Docker
docker-compose exec redis redis-cli

# Локально
redis-cli
```

## Endpoints (MVP)

### Авторизация
- `POST /api/auth/register` - Регистрация
- `POST /api/auth/login` - Вход (возвращает JWT)
- `GET /api/auth/me` - Текущий пользователь

### Контент
- `GET /api/themes` - Список тем
- `GET /api/teachers` - Список преподавателей
- `GET /api/teachers/{id}/series` - Серии преподавателя
- `GET /api/series/{id}/lessons` - Уроки серии
- `GET /api/lessons/{id}` - Детали урока
- `GET /api/lessons/{id}/audio` - Стрим аудио (Range requests)

## Troubleshooting

### База данных не создаётся
```bash
docker-compose down -v  # Удалить volumes
docker-compose up -d    # Пересоздать
```

### Ошибка импорта моделей
Убедитесь что все модели импортированы в `app/models/__init__.py`

### Alembic не видит изменения
```bash
docker-compose restart api
docker-compose exec api alembic revision --autogenerate -m "Description"
```
