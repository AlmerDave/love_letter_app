# 📖 QR Code JSON Specification for Love Letters App

This document explains how the **Love Letters App** encodes and parses invitations using QR codes.  
All QR codes generated in the app contain a JSON payload that follows the structure defined below.

---

## 🎯 Purpose

The QR code is used to **share, store, and unlock invitations**.  
When scanned inside the app, the JSON data is decoded and converted into an `Invitation` object.

---

## 📦 JSON Structure

Every QR code encodes a **top-level object** with these fields:

```json
{
  "type": "love_letter_invitation",
  "version": "1.0",
  "data": {
    "id": "string (UUID)",
    "title": "string",
    "message": "string",
    "location": "string",
    "dateTime": "ISO-8601 date-time string",
    "unlockDateTime": "ISO-8601 date-time string",
    "status": "InvitationStatus enum value",
    "createdAt": "ISO-8601 date-time string",
    "imageUrl": "string (optional)"
  },
  "generated_at": "ISO-8601 date-time string"
}
```

---

## 📝 Field Descriptions

### Top-level fields
- **`type`**: Always `"love_letter_invitation"` (used for validation).  
- **`version`**: Schema version, currently `"1.0"`. Future updates may add new versions.  
- **`data`**: The actual `Invitation` object payload (see below).  
- **`generated_at`**: Timestamp when the QR code was generated.  

### `data` object (Invitation)
- **`id`**: Unique identifier (`UUID`).  
- **`title`**: Short title of the invitation (e.g., `"Dinner Under the Stars ✨"`).  
- **`message`**: Full love letter content. Supports line breaks and emojis.  
- **`location`**: Meeting place or description.  
- **`dateTime`**: When the event is scheduled to happen.  
- **`unlockDateTime`**: When the invitation becomes available to open.  
- **`status`**: Current status, from the `InvitationStatus` enum:  
  - `pending` → Invitation is sent, awaiting response.  
  - `accepted` → Invitation was accepted.  
  - `rejected` → Invitation was declined.  
  - `locked` → Invitation is locked until `unlockDateTime`.  
  - `completed` → Invitation event has passed / completed.  
- **`createdAt`**: When the invitation was created.  
- **`imageUrl`** *(optional)*: URL of an image associated with the invitation (e.g., romantic picture or event flyer).  

---

## 🔑 Example QR JSON

```json
{
  "type": "love_letter_invitation",
  "version": "1.0",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Weekend Adventure Mystery 🎪",
    "message": "My Adventurous Partner in Crime,\n\nI've been planning something special for us this weekend...",
    "location": "Meet me at our special place 💫",
    "dateTime": "2025-10-03T15:00:00Z",
    "unlockDateTime": "2025-10-01T00:00:00Z",
    "status": "InvitationStatus.locked",
    "createdAt": "2025-09-28T06:00:00Z",
    "imageUrl": "https://example.com/adventure.png"
  },
  "generated_at": "2025-09-28T06:30:00Z"
}
```

---

## 📲 How the App Uses It

1. **Generation** → `QRService.generateQRData(invitation)` produces JSON and encodes it into a QR code.  
2. **Scanning** → The app scans a QR code and passes its contents to `QRService.parseQRData(qrData)`.  
3. **Validation** →  
   - `type` must equal `"love_letter_invitation"`.  
   - `version` must be `"1.0"`.  
   - `data` must exist.  
4. **Parsing** → If valid, the JSON is converted into an `Invitation` object using `Invitation.fromJson`.  

---

## ⚠️ Notes & Best Practices

- Keep invitation messages **concise**; very large JSON payloads make QR codes harder to scan.  
- Use `unlockDateTime` to build anticipation for future invitations.  
- Always test QR codes on multiple devices to ensure scannability.  
- For very long or media-heavy invitations, consider encoding a **URL** instead of full JSON, pointing to hosted data.  
