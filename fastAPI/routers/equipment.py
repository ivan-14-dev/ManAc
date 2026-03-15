# ========================================
# Equipment Router
# ========================================

import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import models, schemas
from ..auth import get_current_user
from ..database import get_db

router = APIRouter(prefix="/api/equipements", tags=["Equipment"])


@router.get("/", response_model=List[schemas.EquipmentResponse])
def get_all_equipment(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get all equipment"""
    items = db.query(models.Equipment).offset(skip).limit(limit).all()
    return items


@router.get("/{equipment_id}", response_model=schemas.EquipmentResponse)
def get_equipment(
    equipment_id: str,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get a specific equipment item"""
    item = db.query(models.Equipment).filter(
        models.Equipment.id == equipment_id
    ).first()
    
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Equipment not found"
        )
    
    return item


@router.post("/", response_model=schemas.EquipmentResponse)
def create_equipment(
    equipment_data: schemas.EquipmentCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Create new equipment"""
    item = models.Equipment(
        id=str(uuid.uuid4()),
        name=equipment_data.name,
        category=equipment_data.category,
        description=equipment_data.description,
        serial_number=equipment_data.serial_number,
        barcode=equipment_data.barcode,
        location=equipment_data.location,
        status=equipment_data.status,
        total_quantity=equipment_data.total_quantity,
        available_quantity=equipment_data.available_quantity,
        photo_path=equipment_data.photo_path,
        value=equipment_data.value,
        purchase_date=equipment_data.purchase_date,
        user_id=current_user.id
    )
    
    db.add(item)
    db.commit()
    db.refresh(item)
    
    return item


@router.put("/{equipment_id}", response_model=schemas.EquipmentResponse)
def update_equipment(
    equipment_id: str,
    equipment_data: schemas.EquipmentUpdate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Update equipment"""
    item = db.query(models.Equipment).filter(
        models.Equipment.id == equipment_id
    ).first()
    
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Equipment not found"
        )
    
    # Update fields
    update_data = equipment_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(item, field, value)
    
    db.commit()
    db.refresh(item)
    
    return item


@router.delete("/{equipment_id}")
def delete_equipment(
    equipment_id: str,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Delete equipment"""
    item = db.query(models.Equipment).filter(
        models.Equipment.id == equipment_id
    ).first()
    
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Equipment not found"
        )
    
    db.delete(item)
    db.commit()
    
    return {"message": "Equipment deleted successfully"}
