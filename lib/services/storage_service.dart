import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';

class StorageService {
  static const String _keyContacts = 'gekko_contacts';
  static const String _keyDuressPhrase = 'gekko_duress_phrase';
  static const String _keyCheckInFreq = 'gekko_checkin_freq_minutes';
  static const String _keyApiKey = 'gekko_gemini_api_key';

  final SharedPreferences prefs;

  StorageService(this.prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Emergency Contacts ---
  List<Contact> getContacts() {
    final String? jsonStr = prefs.getString(_keyContacts);
    if (jsonStr == null || jsonStr.isEmpty) {
      // Default demo contacts if empty
      return [
        Contact(
          id: 'c1',
          name: 'Sarah (Sister)',
          phone: '+1 555-0144',
          relationship: 'Sister',
          notifyOnStart: true,
        ),
        Contact(
          id: 'c2',
          name: 'David (Partner)',
          phone: '+1 555-0188',
          relationship: 'Partner',
          notifyOnStart: true,
        ),
      ];
    }
    try {
      final List list = jsonDecode(jsonStr);
      return list.map((item) => Contact.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveContacts(List<Contact> contacts) async {
    final jsonList = contacts.map((c) => c.toJson()).toList();
    await prefs.setString(_keyContacts, jsonEncode(jsonList));
  }

  // --- Duress Phrase ---
  String getDuressPhrase() {
    return prefs.getString(_keyDuressPhrase) ?? 'everything is fine';
  }

  Future<void> saveDuressPhrase(String phrase) async {
    await prefs.setString(_keyDuressPhrase, phrase.trim());
  }

  // --- Check-in Frequency Preference Offset ---
  int getCheckInFreqMinutes() {
    return prefs.getInt(_keyCheckInFreq) ?? 10;
  }

  Future<void> saveCheckInFreqMinutes(int mins) async {
    await prefs.setInt(_keyCheckInFreq, mins);
  }

  // --- Gemini API Key ---
  String? getApiKey() {
    return prefs.getString(_keyApiKey);
  }

  Future<void> saveApiKey(String key) async {
    await prefs.setString(_keyApiKey, key.trim());
  }
}
