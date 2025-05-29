import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Service managing the user's daily activity streak.
///
/// Tracks consecutive days of recorded activities using shared preferences.
class StreakService {
  /// Key for storing the last activity date (YYYY-MM-DD) in SharedPreferences.
  static const _lastDateKey = 'lastActivityDate';

  /// Key for storing the current streak count in SharedPreferences.
  static const _countKey = 'streakCount';

  /// Call this after creating an income or expense.
  static Future<void> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();
    // Initialize SharedPreferences instance.
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    // Format current date as YYYY-MM-DD.
    final lastDate = prefs.getString(_lastDateKey);
    int count = prefs.getInt(_countKey) ?? 0;
    // Retrieve existing streak count or default to 0.

    if (lastDate == today) {
      // Already recorded activity today; no change to streak.
      // already recorded today, do nothing
    } else {
      // Compute yesterday's date string.
      final yesterday = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 1)));
      if (lastDate == yesterday) {
        // Last activity was yesterday; increment streak count.
        count++;
      } else {
        // No recent activity; reset streak count to 1.
        count = 1;
      }
      await prefs.setString(_lastDateKey, today);
      // Save today's date as last activity.
      await prefs.setInt(_countKey, count);
      // Update stored streak count.
    }
  }

  /// Returns true if an activity has been recorded today.
  static Future<bool> isStreakOn() async {
    final prefs = await SharedPreferences.getInstance();
    // Initialize SharedPreferences instance.
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    // Compare stored last activity date to today.
    final lastDate = prefs.getString(_lastDateKey);
    return lastDate == today;
  }

  /// Returns the current streak count (consecutive days).
  static Future<int> getStreakCount() async {
    final prefs = await SharedPreferences.getInstance();
    // Initialize SharedPreferences instance.
    return prefs.getInt(_countKey) ?? 0;
  }
}
