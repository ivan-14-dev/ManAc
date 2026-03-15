# ========================================
# Pydantic Schemas
# ========================================

from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime


# ==================== User Schemas ====================

class UserBase(BaseModel):
    email: EmailStr
    name: str
    phone: Optional[str] = None
    department: Optional[str] = None


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    department: Optional[str] = None


class UserResponse(UserBase):
    id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


# ==================== Stock Item Schemas ====================

class StockItemBase(BaseModel):
    name: str
    category: str
    quantity: int
    min_quantity: int
    unit: str = "pcs"
    price: float
    description: Optional[str] = None
    barcode: Optional[str] = None
    location: str = "Main Warehouse"


class StockItemCreate(StockItemBase):
    pass


class StockItemUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    quantity: Optional[int] = None
    min_quantity: Optional[int] = None
    unit: Optional[str] = None
    price: Optional[float] = None
    description: Optional[str] = None
    barcode: Optional[str] = None
    location: Optional[str] = None


class StockItemResponse(StockItemBase):
    id: str
    created_at: datetime
    updated_at: datetime
    is_synced: bool
    firebase_id: Optional[str] = None
    user_id: str

    class Config:
        from_attributes = True


# ==================== Equipment Schemas ====================

class EquipmentBase(BaseModel):
    name: str
    category: str
    description: str
    serial_number: str
    barcode: Optional[str] = None
    location: str
    status: str = "available"
    total_quantity: int = 1
    available_quantity: int = 1
    photo_path: Optional[str] = None
    value: float = 0.0
    purchase_date: Optional[datetime] = None


class EquipmentCreate(EquipmentBase):
    pass


class EquipmentUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None
    serial_number: Optional[str] = None
    barcode: Optional[str] = None
    location: Optional[str] = None
    status: Optional[str] = None
    total_quantity: Optional[int] = None
    available_quantity: Optional[int] = None
    photo_path: Optional[str] = None
    value: Optional[float] = None
    purchase_date: Optional[datetime] = None


class EquipmentResponse(EquipmentBase):
    id: str
    created_at: datetime
    updated_at: datetime
    is_synced: bool
    user_id: str

    class Config:
        from_attributes = True


# ==================== Checkout Schemas ====================

class CheckoutBase(BaseModel):
    equipment_id: str
    borrower_name: str
    borrower_cni: str
    borrower_email: Optional[EmailStr] = None
    destination_room: str
    quantity: int = 1
    notes: Optional[str] = None


class CheckoutCreate(CheckoutBase):
    pass


class CheckoutReturn(BaseModel):
    notes: Optional[str] = None


class CheckoutResponse(CheckoutBase):
    id: str
    equipment_name: str
    equipment_photo_path: Optional[str] = None
    cni_photo_path: Optional[str] = None
    checkout_time: datetime
    return_time: Optional[datetime] = None
    is_returned: bool
    is_synced: bool
    user_id: str

    class Config:
        from_attributes = True


# ==================== Health Check ====================

class HealthResponse(BaseModel):
    status: str
    database: str
    timestamp: datetime
