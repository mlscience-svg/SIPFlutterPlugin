import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigStorage {
  static const sip_config = 'sip_config';
  static const stun_config = 'stun_config';
  static const turn_config = 'turn_config';

  static Future<void> save(String key, Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(config));
  }

  static Future<Map<String, dynamic>?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(key);
    if (jsonStr != null) {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    }
    return null;
  }
}
