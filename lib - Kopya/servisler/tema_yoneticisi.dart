import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemaYoneticisi extends ChangeNotifier {
  // Singleton yapısı (Her yerden aynı veriye ulaşmak için)
  static final TemaYoneticisi _instance = TemaYoneticisi._internal();
  factory TemaYoneticisi() => _instance;
  TemaYoneticisi._internal();

  ThemeMode _themeMode = ThemeMode.light; // Varsayılan açık tema
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Uygulama açılınca hafızadan son seçimi okur
  Future<void> temayiYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode');
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners(); // Arayüzü güncelle
    }
  }

  // Temayı değiştirir ve kaydeder
  Future<void> temayiDegistir(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Tüm uygulamaya haber ver
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }
}