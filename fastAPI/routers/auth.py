# ========================================
# Authentication Router
# ========================================

from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import models, schemas
from .. import email_service
from .. import database
from ..auth import auth
from ..database import get_db

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/login", response_model=schemas.Token)
def login(
    user_data: schemas.UserLogin,
    db: Session = Depends(database.get_db)
):
    """User login endpoint"""
    # Find user by email
    user = db.query(models.User).filter(
        models.User.email == user_data.email
    ).first()
    
    # Check if user exists and password is correct
    if not user or not auth.verify_password(user_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.email},
        expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }


@router.post("/register", response_model=schemas.UserResponse)
def register(
    user_data: schemas.UserCreate,
    db: Session = Depends(database.get_db)
):
    """User registration endpoint"""
    # Check if user already exists
    existing_user = db.query(models.User).filter(
        models.User.email == user_data.email
    ).first()
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user
    user = models.User(
        id=user_data.email.split("@")[0],  # Simple ID from email
        email=user_data.email,
        name=user_data.name,
        phone=user_data.phone,
        department=user_data.department,
        password_hash=auth.get_password_hash(user_data.password)
    )
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Send welcome email
    email_service.email_service.send_welcome_email(
        email=user.email,
        name=user.name
    )
    
    return user
