# ========================================
# Database Models - SQLAlchemy
# ========================================

from sqlalchemy import Column, String, Integer, Float, DateTime, Boolean, Text, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base


class User(Base):
    """User model"""
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)
    phone = Column(String, nullable=True)
    department = Column(String, nullable=True)
    password_hash = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    stock_items = relationship("StockItem", back_populates="user")
    equipment = relationship("Equipment", back_populates="user")
    checkouts = relationship("EquipmentCheckout", back_populates="user")


class StockItem(Base):
    """Stock Item model"""
    __tablename__ = "stock_items"

    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    category = Column(String, nullable=False)
    quantity = Column(Integer, default=0)
    min_quantity = Column(Integer, default=0)
    unit = Column(String, default="pcs")
    price = Column(Float, default=0.0)
    description = Column(Text, nullable=True)
    barcode = Column(String, nullable=True)
    location = Column(String, default="Main Warehouse")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_synced = Column(Boolean, default=False)
    firebase_id = Column(String, nullable=True)
    
    # Foreign key
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    user = relationship("User", back_populates="stock_items")


class Equipment(Base):
    """Equipment model"""
    __tablename__ = "equipment"

    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    category = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    serial_number = Column(String, nullable=False)
    barcode = Column(String, nullable=True)
    location = Column(String, nullable=False)
    status = Column(String, default="available")  # available, checked_out, maintenance, retired
    total_quantity = Column(Integer, default=1)
    available_quantity = Column(Integer, default=1)
    photo_path = Column(String, nullable=True)
    value = Column(Float, default=0.0)
    purchase_date = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_synced = Column(Boolean, default=False)
    
    # Foreign key
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    user = relationship("User", back_populates="equipment")
    
    # Relationships
    checkouts = relationship("EquipmentCheckout", back_populates="equipment")


class EquipmentCheckout(Base):
    """Equipment Checkout model"""
    __tablename__ = "equipment_checkouts"

    id = Column(String, primary_key=True, index=True)
    equipment_id = Column(String, ForeignKey("equipment.id"), nullable=False)
    equipment_name = Column(String, nullable=False)
    equipment_photo_path = Column(String, nullable=True)
    borrower_name = Column(String, nullable=False)
    borrower_cni = Column(String, nullable=False)
    borrower_email = Column(String, nullable=True)
    cni_photo_path = Column(String, nullable=True)
    destination_room = Column(String, nullable=False)
    quantity = Column(Integer, default=1)
    checkout_time = Column(DateTime, default=datetime.utcnow)
    return_time = Column(DateTime, nullable=True)
    is_returned = Column(Boolean, default=False)
    notes = Column(Text, nullable=True)
    is_synced = Column(Boolean, default=False)
    
    # Foreign keys
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    user = relationship("User", back_populates="checkouts")
    equipment = relationship("Equipment", back_populates="checkouts")


class Activity(Base):
    """Activity log model"""
    __tablename__ = "activities"

    id = Column(String, primary_key=True, index=True)
    type = Column(String, nullable=False)  # stock_in, stock_out, sync, login, logout, connection
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
    metadata = Column(Text, nullable=True)  # JSON string
    is_synced = Column(Boolean, default=False)
    
    # Foreign key
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
