// lib/models/invitation_status.dart

enum InvitationStatus {
  pending,    // Letter is available but not yet responded to
  accepted,   // Letter was accepted
  rejected,   // Letter was rejected (can be reconsidered)
  completed,  // Date has passed
  locked,     // Letter is time-locked
}

extension InvitationStatusExtension on InvitationStatus {
  String get displayName {
    switch (this) {
      case InvitationStatus.pending:
        return 'Awaiting Response';
      case InvitationStatus.accepted:
        return 'Accepted ♥';
      case InvitationStatus.rejected:
        return 'Needs Reconsideration';
      case InvitationStatus.completed:
        return 'Completed';
      case InvitationStatus.locked:
        return 'Time Locked';
    }
  }

  String get description {
    switch (this) {
      case InvitationStatus.pending:
        return 'Tap to open and respond';
      case InvitationStatus.accepted:
        return 'Looking forward to our date!';
      case InvitationStatus.rejected:
        return 'Maybe reconsider? 🥺';
      case InvitationStatus.completed:
        return 'What a wonderful memory!';
      case InvitationStatus.locked:
        return 'Available soon...';
    }
  }

  bool get canBeOpened {
    return this == InvitationStatus.pending || 
           this == InvitationStatus.rejected ||
           this == InvitationStatus.accepted || 
           this == InvitationStatus.completed;
  }

  bool get isCompleted {
    return this == InvitationStatus.completed;
  }

  bool get isPositive {
    return this == InvitationStatus.accepted || 
           this == InvitationStatus.completed;
  }
}