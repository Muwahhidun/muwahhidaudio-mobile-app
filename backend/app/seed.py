"""
Seed script to populate database with test data.

Usage:
    python -m app.seed
    or
    docker-compose exec api python -m app.seed
"""
import asyncio
from datetime import datetime
import bcrypt

from app.database import AsyncSessionLocal
from app.models import (
    Role, User, Theme, BookAuthor, Book,
    LessonTeacher, LessonSeries, Lesson
)


def hash_password(password: str) -> str:
    """Hash password using bcrypt."""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')


async def seed_database():
    """Populate database with test data."""
    async with AsyncSessionLocal() as session:
        try:
            print("🌱 Starting database seed...")

            # 1. Create Roles
            print("\n📋 Creating roles...")
            role_user = Role(
                name="User",
                description="Regular user",
                level=0,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            role_admin = Role(
                name="Admin",
                description="Administrator",
                level=2,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            session.add_all([role_user, role_admin])
            await session.flush()
            print(f"  ✓ Created roles: User (id={role_user.id}), Admin (id={role_admin.id})")

            # 2. Create Test Users
            print("\n👤 Creating test users...")
            test_user = User(
                email="test@example.com",
                password_hash=hash_password("password123"),
                first_name="Test",
                last_name="User",
                is_active=True,
                role_id=role_user.id,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            admin_user = User(
                email="admin@example.com",
                password_hash=hash_password("admin123"),
                first_name="Admin",
                last_name="User",
                is_active=True,
                role_id=role_admin.id,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            session.add_all([test_user, admin_user])
            await session.flush()
            print(f"  ✓ Created users: test@example.com, admin@example.com")
            print(f"    Passwords: password123, admin123")

            # 3. Create Themes
            print("\n🎨 Creating themes...")
            theme_aqida = Theme(
                name="Акыда",
                description="Вероучение в Исламе",
                sort_order=1,
                is_active=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            theme_fiqh = Theme(
                name="Фикх",
                description="Исламское право",
                sort_order=2,
                is_active=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            theme_sirah = Theme(
                name="Сира",
                description="Жизнеописание Пророка ﷺ",
                sort_order=3,
                is_active=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            session.add_all([theme_aqida, theme_fiqh, theme_sirah])
            await session.flush()
            print(f"  ✓ Created {3} themes")

            # 4. Create Book Authors
            print("\n📚 Creating book authors...")
            author1 = BookAuthor(
                name="Мухаммад ибн Абдуль-Ваххаб",
                biography="Великий исламский учёный",
                birth_year=1703,
                death_year=1792,
                is_active=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            author2 = BookAuthor(
                name="Ибн Таймийя",
                biography="Имам, факих и муджтахид",
                birth_year=1263,
                death_year=1328,
                is_active=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            session.add_all([author1, author2])
            await session.flush()
            print(f"  ✓ Created {2} book authors")

            # 5. Create Books
            print("\n📖 Creating books...")
            book1 = Book(
                name="Три основы",
                description="Основы Ислама",
                theme_id=theme_aqida.id,
                author_id=author1.id,
                sort_order=1,
                is_active=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            book2 = Book(
                name="Книга единобожия",
                description="Китаб ат-Таухид",
                theme_id=theme_aqida.id,
                author_id=author1.id,
                sort_order=2,
                is_active=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            session.add_all([book1, book2])
            await session.flush()
            print(f"  ✓ Created {2} books")

            # 6. Create Lesson Teachers
            print("\n👨‍🏫 Creating lesson teachers...")
            teacher1 = LessonTeacher(
                name="Мухаммад Абу Мунира",
                biography="Современный исламский лектор",
                is_active=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            teacher2 = LessonTeacher(
                name="Абу Яхья Крымский",
                biography="Современный исламский лектор",
                is_active=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            session.add_all([teacher1, teacher2])
            await session.flush()
            print(f"  ✓ Created {2} teachers")

            # 7. Create Lesson Series
            print("\n📚 Creating lesson series...")
            series1 = LessonSeries(
                name="Фаида - 1",
                year=2025,
                description="Краткие пояснения к книге Три основы",
                teacher_id=teacher1.id,
                book_id=book1.id,
                theme_id=theme_aqida.id,
                is_completed=False,
                order=1,
                is_active=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            series2 = LessonSeries(
                name="Основы Таухида",
                year=2024,
                description="Введение в единобожие",
                teacher_id=teacher2.id,
                book_id=book2.id,
                theme_id=theme_aqida.id,
                is_completed=True,
                order=1,
                is_active=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            session.add_all([series1, series2])
            await session.flush()
            print(f"  ✓ Created {2} series")

            # 8. Create Lessons
            print("\n🎧 Creating lessons...")
            lessons = []
            for i in range(1, 6):
                lesson = Lesson(
                    title=f"Мухаммад_Абу_Мунира_Три_основы_2025_Фаида_1_урок_{i}",
                    description=f"Урок {i} - Введение в основы Ислама",
                    audio_path=f"audio_files/lesson_{i}.mp3",  # Placeholder
                    lesson_number=i,
                    duration_seconds=1800 + (i * 100),  # ~30 minutes
                    tags="акыда,основы,таухид",
                    series_id=series1.id,
                    book_id=book1.id,
                    teacher_id=teacher1.id,
                    theme_id=theme_aqida.id,
                    is_active=True,
                    created_at=datetime.utcnow(),
                    updated_at=datetime.utcnow()
                )
                lessons.append(lesson)

            for i in range(1, 4):
                lesson = Lesson(
                    title=f"Абу_Яхья_Крымский_Книга_единобожия_2024_Основы_Таухида_урок_{i}",
                    description=f"Урок {i} - Основы Таухида",
                    audio_path=f"audio_files/lesson_tauhid_{i}.mp3",  # Placeholder
                    lesson_number=i,
                    duration_seconds=2000 + (i * 150),
                    tags="акыда,таухид,единобожие",
                    series_id=series2.id,
                    book_id=book2.id,
                    teacher_id=teacher2.id,
                    theme_id=theme_aqida.id,
                    is_active=True,
                    created_at=datetime.utcnow(),
                    updated_at=datetime.utcnow()
                )
                lessons.append(lesson)

            session.add_all(lessons)
            await session.flush()
            print(f"  ✓ Created {len(lessons)} lessons")

            # Commit all changes
            await session.commit()
            print("\n✅ Database seeded successfully!")
            print("\n📝 Summary:")
            print(f"  - 2 roles (User, Admin)")
            print(f"  - 2 users (test@example.com, admin@example.com)")
            print(f"  - 3 themes (Акыда, Фикх, Сира)")
            print(f"  - 2 book authors")
            print(f"  - 2 books")
            print(f"  - 2 teachers")
            print(f"  - 2 series")
            print(f"  - 8 lessons")
            print("\n💡 Note: Audio files are placeholders. Add real MP3 files to backend/audio_files/")

        except Exception as e:
            await session.rollback()
            print(f"\n❌ Error seeding database: {e}")
            raise


if __name__ == "__main__":
    print("=" * 60)
    print("  Islamic Audio Lessons - Database Seed Script")
    print("=" * 60)
    asyncio.run(seed_database())
