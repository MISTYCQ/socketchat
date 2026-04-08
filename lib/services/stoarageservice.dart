import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service for user data
/// Saves logged-in usernames and recent contacts
class StorageService {
  static const String _keyRecentUsers = 'recent_users';
  static const String _keyLastUsername = 'last_username';
  static const String _keySavedContacts = 'saved_contacts';

  /// Save a username to recent users list
  static Future<void> saveRecentUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final recent = await getRecentUsers();
    
    // Add to front, remove duplicates
    recent.remove(username);
    recent.insert(0, username);
    
    // Keep only last 10
    if (recent.length > 10) {
      recent.removeRange(10, recent.length);
    }
    
    await prefs.setStringList(_keyRecentUsers, recent);
    await prefs.setString(_keyLastUsername, username);
  }

  /// Get list of recent usernames
  static Future<List<String>> getRecentUsers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyRecentUsers) ?? [];
  }

  /// Get last used username
  static Future<String?> getLastUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastUsername);
  }

  /// Save a contact
  static Future<void> saveContact(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = await getSavedContacts();
    
    if (!contacts.contains(username)) {
      contacts.add(username);
      await prefs.setStringList(_keySavedContacts, contacts);
    }
  }

  /// Remove a contact
  static Future<void> removeContact(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = await getSavedContacts();
    
    contacts.remove(username);
    await prefs.setStringList(_keySavedContacts, contacts);
  }

  /// Get saved contacts
  static Future<List<String>> getSavedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keySavedContacts) ?? [];
  }

  /// Clear all stored data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}