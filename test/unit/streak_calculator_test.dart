import 'package:flutter_test/flutter_test.dart';
import 'package:indirect_growth/features/habits/domain/completion_model.dart';
import 'package:indirect_growth/features/habits/domain/streak_calculator.dart';
import 'package:indirect_growth/core/constants/app_constants.dart';

void main() {
  group('StreakCalculator', () {
    group('Daily Streaks', () {
      test('returns 0 for empty completions', () {
        final streak = StreakCalculator.calculateStreak(
          [],
          AppConstants.frequencyDaily,
        );
        expect(streak, 0);
      });

      test('returns 1 for single completion today', () {
        final today = DateTime.now();
        final completions = [
          _createCompletion('1', today, true),
        ];

        final streak = StreakCalculator.calculateStreak(
          completions,
          AppConstants.frequencyDaily,
        );
        expect(streak, 1);
      });

      test('returns correct streak for consecutive days', () {
        final today = DateTime.now();
        final completions = [
          _createCompletion('1', today, true),
          _createCompletion('1', today.subtract(const Duration(days: 1)), true),
          _createCompletion('1', today.subtract(const Duration(days: 2)), true),
        ];

        final streak = StreakCalculator.calculateStreak(
          completions,
          AppConstants.frequencyDaily,
        );
        expect(streak, 3);
      });

      test('streak breaks on missed day', () {
        final today = DateTime.now();
        final completions = [
          _createCompletion('1', today, true),
          _createCompletion('1', today.subtract(const Duration(days: 1)), true),
          // Day 2 missed
          _createCompletion('1', today.subtract(const Duration(days: 3)), true),
        ];

        final streak = StreakCalculator.calculateStreak(
          completions,
          AppConstants.frequencyDaily,
        );
        expect(streak, 2);
      });

      test('returns streak starting from yesterday if today not completed', () {
        final today = DateTime.now();
        final completions = [
          _createCompletion('1', today.subtract(const Duration(days: 1)), true),
          _createCompletion('1', today.subtract(const Duration(days: 2)), true),
          _createCompletion('1', today.subtract(const Duration(days: 3)), true),
        ];

        final streak = StreakCalculator.calculateStreak(
          completions,
          AppConstants.frequencyDaily,
        );
        expect(streak, 3);
      });

      test('returns 0 if last completion was more than 1 day ago', () {
        final today = DateTime.now();
        final completions = [
          _createCompletion('1', today.subtract(const Duration(days: 2)), true),
          _createCompletion('1', today.subtract(const Duration(days: 3)), true),
        ];

        final streak = StreakCalculator.calculateStreak(
          completions,
          AppConstants.frequencyDaily,
        );
        expect(streak, 0);
      });

      test('ignores incomplete entries', () {
        final today = DateTime.now();
        final completions = [
          _createCompletion('1', today, true),
          _createCompletion('1', today.subtract(const Duration(days: 1)), false),
          _createCompletion('1', today.subtract(const Duration(days: 2)), true),
        ];

        final streak = StreakCalculator.calculateStreak(
          completions,
          AppConstants.frequencyDaily,
        );
        expect(streak, 1);
      });
    });

    group('Weekly Streaks', () {
      test('returns 0 for empty completions', () {
        final streak = StreakCalculator.calculateStreak(
          [],
          AppConstants.frequencyWeekly,
        );
        expect(streak, 0);
      });

      test('returns 1 for completion this week', () {
        final today = DateTime.now();
        final completions = [
          _createCompletion('1', today, true),
        ];

        final streak = StreakCalculator.calculateStreak(
          completions,
          AppConstants.frequencyWeekly,
        );
        expect(streak, 1);
      });

      test('returns correct streak for consecutive weeks', () {
        final today = DateTime.now();
        final completions = [
          _createCompletion('1', today, true),
          _createCompletion('1', today.subtract(const Duration(days: 7)), true),
          _createCompletion('1', today.subtract(const Duration(days: 14)), true),
        ];

        final streak = StreakCalculator.calculateStreak(
          completions,
          AppConstants.frequencyWeekly,
        );
        expect(streak, 3);
      });
    });

    group('Monthly Streaks', () {
      test('returns 0 for empty completions', () {
        final streak = StreakCalculator.calculateStreak(
          [],
          AppConstants.frequencyMonthly,
        );
        expect(streak, 0);
      });

      test('returns 1 for completion this month', () {
        final today = DateTime.now();
        final completions = [
          _createCompletion('1', today, true),
        ];

        final streak = StreakCalculator.calculateStreak(
          completions,
          AppConstants.frequencyMonthly,
        );
        expect(streak, 1);
      });
    });

    group('Longest Streak', () {
      test('returns 0 for empty completions', () {
        final longestStreak = StreakCalculator.calculateLongestStreak(
          [],
          AppConstants.frequencyDaily,
        );
        expect(longestStreak, 0);
      });

      test('returns correct longest streak', () {
        final today = DateTime.now();
        final completions = [
          // Current streak of 2
          _createCompletion('1', today, true),
          _createCompletion('1', today.subtract(const Duration(days: 1)), true),
          // Gap
          // Old streak of 5
          _createCompletion('1', today.subtract(const Duration(days: 10)), true),
          _createCompletion('1', today.subtract(const Duration(days: 11)), true),
          _createCompletion('1', today.subtract(const Duration(days: 12)), true),
          _createCompletion('1', today.subtract(const Duration(days: 13)), true),
          _createCompletion('1', today.subtract(const Duration(days: 14)), true),
        ];

        final longestStreak = StreakCalculator.calculateLongestStreak(
          completions,
          AppConstants.frequencyDaily,
        );
        expect(longestStreak, 5);
      });
    });

    group('Completion Rate', () {
      test('returns 0 for empty completions', () {
        final startDate = DateTime.now().subtract(const Duration(days: 7));
        final endDate = DateTime.now();

        final rate = StreakCalculator.calculateCompletionRate(
          [],
          AppConstants.frequencyDaily,
          startDate,
          endDate,
        );
        expect(rate, 0.0);
      });

      test('returns correct rate for daily habit', () {
        final today = DateTime.now();
        final startDate = DateTime(today.year, today.month, today.day - 6);
        final endDate = today;

        // 4 completions out of 7 days
        final completions = [
          _createCompletion('1', today, true),
          _createCompletion('1', today.subtract(const Duration(days: 1)), true),
          _createCompletion('1', today.subtract(const Duration(days: 3)), true),
          _createCompletion('1', today.subtract(const Duration(days: 5)), true),
        ];

        final rate = StreakCalculator.calculateCompletionRate(
          completions,
          AppConstants.frequencyDaily,
          startDate,
          endDate,
        );

        // 4 out of 7 = ~0.571
        expect(rate, closeTo(4 / 7, 0.01));
      });

      test('returns 1.0 for 100% completion', () {
        final today = DateTime.now();
        final startDate = DateTime(today.year, today.month, today.day - 2);
        final endDate = today;

        final completions = [
          _createCompletion('1', today, true),
          _createCompletion('1', today.subtract(const Duration(days: 1)), true),
          _createCompletion('1', today.subtract(const Duration(days: 2)), true),
        ];

        final rate = StreakCalculator.calculateCompletionRate(
          completions,
          AppConstants.frequencyDaily,
          startDate,
          endDate,
        );
        expect(rate, 1.0);
      });
    });
  });
}

HabitCompletion _createCompletion(String habitId, DateTime date, bool completed) {
  return HabitCompletion(
    id: HabitCompletion.generateId(habitId, date),
    habitId: habitId,
    date: date,
    completed: completed,
  );
}
