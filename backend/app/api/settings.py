"""
Settings API endpoints for system configuration.
Admin-only endpoints for managing SMTP and email settings.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.settings import (
    SMTPSettings, SMTPSettingsUpdate, TestEmailRequest, TestEmailResponse
)
from app.crud import settings as settings_crud
from app.auth.dependencies import get_current_user
from app.models import User
from app.services.email import send_test_email

router = APIRouter(prefix="/api/settings", tags=["Settings"])


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """
    Dependency to require admin role.

    Raises:
        HTTPException: 403 if user is not admin
    """
    if not current_user.role or current_user.role.level < 2:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user


@router.get("/notifications", response_model=SMTPSettings)
async def get_smtp_settings(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """
    Get current SMTP and email settings.

    Admin only. Returns all SMTP configuration including masked password.
    """
    # Get SMTP settings from database
    smtp_settings = await settings_crud.get_all_settings_dict(db, category='smtp', decrypt=True)
    email_settings = await settings_crud.get_all_settings_dict(db, category='email', decrypt=True)

    # Combine settings
    settings = {**smtp_settings, **email_settings}

    # Convert smtp_use_ssl to boolean
    settings['smtp_use_ssl'] = settings.get('smtp_use_ssl', 'false').lower() == 'true'
    settings['smtp_port'] = int(settings.get('smtp_port', 465))

    return SMTPSettings(**settings)


@router.put("/notifications", response_model=SMTPSettings)
async def update_smtp_settings(
    settings: SMTPSettingsUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """
    Update SMTP and email settings.

    Admin only. Updates all SMTP configuration at once.
    SMTP password will be encrypted before storing.
    """
    # Update settings in database
    await settings_crud.update_smtp_settings(
        db=db,
        smtp_host=settings.smtp_host,
        smtp_port=settings.smtp_port,
        smtp_username=settings.smtp_username,
        smtp_password=settings.smtp_password,
        smtp_use_ssl=settings.smtp_use_ssl,
        email_from_name=settings.email_from_name,
        email_from_address=settings.email_from_address,
        frontend_url=settings.frontend_url
    )

    await db.commit()

    # Return updated settings
    return await get_smtp_settings(db, current_user)


@router.post("/notifications/test", response_model=TestEmailResponse)
async def send_test_email_endpoint(
    request: TestEmailRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """
    Send a test email to verify SMTP configuration.

    Admin only. Sends a test email to the specified address
    using current SMTP settings.
    """
    try:
        await send_test_email(
            db=db,
            to_email=request.test_email
        )

        return TestEmailResponse(
            success=True,
            message=f"Test email successfully sent to {request.test_email}"
        )

    except Exception as e:
        return TestEmailResponse(
            success=False,
            message=f"Failed to send test email: {str(e)}"
        )
