// lib/services/sample_data_service.dart
import 'package:uuid/uuid.dart';
import 'package:love_letter_app/models/invitation.dart';
import 'package:love_letter_app/models/invitation_status.dart';
import 'package:love_letter_app/services/storage_service.dart';

class SampleDataService {
  static const Uuid _uuid = Uuid();

  /// Initialize sample data if no invitations exist
  static Future<void> initializeSampleData() async {
    final existingInvitations = await StorageService.instance.getAllInvitations();
    
    // Only add sample data if no invitations exist
    if (existingInvitations.isEmpty) {
      await _createSingleLetter();
      // await _createSampleInvitations();
    }
  }

/// Create a single invitation that can be opened immediately
static Future<void> _createSingleLetter() async {
  final invitation = Invitation(
    id: _uuid.v4(),
    title: "17th Monsthary BB Date 💗🥰",
    message: 
        "Para sa bb laaaabs of my lifeeee kooo,\n\n"
        "Feel ko nagulat ka na nabasa mo ito hahahah "
        "ito din yung pinag kakaabalahan simuka nung weekend, "
        "pero dahil paparating na yung October 6 bb or yung first bb date "
        "natenn ulit bb gusto siya gawing special kayaaa may pag aya bb gamit app "
        "HAHAHA testing palang din ito bb pero baka madalas ko itong gamitinnnn hahahaha\n\n"
        "Nasa baba din bb yung details at time 🥹🥹\n\n"
        "Kikita na din tayo bb sobra sobraaangg happyyy 💕",
    location: "Philippine Orthopedic Center",
    dateTime: DateTime(2025, 10, 6, 8, 0), // October 6, 2025 8:00 AM
    unlockDateTime: DateTime(2025, 9, 27, 12, 0), // September 27, 2025 12:00 PM (can be opened immediately)
    status: InvitationStatus.pending,
    createdAt: DateTime(2025, 9, 27, 10, 30), // Created September 27, 2025 10:30 AM
  );

  await StorageService.instance.saveInvitation(invitation);
}


  /// Create beautiful sample love letters
  static Future<void> _createSampleInvitations() async {
    final now = DateTime.now();
    
    final sampleInvitations = [
      // Available letter - can be opened immediately
      Invitation(
        id: _uuid.v4(),
        title: "Dinner Under the Stars ✨",
        message: "My Dearest Love,\n\nI've been thinking about how beautiful you look when you smile, and I realized I want to see that smile across from me at our favorite little restaurant tonight.\n\nJoin me for dinner? I promise good food, better conversation, and maybe a surprise or two along the way.\n\nI can't wait to hold your hand across the table and tell you all the reasons why you make my world brighter.\n\nWith all my love and excitement for tonight! 💕",
        location: "La Petit Bistro - Downtown",
        dateTime: now.add(Duration(hours: 6)),
        unlockDateTime: now.subtract(Duration(minutes: 5)), // Available now
        status: InvitationStatus.pending,
        createdAt: now.subtract(Duration(hours: 2)),
      ),

      // Accepted letter - example of positive response
      Invitation(
        id: _uuid.v4(),
        title: "Morning Coffee Date ☕",
        message: "Good morning, Beautiful!\n\nI know you have that big presentation today, so I thought we could start with some coffee and pastries at that cute café you love.\n\nI want to be there to calm your nerves and remind you how absolutely brilliant you are. Plus, I have a good luck charm for you!\n\nWhat do you say? Coffee, encouragement, and all my love to start your day right?\n\nBelieving in you always! ❤️",
        location: "Sunrise Café - Corner of 5th & Main",
        dateTime: now.add(Duration(days: 1, hours: 8)),
        unlockDateTime: now.subtract(Duration(hours: 12)),
        status: InvitationStatus.accepted,
        createdAt: now.subtract(Duration(hours: 15)),
      ),

      // Locked letter - builds anticipation
      Invitation(
        id: _uuid.v4(),
        title: "Weekend Adventure Mystery 🎪",
        message: "My Adventurous Partner in Crime,\n\nI've been planning something special for us this weekend, and I literally cannot contain my excitement!\n\nI won't spoil the surprise, but pack comfortable shoes, bring your sense of adventure, and prepare for a day filled with laughter, new experiences, and memories we'll treasure forever.\n\nTrust me when I say this will be a day you'll never forget. I've been planning this for weeks because you deserve all the magic in the world.\n\nGet ready for our best adventure yet! 🎠✨",
        location: "Meet me at our special place 💫",
        dateTime: now.add(Duration(days: 5, hours: 10)),
        unlockDateTime: now.add(Duration(days: 2)), // Locked for 2 more days
        status: InvitationStatus.locked,
        createdAt: now.subtract(Duration(hours: 1)),
      ),

      // Another locked letter - different unlock time
      Invitation(
        id: _uuid.v4(),
        title: "Midnight Surprise 🌙",
        message: "My Night Owl,\n\nI know you've been working so hard lately, and I see how dedicated you are to everything you do. It's one of the million things I adore about you.\n\nBut tonight, I want to steal you away from all the stress and show you something magical. When the clock strikes midnight, meet me on the rooftop.\n\nI'll have blankets, hot chocolate, and a telescope pointed at the most beautiful constellation - though nothing in the sky could compare to you.\n\nMidnight. Rooftop. Be there. 🌟",
        location: "Our Building Rooftop",
        dateTime: now.add(Duration(hours: 18)),
        unlockDateTime: now.add(Duration(hours: 8)), // Unlocks in 8 hours
        status: InvitationStatus.locked,
        createdAt: now,
      ),

      // Completed letter - nostalgic memory
      Invitation(
        id: _uuid.v4(),
        title: "Our First Date Recreation 💕",
        message: "My Forever Love,\n\nDo you remember our very first date? The nervous butterflies, the endless conversation, the way time seemed to stop when you laughed?\n\nI want to recreate that magic. Same restaurant, same nervous excitement (yes, you still give me butterflies!), but with all the love that's grown between us since that perfect night.\n\nLet's go back to where it all began and celebrate how far we've come while remembering what made us fall for each other in the first place.\n\nHere's to our love story continuing forever! 🥂",
        location: "Mario's Italian Restaurant",
        dateTime: now.subtract(Duration(days: 3)),
        unlockDateTime: now.subtract(Duration(days: 5)),
        status: InvitationStatus.completed,
        createdAt: now.subtract(Duration(days: 7)),
      ),

      // Rejected letter - shows the cute intervention
      Invitation(
        id: _uuid.v4(),
        title: "Spontaneous Road Trip! 🚗",
        message: "My Beautiful Wanderer,\n\nI know it's last minute, but I just had the most amazing idea! What if we packed a bag right now and drove to that little coastal town we saw in the movie last week?\n\nWe could watch the sunset over the ocean, find a cozy bed & breakfast, and spend tomorrow exploring tide pools and eating fish and chips.\n\nI know you love spontaneous adventures, and I promise this will be the kind of trip we'll laugh about for years to come.\n\nSay yes to the adventure? Your chariot (my slightly messy car) awaits! 🌊",
        location: "Seaside Village - 2 hours north",
        dateTime: now.add(Duration(hours: 4)),
        unlockDateTime: now.subtract(Duration(hours: 1)),
        status: InvitationStatus.pending,
        createdAt: now.subtract(Duration(hours: 3)),
      ),
    ];

    // Save all sample invitations
    for (final invitation in sampleInvitations) {
      await StorageService.instance.saveInvitation(invitation);
    }
  }

  /// Add a single test invitation (for testing purposes)
  static Future<void> addTestInvitation() async {
    final now = DateTime.now();
    
    final testInvitation = Invitation(
      id: _uuid.v4(),
      title: "Quick Test Date 🧪",
      message: "Hey Beautiful!\n\nThis is a test invitation to see how amazing this app looks with your love letters!\n\nIsn't the UI just gorgeous? I can't wait to send you real romantic invitations through this app.\n\nThis is just a preview of all the sweet surprises coming your way! 💕",
      location: "Test Location - Anywhere with you!",
      dateTime: now.add(Duration(hours: 2)),
      unlockDateTime: now.subtract(Duration(minutes: 1)),
      status: InvitationStatus.pending,
      createdAt: now,
    );

    await StorageService.instance.saveInvitation(testInvitation);
  }

  /// Clear all sample data (for testing)
  static Future<void> clearAllSampleData() async {
    await StorageService.instance.clearAllData();
  }

  /// Get sample QR data for testing
  static Map<String, dynamic> getSampleQRData() {
    final now = DateTime.now();
    
    final sampleInvitation = Invitation(
      id: _uuid.v4(),
      title: "QR Test Letter 📱",
      message: "Congratulations!\n\nYou successfully scanned a QR code! This is how you'll receive all your future love letters.\n\nI'm so excited to use this app to surprise you with romantic invitations, sweet messages, and unforgettable date ideas.\n\nWelcome to our new way of sharing love! 💕",
      location: "Wherever love takes us!",
      dateTime: now.add(Duration(hours: 24)),
      unlockDateTime: now.add(Duration(minutes: 5)),
      status: InvitationStatus.locked,
      createdAt: now,
    );

    return {
      'type': 'love_letter_invitation',
      'version': '1.0',
      'data': sampleInvitation.toJson(),
      'generated_at': now.toIso8601String(),
    };
  }
}