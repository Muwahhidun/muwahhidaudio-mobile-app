"""
Main FastAPI application entry point.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.config import settings
from app.database import close_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan events.
    Setup and teardown logic.
    """
    # Startup
    print(f"Starting {settings.APP_NAME}...")
    print(f"Debug mode: {settings.DEBUG}")
    print(f"Database: {settings.DATABASE_URL.split('@')[1] if '@' in settings.DATABASE_URL else 'configured'}")

    # TODO: Initialize Redis cache here when implemented
    # await init_cache()

    yield

    # Shutdown
    print("Shutting down...")
    await close_db()


# Create FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    description="REST API for Islamic Audio Lessons Mobile Application",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# CORS middleware - allow all origins in debug mode
# For development, we allow all localhost origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:3001",
        "http://localhost:3002",
        "http://localhost:3003",
        "http://localhost:3004",
        "http://localhost:3065",
        "http://localhost:3066",
        "http://localhost:3067",
        "http://localhost:3068",
        "http://localhost:3069",
        "http://localhost:3070",
        "http://localhost:3071",
        "http://localhost:3072",
        "http://localhost:3073",
        "http://localhost:3074",
        "http://localhost:3075",
        "http://localhost:3076",
        "http://localhost:3077",
        "http://localhost:3078",
        "http://localhost:3079",
        "http://localhost:3083",
        "http://localhost:3087",
        "http://localhost:3088",
        "http://localhost:3089",
        "http://localhost:3080",
        "http://localhost:3081",
        "http://localhost:3082",
        "http://localhost:3084",
        "http://localhost:3085",
        "http://localhost:3086",
        "http://localhost:3088",
        "http://localhost:3089",
        "http://localhost:3090",
        "http://localhost:3091",
        "http://localhost:3093",
        "http://localhost:3094",
        "http://localhost:3095",
        "http://localhost:3096",
        "http://localhost:3097",
        "http://localhost:3098",
        "http://localhost:3099",
        "http://localhost:3100",
        "http://localhost:3101",
        "http://localhost:3110",
        "http://localhost:3111",
        "http://localhost:3112",
        "http://localhost:3113",
        "http://localhost:3114",
        "http://localhost:3115",
        "http://localhost:3116",
        "http://localhost:3117",
        "http://localhost:3118",
        "http://localhost:3119",
        "http://localhost:3120",
        "http://localhost:3121",
        "http://localhost:3122",
        "http://localhost:3123",
        "http://localhost:3124",
        "http://localhost:3125",
        "http://localhost:3126",
        "http://localhost:3127",
        "http://localhost:3128",
        "http://localhost:3129",
        "http://localhost:3130",
        "http://localhost:3131",
        "http://localhost:3132",
        "http://localhost:3133",
        "http://localhost:3134",
        "http://localhost:3135",
        "http://localhost:3136",
        "http://localhost:3137",
        "http://localhost:3138",
        "http://localhost:3139",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)


@app.get("/")
async def root():
    """Root endpoint - health check."""
    return {
        "app": settings.APP_NAME,
        "version": "0.1.0",
        "status": "running"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring."""
    return {
        "status": "healthy",
        "database": "connected"  # TODO: Add actual DB health check
    }


# Include API routers
from app.api import auth, themes, books, book_authors, teachers, series, lessons, tests, statistics, migration, settings as settings_api, users, feedbacks, bookmarks

app.include_router(auth.router, prefix=settings.API_V1_PREFIX)
app.include_router(themes.router, prefix=settings.API_V1_PREFIX)
app.include_router(books.router, prefix=settings.API_V1_PREFIX)
app.include_router(book_authors.router, prefix=settings.API_V1_PREFIX)
app.include_router(teachers.router, prefix=settings.API_V1_PREFIX)
app.include_router(series.router, prefix=settings.API_V1_PREFIX)
app.include_router(lessons.router, prefix=settings.API_V1_PREFIX)
app.include_router(tests.router, prefix=settings.API_V1_PREFIX)
app.include_router(users.router)
app.include_router(feedbacks.router, prefix=settings.API_V1_PREFIX)
app.include_router(bookmarks.router, prefix=settings.API_V1_PREFIX)
app.include_router(statistics.router, prefix=settings.API_V1_PREFIX)
app.include_router(migration.router, prefix=settings.API_V1_PREFIX)
app.include_router(settings_api.router)
