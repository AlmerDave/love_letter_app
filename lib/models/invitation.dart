// lib/models/invitation.dart
import 'package:love_letter_app/models/invitation_status.dart';

class Invitation {
  final String id;
  final String title;
  final String message;
  final String location;
  final DateTime dateTime;
  final DateTime unlockDateTime;
  final InvitationStatus status;
  final DateTime createdAt;
  final String? imageUrl; // Optional romantic image

  Invitation({
    required this.id,
    required this.title,
    required this.message,
    required this.location,
    required this.dateTime,
    required this.unlockDateTime,
    required this.status,
    required this.createdAt,
    this.imageUrl,
  });

  // Check if invitation is currently locked
  bool get isLocked => DateTime.now().isBefore(unlockDateTime);
  
  // Check if invitation is available to open
  bool get isAvailable => !isLocked && status == InvitationStatus.pending;
  
  // Get time remaining until unlock
  Duration get timeUntilUnlock => unlockDateTime.difference(DateTime.now());

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'location': location,
      'dateTime': dateTime.toIso8601String(),
      'unlockDateTime': unlockDateTime.toIso8601String(),
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  // Create from JSON
  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      location: json['location'],
      dateTime: DateTime.parse(json['dateTime']),
      unlockDateTime: DateTime.parse(json['unlockDateTime']),
      status: InvitationStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      imageUrl: json['imageUrl'],
    );
  }

  // Create copy with updated status
  Invitation copyWith({
    String? id,
    String? title,
    String? message,
    String? location,
    DateTime? dateTime,
    DateTime? unlockDateTime,
    InvitationStatus? status,
    DateTime? createdAt,
    String? imageUrl,
  }) {
    return Invitation(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      location: location ?? this.location,
      dateTime: dateTime ?? this.dateTime,
      unlockDateTime: unlockDateTime ?? this.unlockDateTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'Invitation(id: $id, title: $title, status: $status, isLocked: $isLocked)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Invitation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}