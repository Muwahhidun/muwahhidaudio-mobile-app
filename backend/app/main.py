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
# Note: allow_credentials cannot be True when allow_origins is ["*"]
# So we use allow_origin_regex instead
if settings.DEBUG:
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r"http://localhost:\d+",  # Match any localhost port
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
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
from app.api import auth, themes, books, book_authors, teachers, series, lessons, migration

app.include_router(auth.router, prefix=settings.API_V1_PREFIX)
app.include_router(themes.router, prefix=settings.API_V1_PREFIX)
app.include_router(books.router, prefix=settings.API_V1_PREFIX)
app.include_router(book_authors.router, prefix=settings.API_V1_PREFIX)
app.include_router(teachers.router, prefix=settings.API_V1_PREFIX)
app.include_router(series.router, prefix=settings.API_V1_PREFIX)
app.include_router(lessons.router, prefix=settings.API_V1_PREFIX)
app.include_router(migration.router, prefix=settings.API_V1_PREFIX)
