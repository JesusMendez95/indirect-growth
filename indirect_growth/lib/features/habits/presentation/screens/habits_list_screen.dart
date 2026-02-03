import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/utils/helpers.dart';
import '../providers/habits_provider.dart';
import '../widgets/habit_card.dart';

class HabitsListScreen extends ConsumerWidget {
  const HabitsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsWithStatusAsync = ref.watch(habitsWithStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Habits'),
            Text(
              Helpers.getGreeting(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
            ),
          ],
        ),
      ),
      body: habitsWithStatusAsync.when(
        data: (habitsWithStatus) {
          if (habitsWithStatus.isEmpty) {
            return _EmptyState(
              onAddHabit: () => context.push('/habits/create'),
            );
          }

          // Group habits by category
          final groupedHabits = <String, List<HabitWithStatus>>{};
          for (final h in habitsWithStatus) {
            groupedHabits.putIfAbsent(h.habit.category, () => []).add(h);
          }

          // Calculate completion stats
          final totalHabits = habitsWithStatus.length;
          final completedHabits =
              habitsWithStatus.where((h) => h.isCompletedToday).length;
          final completionRate = totalHabits > 0
              ? (completedHabits / totalHabits * 100).round()
              : 0;

          return Column(
            children: [
              // Daily Progress Header
              _DailyProgressHeader(
                completed: completedHabits,
                total: totalHabits,
                percentage: completionRate,
              ),

              // Habits List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedHabits.length,
                  itemBuilder: (context, index) {
                    final category = groupedHabits.keys.elementAt(index);
                    final habits = groupedHabits[category]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (index > 0) const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            category,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.white54,
                                ),
                          ),
                        ),
                        ...habits.map((habitWithStatus) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: HabitCard(
                                habitWithStatus: habitWithStatus,
                                onToggle: () => _toggleCompletion(
                                  context,
                                  ref,
                                  habitWithStatus.habit.id,
                                ),
                                onTap: () => context.push(
                                  '/habits/${habitWithStatus.habit.id}',
                                ),
                              ),
                            )),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(habitsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/habits/create'),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('New Habit'),
      ),
    );
  }

  void _toggleCompletion(BuildContext context, WidgetRef ref, String habitId) {
    ref.read(habitsNotifierProvider.notifier).toggleCompletion(
          habitId,
          DateTime.now(),
        );
  }
}

class _DailyProgressHeader extends StatelessWidget {
  final int completed;
  final int total;
  final int percentage;

  const _DailyProgressHeader({
    required this.completed,
    required this.total,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.8),
            AppTheme.secondaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Progress",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completed of $total habits',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? completed / total : 0,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddHabit;

  const _EmptyState({required this.onAddHabit});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No habits yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Start building your daily routine by adding your first habit.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAddHabit,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Habit'),
            ),
          ],
        ),
      ),
    );
  }
}
