import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/habits_repository.dart';
import '../../domain/habit_model.dart';
import '../../domain/completion_model.dart';
import '../../domain/streak_calculator.dart';

// Repository provider
final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  return HabitsRepository();
});

// All habits stream
final habitsProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(habitsRepositoryProvider).getHabits();
});

// Single habit by ID
final habitProvider = FutureProvider.family<Habit?, String>((ref, habitId) {
  return ref.watch(habitsRepositoryProvider).getHabit(habitId);
});

// Today's completions stream
final todayCompletionsProvider = StreamProvider<List<HabitCompletion>>((ref) {
  return ref.watch(habitsRepositoryProvider).getTodayCompletions();
});

// Completions for a specific habit
final habitCompletionsProvider =
    StreamProvider.family<List<HabitCompletion>, String>((ref, habitId) {
  return ref.watch(habitsRepositoryProvider).getCompletions(habitId);
});

// Streak for a specific habit
final habitStreakProvider = Provider.family<int, String>((ref, habitId) {
  final completionsAsync = ref.watch(habitCompletionsProvider(habitId));
  final habitAsync = ref.watch(habitProvider(habitId));

  return completionsAsync.when(
    data: (completions) => habitAsync.when(
      data: (habit) {
        if (habit == null) return 0;
        return StreakCalculator.calculateStreak(completions, habit.frequency);
      },
      loading: () => 0,
      error: (_, __) => 0,
    ),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Habits state notifier for actions
class HabitsNotifier extends StateNotifier<HabitsState> {
  final HabitsRepository _repository;

  HabitsNotifier(this._repository) : super(const HabitsState());

  Future<bool> createHabit({
    required String name,
    String? description,
    required String frequency,
    required String category,
    int? targetCount,
    String? linkedAbilityId,
    int xpReward = 10,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final habit = Habit(
        id: '', // Will be set by Firestore
        name: name,
        description: description,
        frequency: frequency,
        category: category,
        createdAt: DateTime.now(),
        targetCount: targetCount,
        linkedAbilityId: linkedAbilityId,
        xpReward: xpReward,
      );

      await _repository.createHabit(habit);
      state = state.copyWith(isLoading: false);
      return true;
    } on HabitsException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to create habit');
      return false;
    }
  }

  Future<bool> updateHabit(Habit habit) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.updateHabit(habit);
      state = state.copyWith(isLoading: false);
      return true;
    } on HabitsException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update habit');
      return false;
    }
  }

  Future<bool> deleteHabit(String habitId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.deleteHabit(habitId);
      state = state.copyWith(isLoading: false);
      return true;
    } on HabitsException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to delete habit');
      return false;
    }
  }

  Future<bool> toggleCompletion(String habitId, DateTime date) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.toggleCompletion(habitId, date);
      state = state.copyWith(isLoading: false);
      return true;
    } on HabitsException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to toggle completion');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class HabitsState {
  final bool isLoading;
  final String? error;

  const HabitsState({
    this.isLoading = false,
    this.error,
  });

  HabitsState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return HabitsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Habits notifier provider
final habitsNotifierProvider = StateNotifierProvider<HabitsNotifier, HabitsState>((ref) {
  return HabitsNotifier(ref.watch(habitsRepositoryProvider));
});

// Combined habit with today's completion status
class HabitWithStatus {
  final Habit habit;
  final bool isCompletedToday;
  final int streak;

  HabitWithStatus({
    required this.habit,
    required this.isCompletedToday,
    required this.streak,
  });
}

// Provider for habits with their completion status
final habitsWithStatusProvider = Provider<AsyncValue<List<HabitWithStatus>>>((ref) {
  final habitsAsync = ref.watch(habitsProvider);
  final todayCompletionsAsync = ref.watch(todayCompletionsProvider);

  return habitsAsync.when(
    data: (habits) => todayCompletionsAsync.when(
      data: (completions) {
        final completedHabitIds = completions
            .where((c) => c.completed)
            .map((c) => c.habitId)
            .toSet();

        final habitsWithStatus = habits.map((habit) {
          final streak = ref.watch(habitStreakProvider(habit.id));
          return HabitWithStatus(
            habit: habit,
            isCompletedToday: completedHabitIds.contains(habit.id),
            streak: streak,
          );
        }).toList();

        return AsyncValue.data(habitsWithStatus);
      },
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
