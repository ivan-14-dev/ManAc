# ========================================
# WebSocket Manager - Real-time updates
# ========================================

from typing import Dict, List, Set
from fastapi import WebSocket
import json
from datetime import datetime


class ConnectionManager:
    """Manage WebSocket connections for real-time updates"""
    
    def __init__(self):
        # Active connections: role -> set of websockets
        self.active_connections: Dict[str, Set[WebSocket]] = {
            "admin": set(),
            "user": set(),
            "all": set(),
        }
    
    async def connect(self, websocket: WebSocket, role: str = "all"):
        """Connect a new WebSocket client"""
        await websocket.accept()
        self.active_connections[role].add(websocket)
        self.active_connections["all"].add(websocket)
        print(f"[WebSocket] Client connected. Role: {role}, Total: {len(self.active_connections['all'])}")
    
    def disconnect(self, websocket: WebSocket, role: str = "all"):
        """Disconnect a WebSocket client"""
        self.active_connections[role].discard(websocket)
        self.active_connections["all"].discard(websocket)
        print(f"[WebSocket] Client disconnected. Role: {role}")
    
    async def send_personal_message(self, message: dict, websocket: WebSocket):
        """Send message to a specific client"""
        try:
            await websocket.send_text(json.dumps(message))
        except Exception as e:
            print(f"[WebSocket] Error sending personal: {e}")
    
    async def broadcast(self, message: dict, role: str = "all"):
        """Broadcast message to all connected clients"""
        disconnected = []
        
        for connection in self.active_connections[role]:
            try:
                await connection.send_text(json.dumps(message))
            except Exception as e:
                print(f"[WebSocket] Error broadcasting: {e}")
                disconnected.append(connection)
        
        # Remove disconnected clients
        for conn in disconnected:
            self.disconnect(conn, role)
    
    async def broadcast_checkout(self, checkout_data: dict):
        """Broadcast new checkout to admins"""
        message = {
            "type": "checkout_created",
            "data": checkout_data,
            "timestamp": datetime.utcnow().isoformat()
        }
        await self.broadcast(message, "admin")
    
    async def broadcast_return(self, return_data: dict):
        """Broadcast return to admins"""
        message = {
            "type": "checkout_returned",
            "data": return_data,
            "timestamp": datetime.utcnow().isoformat()
        }
        await self.broadcast(message, "admin")
    
    async def broadcast_stock_update(self, stock_data: dict):
        """Broadcast stock update to all"""
        message = {
            "type": "stock_updated",
            "data": stock_data,
            "timestamp": datetime.utcnow().isoformat()
        }
        await self.broadcast(message, "all")
    
    async def broadcast_activity(self, activity_data: dict):
        """Broadcast activity to all"""
        message = {
            "type": "activity",
            "data": activity_data,
            "timestamp": datetime.utcnow().isoformat()
        }
        await self.broadcast(message, "all")


# Singleton instance
manager = ConnectionManager()
