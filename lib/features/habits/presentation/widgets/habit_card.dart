import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/habits_provider.dart';

class HabitCard extends StatelessWidget {
  final HabitWithStatus habitWithStatus;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const HabitCard({
    super.key,
    required this.habitWithStatus,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final habit = habitWithStatus.habit;
    final isCompleted = habitWithStatus.isCompletedToday;
    final streak = habitWithStatus.streak;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Completion Checkbox
              _CompletionCheckbox(
                isCompleted: isCompleted,
                onToggle: onToggle,
              ),
              const SizedBox(width: 16),

              // Habit Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? Colors.white54 : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _CategoryBadge(category: habit.category),
                        const SizedBox(width: 8),
                        _FrequencyBadge(frequency: habit.frequency),
                      ],
                    ),
                  ],
                ),
              ),

              // Streak Badge
              if (streak > 0) ...[
                const SizedBox(width: 8),
                StreakBadge(streak: streak),
              ],

              // Arrow Icon
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionCheckbox extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback onToggle;

  const _CompletionCheckbox({
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isCompleted ? AppTheme.successColor : Colors.transparent,
          border: Border.all(
            color: isCompleted ? AppTheme.successColor : Colors.white38,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isCompleted
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              )
            : null,
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

class _FrequencyBadge extends StatelessWidget {
  final String frequency;

  const _FrequencyBadge({required this.frequency});

  String get _displayText {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return frequency;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _displayText,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white54,
        ),
      ),
    );
  }
}

class StreakBadge extends StatelessWidget {
  final int streak;
  final bool large;

  const StreakBadge({
    super.key,
    required this.streak,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.warningColor, Colors.orange],
        ),
        borderRadius: BorderRadius.circular(large ? 8 : 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: large ? 20 : 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: TextStyle(
              fontSize: large ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
