# ========================================
# FastAPI Main Application
# ========================================

import json
from datetime import datetime
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from .database import init_db
from .routers import auth, stock, equipment, emprunts, users
from .schemas import HealthResponse
from .websocket_manager import manager
from .email_service import email_queue

# Create FastAPI app
app = FastAPI(
    title="ManAc API",
    description="Backend API for ManAc Stock Management Mobile App",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup_event():
    """Initialize database on startup"""
    init_db()
    email_queue.start()


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    email_queue.stop()


@app.get("/", tags=["Root"])
def root():
    """Root endpoint"""
    return {
        "message": "ManAc API - Stock Management System",
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/api/health", response_model=HealthResponse, tags=["Health"])
def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "database": "postgresql",
        "timestamp": datetime.utcnow()
    }


# WebSocket endpoint for real-time updates
@app.websocket("/ws/{role}")
async def websocket_endpoint(websocket: WebSocket, role: str = "all"):
    """WebSocket endpoint for real-time updates"""
    await manager.connect(websocket, role)
    try:
        while True:
            # Keep connection alive, wait for messages
            data = await websocket.receive_text()
            # Echo back for ping/pong
            await websocket.send_text(json.dumps({"type": "pong"}))
    except WebSocketDisconnect:
        manager.disconnect(websocket, role)


# Include routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(stock.router)
app.include_router(equipment.router)
app.include_router(emprunts.router)
