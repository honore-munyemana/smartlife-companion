import 'package:shared_preferences/shared_preferences.dart';

class ThemeHelper {
  static const String _keyTheme = 'theme_key';

  // Save theme mode preference
  static Future<void> saveTheme(bool isDarkMode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(_keyTheme, isDarkMode);
  }

  // Load theme mode preference
  static Future<bool> loadTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTheme) ?? false; // Default to light mode
  }
}
