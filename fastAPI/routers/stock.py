# ========================================
# Stock Router
# ========================================

import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import models, schemas
from ..auth import get_current_user
from ..database import get_db

router = APIRouter(prefix="/api/stock", tags=["Stock"])


@router.get("/", response_model=List[schemas.StockItemResponse])
def get_all_stock(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get all stock items"""
    items = db.query(models.StockItem).offset(skip).limit(limit).all()
    return items


@router.get("/{item_id}", response_model=schemas.StockItemResponse)
def get_stock_item(
    item_id: str,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get a specific stock item"""
    item = db.query(models.StockItem).filter(
        models.StockItem.id == item_id
    ).first()
    
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Stock item not found"
        )
    
    return item


@router.post("/", response_model=schemas.StockItemResponse)
def create_stock_item(
    item_data: schemas.StockItemCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Create a new stock item"""
    item = models.StockItem(
        id=str(uuid.uuid4()),
        name=item_data.name,
        category=item_data.category,
        quantity=item_data.quantity,
        min_quantity=item_data.min_quantity,
        unit=item_data.unit,
        price=item_data.price,
        description=item_data.description,
        barcode=item_data.barcode,
        location=item_data.location,
        user_id=current_user.id
    )
    
    db.add(item)
    db.commit()
    db.refresh(item)
    
    return item


@router.put("/{item_id}", response_model=schemas.StockItemResponse)
def update_stock_item(
    item_id: str,
    item_data: schemas.StockItemUpdate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Update a stock item"""
    item = db.query(models.StockItem).filter(
        models.StockItem.id == item_id
    ).first()
    
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Stock item not found"
        )
    
    # Update fields
    update_data = item_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(item, field, value)
    
    db.commit()
    db.refresh(item)
    
    return item


@router.delete("/{item_id}")
def delete_stock_item(
    item_id: str,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Delete a stock item"""
    item = db.query(models.StockItem).filter(
        models.StockItem.id == item_id
    ).first()
    
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Stock item not found"
        )
    
    db.delete(item)
    db.commit()
    
    return {"message": "Stock item deleted successfully"}
