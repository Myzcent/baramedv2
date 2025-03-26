import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeProvider extends ChangeNotifier {
  double _fontSize = 16.0;

  double get fontSize => _fontSize;

  FontSizeProvider() {
    _loadFontSize();
  }

  void setFontSize(double newSize) {
    _fontSize = newSize;
    _saveFontSize(newSize);
    notifyListeners(); // Para mag-update agad ang UI
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    notifyListeners();
  }

  Future<void> _saveFontSize(double newSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', newSize);
  }
}
