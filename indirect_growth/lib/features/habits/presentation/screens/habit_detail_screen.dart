import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/streak_calculator.dart';
import '../providers/habits_provider.dart';
import '../widgets/habit_card.dart';

class HabitDetailScreen extends ConsumerWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitAsync = ref.watch(habitProvider(habitId));
    final completionsAsync = ref.watch(habitCompletionsProvider(habitId));
    final streak = ref.watch(habitStreakProvider(habitId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/habits/$habitId/edit'),
          ),
        ],
      ),
      body: habitAsync.when(
        data: (habit) {
          if (habit == null) {
            return const Center(child: Text('Habit not found'));
          }

          return completionsAsync.when(
            data: (completions) {
              final longestStreak = StreakCalculator.calculateLongestStreak(
                completions,
                habit.frequency,
              );

              final completionRate = StreakCalculator.calculateCompletionRate(
                completions,
                habit.frequency,
                habit.createdAt,
                DateTime.now(),
              );

              final totalCompletions =
                  completions.where((c) => c.completed).length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    _HabitHeaderCard(
                      name: habit.name,
                      description: habit.description,
                      category: habit.category,
                      frequency: habit.frequency,
                      streak: streak,
                    ),
                    const SizedBox(height: 24),

                    // Stats Grid
                    _StatsGrid(
                      currentStreak: streak,
                      longestStreak: longestStreak,
                      completionRate: completionRate,
                      totalCompletions: totalCompletions,
                    ),
                    const SizedBox(height: 24),

                    // Recent Activity
                    Text(
                      'Recent Activity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _RecentActivityCalendar(
                      completions: completions,
                      frequency: habit.frequency,
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _QuickActions(
                      onToggleToday: () {
                        ref
                            .read(habitsNotifierProvider.notifier)
                            .toggleCompletion(habitId, DateTime.now());
                      },
                      isCompletedToday: completions.any((c) =>
                          c.completed &&
                          _isSameDay(c.date, DateTime.now())),
                    ),
                  ],
                ),
              );
            },
            loading: () => const LoadingIndicator(),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _HabitHeaderCard extends StatelessWidget {
  final String name;
  final String? description;
  final String category;
  final String frequency;
  final int streak;

  const _HabitHeaderCard({
    required this.name,
    this.description,
    required this.category,
    required this.frequency,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                if (streak > 0) StreakBadge(streak: streak, large: true),
              ],
            ),
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.category,
                  label: category,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.repeat,
                  label: frequency[0].toUpperCase() + frequency.substring(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final double completionRate;
  final int totalCompletions;

  const _StatsGrid({
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
    required this.totalCompletions,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Current Streak',
          value: '$currentStreak',
          icon: Icons.local_fire_department,
          iconColor: AppTheme.warningColor,
        ),
        _StatCard(
          title: 'Best Streak',
          value: '$longestStreak',
          icon: Icons.emoji_events,
          iconColor: AppTheme.accentColor,
        ),
        _StatCard(
          title: 'Completion Rate',
          value: '${(completionRate * 100).round()}%',
          icon: Icons.pie_chart,
          iconColor: AppTheme.successColor,
        ),
        _StatCard(
          title: 'Total Completions',
          value: '$totalCompletions',
          icon: Icons.check_circle,
          iconColor: AppTheme.primaryColor,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityCalendar extends StatelessWidget {
  final List completions;
  final String frequency;

  const _RecentActivityCalendar({
    required this.completions,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(28, (i) {
      return DateTime(today.year, today.month, today.day - (27 - i));
    });

    final completedDays = completions
        .where((c) => c.completed)
        .map((c) => DateTime(c.date.year, c.date.month, c.date.day))
        .toSet();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last 4 Weeks',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: 28,
              itemBuilder: (context, index) {
                final date = days[index];
                final isCompleted = completedDays.contains(date);
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;

                return Container(
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.successColor
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                    border: isToday
                        ? Border.all(color: AppTheme.primaryColor, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isCompleted ? Colors.white : Colors.white38,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onToggleToday;
  final bool isCompletedToday;

  const _QuickActions({
    required this.onToggleToday,
    required this.isCompletedToday,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onToggleToday,
                icon: Icon(
                  isCompletedToday
                      ? Icons.close
                      : Icons.check,
                ),
                label: Text(
                  isCompletedToday
                      ? 'Mark Incomplete'
                      : 'Complete Today',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompletedToday
                      ? Colors.grey
                      : AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
