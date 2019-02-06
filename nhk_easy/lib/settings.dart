import 'package:shared_preferences/shared_preferences.dart';

void saveBrightness(final bool _isDark) async {
  final SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();
  sharedPreferences.setBool('isDark', _isDark);
}

Future<bool> getBrightness() async {
  final SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();
  final bool isDark = sharedPreferences.getBool('isDark');

  if (isDark != null) {
    return sharedPreferences.getBool('isDark');
  }
  sharedPreferences.setBool('isDark', false);
  return false;
}

void saveFontSize(final int _fontSize) async {
  final SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();
  sharedPreferences.setInt('fontSize', _fontSize);
}

Future<int> getFontSize() async {
  final SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();
  final int fontSize = sharedPreferences.getInt('fontSize');

  if (fontSize != null) {
    return sharedPreferences.getInt('fontSize');
  }
  sharedPreferences.setInt('fontSize', 0);
  return 0;
}
