// lib/services/streak_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StreakService {
  /// Lee la racha, la incrementa si es día nuevo y la devuelve.
  static Future<int> updateAndGetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = prefs.getString('lastStreakDate');
    int streak = prefs.getInt('streakCount') ?? 0;
    if (lastDate != today) {
      streak++;
      await prefs.setInt('streakCount', streak);
      await prefs.setString('lastStreakDate', today);
    }
    return streak;
  }
}