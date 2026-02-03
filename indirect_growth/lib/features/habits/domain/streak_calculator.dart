import '../../../core/constants/app_constants.dart';
import '../../../core/utils/helpers.dart';
import 'completion_model.dart';

class StreakCalculator {
  /// Calculate the current streak for a habit based on completions
  static int calculateStreak(
    List<HabitCompletion> completions,
    String frequency,
  ) {
    if (completions.isEmpty) return 0;

    // Filter to only completed entries
    final completedEntries = completions
        .where((c) => c.completed)
        .map((c) => Helpers.startOfDay(c.date))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending

    if (completedEntries.isEmpty) return 0;

    final today = Helpers.startOfDay(DateTime.now());
    int streak = 0;

    switch (frequency) {
      case AppConstants.frequencyDaily:
        streak = _calculateDailyStreak(completedEntries, today);
        break;
      case AppConstants.frequencyWeekly:
        streak = _calculateWeeklyStreak(completedEntries, today);
        break;
      case AppConstants.frequencyMonthly:
        streak = _calculateMonthlyStreak(completedEntries, today);
        break;
    }

    return streak;
  }

  static int _calculateDailyStreak(List<DateTime> dates, DateTime today) {
    if (dates.isEmpty) return 0;

    // Check if today or yesterday is in the list
    final yesterday = today.subtract(const Duration(days: 1));
    DateTime checkDate;

    if (dates.contains(today)) {
      checkDate = today;
    } else if (dates.contains(yesterday)) {
      checkDate = yesterday;
    } else {
      return 0;
    }

    int streak = 0;
    for (final date in dates) {
      if (Helpers.isSameDay(date, checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (date.isBefore(checkDate)) {
        break;
      }
    }

    return streak;
  }

  static int _calculateWeeklyStreak(List<DateTime> dates, DateTime today) {
    if (dates.isEmpty) return 0;

    final thisWeekStart = Helpers.startOfWeek(today);
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    // Check if this week or last week has a completion
    bool hasThisWeek = dates.any((d) =>
        !d.isBefore(thisWeekStart) && d.isBefore(thisWeekStart.add(const Duration(days: 7))));
    bool hasLastWeek = dates.any((d) =>
        !d.isBefore(lastWeekStart) && d.isBefore(thisWeekStart));

    DateTime checkWeekStart;
    if (hasThisWeek) {
      checkWeekStart = thisWeekStart;
    } else if (hasLastWeek) {
      checkWeekStart = lastWeekStart;
    } else {
      return 0;
    }

    int streak = 0;
    while (true) {
      final weekEnd = checkWeekStart.add(const Duration(days: 7));
      bool hasCompletion = dates.any((d) =>
          !d.isBefore(checkWeekStart) && d.isBefore(weekEnd));

      if (hasCompletion) {
        streak++;
        checkWeekStart = checkWeekStart.subtract(const Duration(days: 7));
      } else {
        break;
      }
    }

    return streak;
  }

  static int _calculateMonthlyStreak(List<DateTime> dates, DateTime today) {
    if (dates.isEmpty) return 0;

    final thisMonthStart = Helpers.startOfMonth(today);
    final lastMonthStart = DateTime(
      thisMonthStart.month == 1 ? thisMonthStart.year - 1 : thisMonthStart.year,
      thisMonthStart.month == 1 ? 12 : thisMonthStart.month - 1,
      1,
    );

    // Check if this month or last month has a completion
    bool hasThisMonth = dates.any((d) =>
        d.year == thisMonthStart.year && d.month == thisMonthStart.month);
    bool hasLastMonth = dates.any((d) =>
        d.year == lastMonthStart.year && d.month == lastMonthStart.month);

    int checkYear;
    int checkMonth;
    if (hasThisMonth) {
      checkYear = thisMonthStart.year;
      checkMonth = thisMonthStart.month;
    } else if (hasLastMonth) {
      checkYear = lastMonthStart.year;
      checkMonth = lastMonthStart.month;
    } else {
      return 0;
    }

    int streak = 0;
    while (true) {
      bool hasCompletion = dates.any((d) =>
          d.year == checkYear && d.month == checkMonth);

      if (hasCompletion) {
        streak++;
        checkMonth--;
        if (checkMonth < 1) {
          checkMonth = 12;
          checkYear--;
        }
      } else {
        break;
      }
    }

    return streak;
  }

  /// Calculate longest streak ever achieved
  static int calculateLongestStreak(
    List<HabitCompletion> completions,
    String frequency,
  ) {
    if (completions.isEmpty) return 0;

    final completedDates = completions
        .where((c) => c.completed)
        .map((c) => Helpers.startOfDay(c.date))
        .toSet()
        .toList()
      ..sort();

    if (completedDates.isEmpty) return 0;

    int longestStreak = 0;
    int currentStreak = 0;
    DateTime? previousDate;

    for (final date in completedDates) {
      if (previousDate == null) {
        currentStreak = 1;
      } else {
        bool isConsecutive = false;

        switch (frequency) {
          case AppConstants.frequencyDaily:
            isConsecutive = date.difference(previousDate).inDays == 1;
            break;
          case AppConstants.frequencyWeekly:
            final prevWeekStart = Helpers.startOfWeek(previousDate);
            final currWeekStart = Helpers.startOfWeek(date);
            isConsecutive = currWeekStart.difference(prevWeekStart).inDays == 7;
            break;
          case AppConstants.frequencyMonthly:
            isConsecutive = (date.year == previousDate.year &&
                    date.month == previousDate.month + 1) ||
                (date.year == previousDate.year + 1 &&
                    date.month == 1 &&
                    previousDate.month == 12);
            break;
        }

        if (isConsecutive) {
          currentStreak++;
        } else {
          currentStreak = 1;
        }
      }

      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }

      previousDate = date;
    }

    return longestStreak;
  }

  /// Calculate completion rate for a given period
  static double calculateCompletionRate(
    List<HabitCompletion> completions,
    String frequency,
    DateTime startDate,
    DateTime endDate,
  ) {
    int totalPeriods = 0;
    int completedPeriods = 0;

    switch (frequency) {
      case AppConstants.frequencyDaily:
        totalPeriods = endDate.difference(startDate).inDays + 1;
        completedPeriods = completions
            .where((c) =>
                c.completed &&
                !c.date.isBefore(startDate) &&
                !c.date.isAfter(endDate))
            .map((c) => Helpers.startOfDay(c.date))
            .toSet()
            .length;
        break;

      case AppConstants.frequencyWeekly:
        DateTime weekStart = Helpers.startOfWeek(startDate);
        while (!weekStart.isAfter(endDate)) {
          totalPeriods++;
          final weekEnd = weekStart.add(const Duration(days: 7));
          bool hasCompletion = completions.any((c) =>
              c.completed &&
              !c.date.isBefore(weekStart) &&
              c.date.isBefore(weekEnd));
          if (hasCompletion) completedPeriods++;
          weekStart = weekEnd;
        }
        break;

      case AppConstants.frequencyMonthly:
        DateTime monthStart = Helpers.startOfMonth(startDate);
        while (!monthStart.isAfter(endDate)) {
          totalPeriods++;
          bool hasCompletion = completions.any((c) =>
              c.completed &&
              c.date.year == monthStart.year &&
              c.date.month == monthStart.month);
          if (hasCompletion) completedPeriods++;
          monthStart = DateTime(
            monthStart.month == 12 ? monthStart.year + 1 : monthStart.year,
            monthStart.month == 12 ? 1 : monthStart.month + 1,
            1,
          );
        }
        break;
    }

    if (totalPeriods == 0) return 0.0;
    return completedPeriods / totalPeriods;
  }
}
