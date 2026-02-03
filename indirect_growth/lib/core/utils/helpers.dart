import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class Helpers {
  /// Calculate XP required for a given level
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return (AppConstants.baseXpPerLevel *
            (1 - pow(AppConstants.xpMultiplier, level - 1)) /
            (1 - AppConstants.xpMultiplier))
        .round();
  }

  /// Calculate current level from total XP
  static int levelFromXp(int totalXp) {
    int level = 1;
    while (xpForLevel(level + 1) <= totalXp) {
      level++;
    }
    return level;
  }

  /// Calculate progress to next level (0.0 to 1.0)
  static double progressToNextLevel(int totalXp) {
    int currentLevel = levelFromXp(totalXp);
    int currentLevelXp = xpForLevel(currentLevel);
    int nextLevelXp = xpForLevel(currentLevel + 1);
    int xpInCurrentLevel = totalXp - currentLevelXp;
    int xpNeededForLevel = nextLevelXp - currentLevelXp;
    return xpInCurrentLevel / xpNeededForLevel;
  }

  /// Power function for XP calculation
  static double pow(double base, int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  /// Format date as string for Firestore document IDs
  static String formatDateForId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Parse date string from Firestore document ID
  static DateTime parseDateFromId(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    int daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Show a snackbar with message
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password strength (min 8 chars, 1 uppercase, 1 lowercase, 1 number)
  static bool isValidPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  /// Get greeting based on time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  /// Calculate streak from list of completion dates
  static int calculateStreak(List<DateTime> completionDates, String frequency) {
    if (completionDates.isEmpty) return 0;

    // Sort dates in descending order
    final sortedDates = completionDates
        .map((d) => startOfDay(d))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime checkDate = startOfDay(DateTime.now());

    for (final date in sortedDates) {
      if (frequency == AppConstants.frequencyDaily) {
        if (isSameDay(date, checkDate)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else if (date.isBefore(checkDate)) {
          // Allow one day gap (yesterday not completed but today is)
          if (streak == 0 &&
              checkDate.difference(date).inDays == 1) {
            checkDate = date;
            streak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }
      } else if (frequency == AppConstants.frequencyWeekly) {
        final checkWeekStart = startOfWeek(checkDate);
        final dateWeekStart = startOfWeek(date);
        if (isSameDay(dateWeekStart, checkWeekStart)) {
          streak++;
          checkDate = checkWeekStart.subtract(const Duration(days: 1));
        } else if (dateWeekStart.isBefore(checkWeekStart)) {
          break;
        }
      } else if (frequency == AppConstants.frequencyMonthly) {
        if (date.year == checkDate.year && date.month == checkDate.month) {
          streak++;
          checkDate = DateTime(checkDate.year, checkDate.month, 1)
              .subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    return streak;
  }
}
