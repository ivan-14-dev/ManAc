# ========================================
# Equipment Checkouts Router
# ========================================

import uuid
from typing import List
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import models, schemas
from ..auth import get_current_user
from ..database import get_db
from ..email_service import email_service
from ..websocket_manager import manager

router = APIRouter(prefix="/api/emprunts", tags=["Checkouts"])


@router.get("/", response_model=List[schemas.CheckoutResponse])
def get_all_checkouts(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get all checkouts"""
    checkouts = db.query(models.EquipmentCheckout).offset(skip).limit(limit).all()
    return checkouts


@router.get("/{checkout_id}", response_model=schemas.CheckoutResponse)
def get_checkout(
    checkout_id: str,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get a specific checkout"""
    checkout = db.query(models.EquipmentCheckout).filter(
        models.EquipmentCheckout.id == checkout_id
    ).first()
    
    if not checkout:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Checkout not found"
        )
    
    return checkout


@router.post("/", response_model=List[schemas.CheckoutResponse])
async def create_checkout(
    checkout_data: schemas.CheckoutCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Create a new checkout (emprunt) - supports multiple items via equipment_id as comma-separated"""
    
    # Handle multiple equipment IDs (comma-separated)
    equipment_ids = [eid.strip() for eid in checkout_data.equipment_id.split(",")]
    
    created_checkouts = []
    items_data = []
    
    for equipment_id in equipment_ids:
        # Get equipment
        equipment = db.query(models.Equipment).filter(
            models.Equipment.id == equipment_id
        ).first()
        
        if not equipment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Equipment not found: {equipment_id}"
            )
        
        # Check availability
        if equipment.available_quantity < checkout_data.quantity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Not enough {equipment.name} available"
            )
        
        # Create checkout
        checkout = models.EquipmentCheckout(
            id=str(uuid.uuid4()),
            equipment_id=equipment_id,
            equipment_name=equipment.name,
            equipment_photo_path=equipment.photo_path,
            borrower_name=checkout_data.borrower_name,
            borrower_cni=checkout_data.borrower_cni,
            borrower_email=checkout_data.borrower_email,
            destination_room=checkout_data.destination_room,
            quantity=checkout_data.quantity,
            notes=checkout_data.notes,
            user_id=current_user.id
        )
        
        # Update equipment availability
        equipment.available_quantity -= checkout_data.quantity
        if equipment.available_quantity == 0:
            equipment.status = "checked_out"
        
        db.add(checkout)
        created_checkouts.append(checkout)
        
        # Collect item data for email
        items_data.append({
            "name": equipment.name,
            "quantity": checkout_data.quantity,
            "id": equipment.id
        })
    
    db.commit()
    
    # Refresh to get IDs
    for checkout in created_checkouts:
        db.refresh(checkout)
    
    # Send email notification to borrower
    if checkout_data.borrower_email:
        email_service.send_borrow_confirmation(
            email=checkout_data.borrower_email,
            borrower_name=checkout_data.borrower_name,
            items=items_data,
            checkout_id=created_checkouts[0].id
        )
    
    # Broadcast to admins via WebSocket
    for checkout in created_checkouts:
        await manager.broadcast_checkout({
            "id": checkout.id,
            "equipment_name": checkout.equipment_name,
            "borrower_name": checkout.borrower_name,
            "quantity": checkout.quantity,
            "checkout_time": checkout.checkout_time.isoformat()
        })
    
    return created_checkouts


@router.put("/{checkout_id}/retour", response_model=schemas.CheckoutResponse)
async def return_checkout(
    checkout_id: str,
    return_data: schemas.CheckoutReturn,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Return equipment (retour)"""
    checkout = db.query(models.EquipmentCheckout).filter(
        models.EquipmentCheckout.id == checkout_id
    ).first()
    
    if not checkout:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Checkout not found"
        )
    
    if checkout.is_returned:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Equipment already returned"
        )
    
    # Update checkout
    checkout.is_returned = True
    checkout.return_time = datetime.utcnow()
    checkout.notes = return_data.notes if return_data.notes else checkout.notes
    
    # Update equipment availability
    equipment = db.query(models.Equipment).filter(
        models.Equipment.id == checkout.equipment_id
    ).first()
    
    if equipment:
        equipment.available_quantity += checkout.quantity
        equipment.status = "available"
    
    db.commit()
    db.refresh(checkout)
    
    # Send email notification
    if checkout.borrower_email:
        email_service.send_return_confirmation(
            email=checkout.borrower_email,
            borrower_name=checkout.borrower_name,
            items=[{"name": checkout.equipment_name}],
            checkout_id=checkout.id
        )
    
    # Broadcast return to admins
    await manager.broadcast_return({
        "id": checkout.id,
        "equipment_name": checkout.equipment_name,
        "borrower_name": checkout.borrower_name,
        "return_time": checkout.return_time.isoformat()
    })
    
    return checkout


@router.post("/bulk/retour")
async def return_multiple_checkouts(
    checkout_ids: List[str],
    notes: str = None,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Return multiple checkouts at once"""
    returned_checkouts = []
    
    for checkout_id in checkout_ids:
        checkout = db.query(models.EquipmentCheckout).filter(
            models.EquipmentCheckout.id == checkout_id
        ).first()
        
        if not checkout or checkout.is_returned:
            continue
        
        # Update checkout
        checkout.is_returned = True
        checkout.return_time = datetime.utcnow()
        checkout.notes = notes
        
        # Update equipment
        equipment = db.query(models.Equipment).filter(
            models.Equipment.id == checkout.equipment_id
        ).first()
        
        if equipment:
            equipment.available_quantity += checkout.quantity
            equipment.status = "available"
        
        returned_checkouts.append({
            "id": checkout.id,
            "equipment_name": checkout.equipment_name
        })
        
        # Send email
        if checkout.borrower_email:
            email_service.send_return_confirmation(
                email=checkout.borrower_email,
                borrower_name=checkout.borrower_name,
                items=[{"name": checkout.equipment_name}],
                checkout_id=checkout.id
            )
    
    db.commit()
    
    # Broadcast to admins
    for checkout_data in returned_checkouts:
        await manager.broadcast_return(checkout_data)
    
    return {
        "message": f"{len(returned_checkouts)} checkouts returned",
        "returned": returned_checkouts
    }


@router.delete("/{checkout_id}")
def delete_checkout(
    checkout_id: str,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Delete a checkout"""
    checkout = db.query(models.EquipmentCheckout).filter(
        models.EquipmentCheckout.id == checkout_id
    ).first()
    
    if not checkout:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Checkout not found"
        )
    
    db.delete(checkout)
    db.commit()
    
    return {"message": "Checkout deleted successfully"}
