"""
CRUD operations for SystemSettings model.
"""
from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.system_settings import SystemSettings
from app.utils.encryption import encrypt_value, decrypt_value


async def get_setting(db: AsyncSession, key: str) -> Optional[SystemSettings]:
    """
    Get a single setting by key.

    Args:
        db: Database session
        key: Setting key

    Returns:
        SystemSettings object if found, None otherwise
    """
    result = await db.execute(
        select(SystemSettings).where(SystemSettings.key == key)
    )
    return result.scalar_one_or_none()


async def get_settings_by_category(
    db: AsyncSession,
    category: str,
    decrypt: bool = True
) -> List[SystemSettings]:
    """
    Get all settings for a category.

    Args:
        db: Database session
        category: Category name (e.g., 'smtp', 'email')
        decrypt: Whether to decrypt encrypted values

    Returns:
        List of SystemSettings objects
    """
    result = await db.execute(
        select(SystemSettings)
        .where(SystemSettings.category == category)
        .order_by(SystemSettings.key)
    )
    settings = result.scalars().all()

    # Decrypt encrypted values if requested
    if decrypt:
        for setting in settings:
            if setting.is_encrypted and setting.value:
                setting.value = decrypt_value(setting.value)

    return list(settings)


async def get_all_settings_dict(
    db: AsyncSession,
    category: Optional[str] = None,
    decrypt: bool = True
) -> Dict[str, Any]:
    """
    Get settings as a dictionary (key: value).

    Args:
        db: Database session
        category: Optional category filter
        decrypt: Whether to decrypt encrypted values

    Returns:
        Dictionary of {key: value}
    """
    query = select(SystemSettings)
    if category:
        query = query.where(SystemSettings.category == category)

    result = await db.execute(query.order_by(SystemSettings.key))
    settings = result.scalars().all()

    settings_dict = {}
    for setting in settings:
        value = setting.value
        if decrypt and setting.is_encrypted and value:
            value = decrypt_value(value)
        settings_dict[setting.key] = value

    return settings_dict


async def update_setting(
    db: AsyncSession,
    key: str,
    value: str,
    encrypt: bool = False
) -> SystemSettings:
    """
    Update an existing setting value.

    Args:
        db: Database session
        key: Setting key
        value: New value
        encrypt: Whether to encrypt the value

    Returns:
        Updated SystemSettings object
    """
    # Get existing setting
    setting = await get_setting(db, key)

    if not setting:
        raise ValueError(f"Setting with key '{key}' not found")

    # Encrypt value if needed
    if encrypt:
        value = encrypt_value(value)
        setting.is_encrypted = True
    else:
        setting.is_encrypted = False

    # Update value
    setting.value = value

    await db.flush()
    await db.refresh(setting)

    return setting


async def create_or_update_setting(
    db: AsyncSession,
    key: str,
    value: str,
    category: Optional[str] = None,
    description: Optional[str] = None,
    encrypt: bool = False
) -> SystemSettings:
    """
    Create a new setting or update existing one.

    Args:
        db: Database session
        key: Setting key
        value: Setting value
        category: Category (e.g., 'smtp', 'email')
        description: Setting description
        encrypt: Whether to encrypt the value

    Returns:
        Created or updated SystemSettings object
    """
    # Try to get existing setting
    setting = await get_setting(db, key)

    if setting:
        # Update existing
        if encrypt:
            value = encrypt_value(value)
            setting.is_encrypted = True
        else:
            setting.is_encrypted = False

        setting.value = value
        if category:
            setting.category = category
        if description:
            setting.description = description
    else:
        # Create new
        if encrypt:
            value = encrypt_value(value)

        setting = SystemSettings(
            key=key,
            value=value,
            category=category,
            description=description,
            is_encrypted=encrypt
        )
        db.add(setting)

    await db.flush()
    await db.refresh(setting)

    return setting


async def update_smtp_settings(
    db: AsyncSession,
    smtp_host: str,
    smtp_port: int,
    smtp_username: str,
    smtp_password: str,
    smtp_use_ssl: bool,
    email_from_name: str,
    email_from_address: str,
    frontend_url: str
) -> None:
    """
    Update all SMTP and email settings at once.

    Args:
        db: Database session
        smtp_host: SMTP server hostname
        smtp_port: SMTP server port
        smtp_username: SMTP username
        smtp_password: SMTP password (will be encrypted)
        smtp_use_ssl: Use SSL for SMTP
        email_from_name: Display name for sender
        email_from_address: Email address for sender
        frontend_url: Frontend URL for email links
    """
    # Update each setting
    await create_or_update_setting(db, 'smtp_host', smtp_host, 'smtp', 'SMTP server hostname')
    await create_or_update_setting(db, 'smtp_port', str(smtp_port), 'smtp', 'SMTP server port')
    await create_or_update_setting(db, 'smtp_username', smtp_username, 'smtp', 'SMTP username/email')
    await create_or_update_setting(db, 'smtp_password', smtp_password, 'smtp', 'SMTP password', encrypt=True)
    await create_or_update_setting(db, 'smtp_use_ssl', 'true' if smtp_use_ssl else 'false', 'smtp', 'Use SSL for SMTP connection')
    await create_or_update_setting(db, 'email_from_name', email_from_name, 'email', 'Display name for sender')
    await create_or_update_setting(db, 'email_from_address', email_from_address, 'email', 'Email address for sender')
    await create_or_update_setting(db, 'frontend_url', frontend_url, 'email', 'Frontend URL for email links')

    await db.flush()
