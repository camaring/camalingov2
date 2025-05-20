import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StreakService {
  static const _lastDateKey = 'lastActivityDate';
  static const _countKey = 'streakCount';

  /// Call this after creating an income or expense.
  /// Updates the streak count: increments if yesterday had activity, resets to 1 otherwise.
  static Future<void> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = prefs.getString(_lastDateKey);
    int count = prefs.getInt(_countKey) ?? 0;

    if (lastDate == today) {
      // already recorded today, do nothing
    } else {
      // check if yesterday
      final yesterday = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 1)));
      if (lastDate == yesterday) {
        count++;
      } else {
        count = 1;
      }
      await prefs.setString(_lastDateKey, today);
      await prefs.setInt(_countKey, count);
    }
  }

  /// Returns true if the user has recorded an activity today.
  static Future<bool> isStreakOn() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = prefs.getString(_lastDateKey);
    return lastDate == today;
  }

  /// Returns the current streak count (number of consecutive days).
  static Future<int> getStreakCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_countKey) ?? 0;
  }
}
