# 📖 QR Code Specification for Love Letters App

This document explains how the **Love Letters App** encodes and parses invitations using QR codes.

---

## 🎯 Purpose

The QR code is used to **share, store, and unlock invitations**.  
When scanned inside the app, the data is decoded and converted into an `Invitation` object.

---

## ✨ NEW: Flexible QR Code Formats

The app now supports **multiple QR code formats** - from simple plain text to full JSON!  
You can use whichever format is easiest for you.

---

## 📝 Supported Formats

### Format 1: Simple Key-Value (RECOMMENDED) ⭐

**✅ Copy this exact example to test:**
```
Title: Test Love Letter 💕
Message: This is a test message. If you can read this, scanning works!
Location: Our favorite place
Date: 2025-12-25 7:00 PM
Unlock: 2025-11-13 5:00 PM
```

**Rules:**
- Each line: `Key: Value`
- Keys are case-insensitive (`title`, `Title`, `TITLE` all work)
- Only **Title** OR **Message** is required (everything else is optional)
- Emojis are fully supported! 💕✨🎪
- Line breaks create new fields automatically

**Alternative Key Names (All Work!):**
- **Title**: `title`, `subject`, `event`, `heading`
- **Message**: `message`, `msg`, `text`, `note`, `content`
- **Location**: `location`, `place`, `venue`, `loc`, `where`
- **Date**: `date`, `datetime`, `when`, `eventdate`, `time`
- **Unlock**: `unlock`, `unlockdatetime`, `open`, `available`, `openon`

---

### Format 2: Minimal (Smart Defaults) 🚀

Only provide what you want - the rest auto-fills!
```
Title: DATE 💕
Message: Miss na kita!
```

**What gets auto-filled:**
- `Location`: "To be announced"
- `Date`: 7 days from now
- `Unlock`: Right now (immediately available)
- `ID`: Auto-generated unique ID
- `Status`: Pending

---

### Format 3: Flexible Plain Text 🎨

The parser is smart! These all work:

**Casual format:**
```
Title is: Weekend Adventure
Message: Hey, want to hang out?
Location will be: Coffee shop
When: November 20, 2025 at 3pm
Can open: November 15, 2025 at 5pm
```

**Compact format:**
```
title: Date Night
message: Dinner?
location: Restaurant
date: 2025-11-20 19:00
unlock: 2025-11-15 17:00
```

**Mixed format:**
```
TITLE: Movie Night 🎬
msg: Let's watch a movie!
place: Cinema
when: Nov 25, 2025 8:00 PM
open: Nov 20, 2025
```

---

### Format 4: Full JSON (Advanced) 🔧

For programmatic generation or backward compatibility:

**⚠️ Must be a SINGLE LINE - no line breaks!**
```json
{"type":"love_letter_invitation","version":"1.0","data":{"id":"test-001","title":"Test Love Letter 💕","message":"This is a test invitation. If you can read this, scanning works!","location":"Test Location","dateTime":"2025-12-25T19:00:00.000Z","unlockDateTime":"2025-11-13T00:00:00.000Z","status":"InvitationStatus.pending","createdAt":"2025-11-13T10:00:00.000Z","imageUrl":null},"generated_at":"2025-11-13T10:00:00.000Z"}
```

---

## 📅 Date Format Support

The parser accepts multiple date formats:

**ISO Format (Recommended):**
```
2025-11-15T15:00:00.000Z
2025-11-15T15:00:00Z
```

**Readable Formats:**
```
2025-11-15 3:00 PM
2025-11-15 15:00
11/15/2025 3:00 PM
11/15/2025 15:00
Nov 15, 2025 3:00 PM
November 15, 2025 3:00 PM
```

**Date Only (time defaults to midnight):**
```
2025-11-15
```

---

## 🧪 Quick Start Test Examples

### Example 1: Minimal Love Letter
```
Title: Coffee Date ☕
Message: Want to grab coffee with me?
```

### Example 2: Complete Love Letter
```
Title: Romantic Dinner 🌹
Message: I've been thinking about you all day. Would you join me for a special dinner tonight?
Location: The Romantic Restaurant, 123 Love Street
Date: 2025-12-14 7:00 PM
Unlock: 2025-12-10 9:00 AM
```

### Example 3: Tagalog Love Letter
```
Title: Date Tayo! 💕
Message: Miss na miss na kita sobra! Tara date tayo this weekend? Promise masaya yan! 🥰
Location: Mall
Date: 2025-11-20 3:00 PM
Unlock: 2025-11-15 5:00 PM
```

### Example 4: Event Invitation
```
Title: Birthday Surprise Party 🎉
Message: You're invited to my birthday party! It's a surprise theme, so dress fancy!
Location: My place
Date: 2025-12-01 6:00 PM
Unlock: 2025-11-25 12:00 PM
```

---

## 📲 How to Generate QR Codes

### Method 1: Online QR Generator (Easiest)

1. Go to https://www.qr-code-generator.com/
2. Select **"Text"** type
3. Copy one of the examples above
4. Paste into the text field
5. Click **"Create QR Code"**
6. Download and share!

### Method 2: Other Recommended Generators

- https://www.qr-monkey.com/ (select "Text")
- https://qr.io/ (select "Text")
- Any QR generator that supports **plain text**

### Method 3: In-App (Coming Soon)

The app will have a built-in QR generator - just fill a form!

---

## ⚠️ Important Rules

### ✅ DO:
- Use **"Text"** or **"Plain Text"** mode in QR generators
- Use straight quotes: `"`
- Keep messages under 500 characters for best scanning
- Test your QR code before sharing
- Use emojis freely! 💕

### ❌ DON'T:
- Use URL, vCard, or other QR types
- Use smart/curly quotes: `""`
- Add extra formatting or line breaks (unless using simple key-value format)
- Make QR codes too small (minimum 300x300 pixels)

---

## 🔧 Technical Details (For Developers)

### Parsing Flow

The app uses a **cascading parser** that tries formats in this order:

1. **Full JSON** → Original format with `type` and `version` wrapper
2. **Plain Text Key-Value** → Parses `Key: Value` format
3. **Smart Extraction** → Uses regex to extract fields from any text

### Required Fields

**Minimum required:** Just **ONE** of these:
- `title` OR `message`

**Auto-generated if missing:**
- `id` → Random UUID
- `location` → "To be announced"
- `dateTime` → 7 days from now
- `unlockDateTime` → Current time (immediately unlocked)
- `status` → `pending`
- `createdAt` → Current time
- `imageUrl` → `null`

### Full JSON Structure (For Reference)
```json
{
  "type": "love_letter_invitation",
  "version": "1.0",
  "data": {
    "id": "string (UUID)",
    "title": "string",
    "message": "string",
    "location": "string",
    "dateTime": "ISO-8601 datetime",
    "unlockDateTime": "ISO-8601 datetime",
    "status": "InvitationStatus.pending",
    "createdAt": "ISO-8601 datetime",
    "imageUrl": "string or null"
  },
  "generated_at": "ISO-8601 datetime"
}
```

---

## 🐛 Troubleshooting

### "Invalid love letter QR code"

**Try these solutions:**

1. **Use the simple format:**
```
   Title: Test
   Message: Hello
```

2. **Check your QR generator** - Must be "Text" mode, not URL

3. **Remove extra spaces** - One space after colon is enough

4. **Use straight quotes** - Not smart quotes

5. **Test with example** - Copy one of the examples above exactly

### "This love letter has already been added"

The invitation ID already exists. Change the `id` field or delete the existing one.

### QR Code Won't Scan

- **Lighting** - Ensure good lighting on the QR code
- **Size** - QR code should be at least 2x2 inches
- **Distance** - Try moving phone closer/farther
- **Focus** - Make sure camera is focused
- **Quality** - Generate high-resolution QR codes (300x300 minimum)

---

## 💡 Tips & Best Practices

### For Best Results:
- Keep messages short and sweet (under 200 chars)
- Use emojis to add personality! 💕✨
- Test QR codes before sharing
- Set unlock dates strategically for anticipation
- Use descriptive titles

### Message Ideas:
- Romantic dinner invitations
- Date proposals
- Birthday surprises
- Anniversary messages
- "Just because" love notes
- Apology letters
- Thank you messages

---

## 📚 Related Files

- **Model**: `lib/models/invitation.dart`
- **QR Service**: `lib/services/qr_service.dart`
- **Scanner**: `lib/screens/qr_scanner_screen.dart`
- **Status Enum**: `lib/models/invitation_status.dart`

---

## 🆘 Still Having Issues?

**Debugging Checklist:**

- [ ] Using "Text" mode in QR generator
- [ ] At least Title OR Message is provided
- [ ] No smart quotes (use straight quotes: ")
- [ ] Camera permissions granted
- [ ] Good lighting on QR code
- [ ] QR code is clear and not blurry
- [ ] Tried the test examples above

**Need more help?** Check the app console for detailed error messages.

---

**Last Updated**: November 13, 2025  
**Parser Version**: 2.0 (Multi-format support)  
**Schema Version**: 1.0 (Backward compatible)