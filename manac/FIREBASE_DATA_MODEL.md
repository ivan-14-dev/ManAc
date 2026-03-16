# Firebase Firestore Data Model

This document describes the data model for ManAc app synchronization with Firebase Firestore.

## Collections

### 1. equipment_checkouts
```json
{
  "id": "uuid-string",
  "equipmentId": "equipment-uuid",
  "equipmentName": "Projecteur LCD",
  "equipmentPhotoPath": "path/to/photo.jpg",
  "borrowerName": "John Doe",
  "borrowerCni": "CM123456789",
  "cniPhotoPath": "path/to/cni.jpg",
  "destinationRoom": "Salle A101",
  "quantity": 2,
  "checkoutTime": "2024-01-15T10:30:00.000Z",
  "returnTime": null,
  "isReturned": false,
  "notes": "Pour présentation",
  "userId": "user-uuid",
  "userName": "Admin User",
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:30:00.000Z"
}
```

### 2. equipment
```json
{
  "id": "uuid-string",
  "name": "Projecteur LCD",
  "category": "Electronique",
  "totalQuantity": 5,
  "availableQuantity": 3,
  "photoPath": "path/to/photo.jpg",
  "description": "Projecteur HD",
  "location": "Magasin A",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-15T10:30:00.000Z"
}
```

### 3. activities
```json
{
  "id": "uuid-string",
  "type": "checkout|return|login|logout",
  "title": "Emprunt d'équipement",
  "description": "Emprunt de 2 Projecteur LCD par Jean par Admin",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "userId": "user-uuid",
  "userName": "Admin User",
  "metadata": {
    "equipmentId": "equipment-uuid",
    "equipmentName": "Projecteur LCD",
    "borrowerName": "Jean",
    "quantity": 2,
    "checkoutTime": "2024-01-15T10:30:00.000Z"
  },
  "createdAt": "2024-01-15T10:30:00.000Z"
}
```

### 4. stock_items (for inventory)
```json
{
  "id": "uuid-string",
  "name": "Projecteur LCD",
  "category": "Electronique",
  "quantity": 5,
  "minQuantity": 2,
  "unit": "piece",
  "price": 500.00,
  "description": "Projecteur HD 1080p",
  "barcode": "PROJ-001",
  "location": "Magasin A",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-15T10:30:00.000Z"
}
```

### 5. stock_movements
```json
{
  "id": "uuid-string",
  "stockItemId": "stock-item-uuid",
  "type": "in|out|adjustment",
  "quantity": 5,
  "reason": "Achat",
  "reference": "BON-001",
  "date": "2024-01-15T10:30:00.000Z",
  "userId": "user-uuid",
  "userName": "Admin User",
  "createdAt": "2024-01-15T10:30:00.000Z"
}
```

## Firebase Storage Structure

```
manac-storage/
├── equipment/
│   ├── {equipment_id}/
│   │   ├── photo.jpg
│   │   └── thumbnail.jpg
│   │
├── cni/
│   ├── {checkout_id}/
│   │   └── cni_photo.jpg
│   │
└── reports/
    └── {date}/
        └── report.pdf
```

## Firestore Indexes Required

Create these indexes in Firebase Console:

1. **equipment_checkouts** collection:
   - Field: `isReturned` (ascending)
   - Field: `checkoutTime` (descending)

2. **activities** collection:
   - Field: `timestamp` (descending)
   - Field: `type` (ascending)

3. **stock_movements** collection:
   - Field: `stockItemId` (ascending)
   - Field: `date` (descending)

## Security Rules (firestore.rules)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User authentication required
    match /equipment_checkouts/{checkoutId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    match /equipment/{equipmentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    match /activities/{activityId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    match /stock_items/{itemId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Storage Security Rules (storage.rules)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /equipment/{equipmentId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    match /cni/{checkoutId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Sync Strategy

### For Offline-First Sync:

1. **Local Storage** (Priority):
   - All data saved to local storage first
   - Sync queue tracks changes

2. **Firebase Sync** (When online):
   - Push local changes to Firebase
   - Pull remote changes to local

3. **Conflict Resolution**:
   - Last-write-wins based on `updatedAt` timestamp
   - Keep `isSynced` flag to track sync status
