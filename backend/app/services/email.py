"""
Email service for sending verification emails and notifications.
Uses aiosmtplib for async SMTP and Jinja2 for HTML templates.
"""
import ssl
from pathlib import Path
from typing import Optional, Dict, Any
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

import aiosmtplib
from jinja2 import Environment, FileSystemLoader, select_autoescape
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.config import settings
from app.models.system_settings import SystemSettings
from app.utils.encryption import decrypt_value


# Templates directory
TEMPLATES_DIR = Path(__file__).parent.parent / "templates" / "emails"


# Jinja2 environment for email templates
jinja_env = Environment(
    loader=FileSystemLoader(str(TEMPLATES_DIR)),
    autoescape=select_autoescape(['html', 'xml'])
)


class SMTPConfig:
    """SMTP configuration data class."""

    def __init__(
        self,
        host: str,
        port: int,
        username: str,
        password: str,
        use_ssl: bool,
        from_name: str,
        from_address: str,
        frontend_url: str
    ):
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.use_ssl = use_ssl
        self.from_name = from_name
        self.from_address = from_address
        self.frontend_url = frontend_url

    @property
    def from_email(self) -> str:
        """Format 'From' email with name."""
        return f"{self.from_name} <{self.from_address}>"


async def get_smtp_config(db: AsyncSession) -> SMTPConfig:
    """
    Get SMTP configuration from database or fallback to environment variables.

    Args:
        db: Database session

    Returns:
        SMTPConfig object with SMTP settings
    """
    # Try to load from database first
    result = await db.execute(
        select(SystemSettings).where(
            SystemSettings.category.in_(['smtp', 'email'])
        )
    )
    settings_dict = {s.key: s for s in result.scalars().all()}

    def get_setting(key: str, default: Any, is_encrypted: bool = False) -> Any:
        """Helper to get setting value with fallback."""
        if key in settings_dict:
            value = settings_dict[key].value
            if is_encrypted and value:
                value = decrypt_value(value)
            # Convert string booleans
            if isinstance(value, str) and value.lower() in ('true', 'false'):
                return value.lower() == 'true'
            # Convert string integers
            if key.endswith('_port') and isinstance(value, str):
                return int(value)
            return value
        return default

    return SMTPConfig(
        host=get_setting('smtp_host', settings.SMTP_HOST),
        port=get_setting('smtp_port', settings.SMTP_PORT),
        username=get_setting('smtp_username', settings.SMTP_USERNAME),
        password=get_setting('smtp_password', settings.SMTP_PASSWORD, is_encrypted=True),
        use_ssl=get_setting('smtp_use_ssl', settings.SMTP_USE_SSL),
        from_name=get_setting('email_from_name', settings.EMAIL_FROM_NAME),
        from_address=get_setting('email_from_address', settings.EMAIL_FROM_ADDRESS),
        frontend_url=get_setting('frontend_url', settings.FRONTEND_URL)
    )


async def send_email(
    db: AsyncSession,
    to_email: str,
    subject: str,
    html_content: str,
    text_content: Optional[str] = None
) -> None:
    """
    Send an email using SMTP.

    Args:
        db: Database session
        to_email: Recipient email address
        subject: Email subject
        html_content: HTML content of the email
        text_content: Plain text content (optional, will strip HTML if not provided)

    Raises:
        Exception: If email sending fails
    """
    # Get SMTP configuration
    config = await get_smtp_config(db)

    # Create message
    message = MIMEMultipart('alternative')
    message['From'] = config.from_email
    message['To'] = to_email
    message['Subject'] = subject

    # Add text and HTML parts
    if text_content:
        part1 = MIMEText(text_content, 'plain', 'utf-8')
        message.attach(part1)

    part2 = MIMEText(html_content, 'html', 'utf-8')
    message.attach(part2)

    # Send email
    try:
        if config.use_ssl:
            # Use SSL
            await aiosmtplib.send(
                message,
                hostname=config.host,
                port=config.port,
                username=config.username,
                password=config.password,
                use_tls=True,
                start_tls=False,
                tls_context=ssl.create_default_context()
            )
        else:
            # Use STARTTLS
            await aiosmtplib.send(
                message,
                hostname=config.host,
                port=config.port,
                username=config.username,
                password=config.password,
                use_tls=False,
                start_tls=True
            )
    except Exception as e:
        raise Exception(f"Failed to send email: {str(e)}")


async def send_verification_email(
    db: AsyncSession,
    email: str,
    username: str,
    token: str
) -> None:
    """
    Send email verification link to user.

    Args:
        db: Database session
        email: User's email address
        username: User's username
        token: Verification token

    Raises:
        Exception: If email sending fails
    """
    # Get config for frontend URL
    config = await get_smtp_config(db)

    # Get subject from settings or use default
    result = await db.execute(
        select(SystemSettings).where(SystemSettings.key == 'verification_subject')
    )
    setting = result.scalar_one_or_none()
    subject = setting.value if setting else "Подтвердите регистрацию"

    # Prepare template context
    context = {
        'username': username,
        'verification_url': f"{config.frontend_url}/email-verified?token={token}",
        'frontend_url': config.frontend_url
    }

    # Render template
    template = jinja_env.get_template('verification.html')
    html_content = template.render(**context)

    # Send email
    await send_email(
        db=db,
        to_email=email,
        subject=subject,
        html_content=html_content
    )


async def send_test_email(
    db: AsyncSession,
    to_email: str
) -> None:
    """
    Send a test email to verify SMTP configuration.

    Args:
        db: Database session
        to_email: Recipient email address for test

    Raises:
        Exception: If email sending fails
    """
    subject = "Тестовое письмо - Islamic Audio Lessons"

    # Prepare template context
    context = {
        'to_email': to_email
    }

    # Render template
    template = jinja_env.get_template('test.html')
    html_content = template.render(**context)

    # Send email
    await send_email(
        db=db,
        to_email=to_email,
        subject=subject,
        html_content=html_content
    )
