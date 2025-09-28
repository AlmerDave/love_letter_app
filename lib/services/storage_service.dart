// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:love_letter_app/models/invitation.dart';
import 'package:love_letter_app/models/invitation_status.dart';

class StorageService {
  static const String _invitationsKey = 'love_letters_invitations';
  static const String _settingsKey = 'app_settings';
  
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  SharedPreferences? _prefs;

  // Initialize storage service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Save invitation to local storage
  Future<bool> saveInvitation(Invitation invitation) async {
    try {
      await initialize();
      
      final invitations = await getAllInvitations();
      
      // Update existing or add new
      final existingIndex = invitations.indexWhere((i) => i.id == invitation.id);
      if (existingIndex != -1) {
        invitations[existingIndex] = invitation;
      } else {
        invitations.add(invitation);
      }
      
      // Save to storage
      final jsonList = invitations.map((i) => i.toJson()).toList();
      return await _prefs!.setString(_invitationsKey, json.encode(jsonList));
    } catch (e) {
      print('Error saving invitation: $e');
      return false;
    }
  }

  // Get all invitations from storage
  Future<List<Invitation>> getAllInvitations() async {
    try {
      await initialize();
      
      final jsonString = _prefs!.getString(_invitationsKey);
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Invitation.fromJson(json)).toList();
    } catch (e) {
      print('Error loading invitations: $e');
      return [];
    }
  }

  // Get invitation by ID
  Future<Invitation?> getInvitationById(String id) async {
    final invitations = await getAllInvitations();
    try {
      return invitations.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update invitation status
  Future<bool> updateInvitationStatus(String id, InvitationStatus status) async {
    try {
      final invitation = await getInvitationById(id);
      if (invitation == null) return false;
      
      final updatedInvitation = invitation.copyWith(status: status);
      return await saveInvitation(updatedInvitation);
    } catch (e) {
      print('Error updating invitation status: $e');
      return false;
    }
  }

  // Delete invitation
  Future<bool> deleteInvitation(String id) async {
    try {
      await initialize();
      
      final invitations = await getAllInvitations();
      invitations.removeWhere((i) => i.id == id);
      
      final jsonList = invitations.map((i) => i.toJson()).toList();
      return await _prefs!.setString(_invitationsKey, json.encode(jsonList));
    } catch (e) {
      print('Error deleting invitation: $e');
      return false;
    }
  }

  // Get pending invitations (can be opened)
  Future<List<Invitation>> getPendingInvitations() async {
    final invitations = await getAllInvitations();
    return invitations.where((i) => 
      i.status == InvitationStatus.pending || 
      i.status == InvitationStatus.rejected
    ).toList();
  }

  // Get locked invitations
  Future<List<Invitation>> getLockedInvitations() async {
    final invitations = await getAllInvitations();
    return invitations.where((i) => i.isLocked).toList();
  }

  // Get completed invitations
  Future<List<Invitation>> getCompletedInvitations() async {
    final invitations = await getAllInvitations();
    return invitations.where((i) => 
      i.status == InvitationStatus.accepted || 
      i.status == InvitationStatus.completed
    ).toList();
  }

  // Check for unlocked letters (for notifications)
  Future<List<Invitation>> checkForNewlyUnlockedLetters() async {
    final invitations = await getAllInvitations();
    final now = DateTime.now();
    
    List<Invitation> newlyUnlocked = [];
    
    for (final invitation in invitations) {
      if (invitation.status == InvitationStatus.locked && 
          now.isAfter(invitation.unlockDateTime)) {
        // Update status to pending
        final updated = invitation.copyWith(status: InvitationStatus.pending);
        await saveInvitation(updated);
        newlyUnlocked.add(updated);
      }
    }
    
    return newlyUnlocked;
  }

  // Import invitation from QR code data
  Future<bool> importInvitationFromQR(String qrData) async {
    try {
      final Map<String, dynamic> data = json.decode(qrData);
      final invitation = Invitation.fromJson(data);
      return await saveInvitation(invitation);
    } catch (e) {
      print('Error importing invitation from QR: $e');
      return false;
    }
  }

  // Clear all data (for testing/reset)
  Future<bool> clearAllData() async {
    try {
      await initialize();
      return await _prefs!.remove(_invitationsKey);
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }

  // Save app settings
  Future<bool> saveSetting(String key, dynamic value) async {
    try {
      await initialize();
      final settings = await getSettings();
      settings[key] = value;
      return await _prefs!.setString(_settingsKey, json.encode(settings));
    } catch (e) {
      print('Error saving setting: $e');
      return false;
    }
  }

  // Get app settings
  Future<Map<String, dynamic>> getSettings() async {
    try {
      await initialize();
      final jsonString = _prefs!.getString(_settingsKey);
      if (jsonString == null) return {};
      return json.decode(jsonString);
    } catch (e) {
      print('Error loading settings: $e');
      return {};
    }
  }
}