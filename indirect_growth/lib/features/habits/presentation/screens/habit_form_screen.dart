import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/utils/helpers.dart';
import '../../domain/habit_model.dart';
import '../providers/habits_provider.dart';

class HabitFormScreen extends ConsumerStatefulWidget {
  final String? habitId;

  const HabitFormScreen({super.key, this.habitId});

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _frequency = AppConstants.frequencyDaily;
  String _category = AppConstants.habitCategories.first;
  bool _isLoading = false;
  Habit? _existingHabit;

  bool get isEditing => widget.habitId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadHabit();
    }
  }

  Future<void> _loadHabit() async {
    setState(() => _isLoading = true);
    final habit = await ref.read(habitsRepositoryProvider).getHabit(widget.habitId!);
    if (habit != null && mounted) {
      setState(() {
        _existingHabit = habit;
        _nameController.text = habit.name;
        _descriptionController.text = habit.description ?? '';
        _frequency = habit.frequency;
        _category = habit.category;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final notifier = ref.read(habitsNotifierProvider.notifier);
    bool success;

    if (isEditing && _existingHabit != null) {
      final updatedHabit = _existingHabit!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        frequency: _frequency,
        category: _category,
      );
      success = await notifier.updateHabit(updatedHabit);
    } else {
      success = await notifier.createHabit(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        frequency: _frequency,
        category: _category,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Helpers.showSnackBar(
        context,
        isEditing ? 'Habit updated successfully' : 'Habit created successfully',
      );
      context.pop();
    } else if (mounted) {
      final error = ref.read(habitsNotifierProvider).error;
      Helpers.showSnackBar(
        context,
        error ?? 'Something went wrong',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Habit' : 'New Habit'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: _isLoading && isEditing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name Field
                    CustomTextField(
                      controller: _nameController,
                      label: 'Habit Name',
                      hint: 'e.g., Morning meditation',
                      prefixIcon: Icons.edit,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a habit name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Description (optional)',
                      hint: 'Add details about your habit',
                      prefixIcon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Frequency Selection
                    Text(
                      'Frequency',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _FrequencySelector(
                      selectedFrequency: _frequency,
                      onChanged: (value) => setState(() => _frequency = value),
                    ),
                    const SizedBox(height: 24),

                    // Category Selection
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _CategorySelector(
                      selectedCategory: _category,
                      onChanged: (value) => setState(() => _category = value),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    CustomButton(
                      text: isEditing ? 'Update Habit' : 'Create Habit',
                      onPressed: _handleSubmit,
                      isLoading: _isLoading,
                      icon: isEditing ? Icons.save : Icons.add,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: const Text(
          'Are you sure you want to delete this habit? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _isLoading = true);

              final success = await ref
                  .read(habitsNotifierProvider.notifier)
                  .deleteHabit(widget.habitId!);

              setState(() => _isLoading = false);

              if (success && mounted) {
                Helpers.showSnackBar(context, 'Habit deleted');
                context.pop();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  final String selectedFrequency;
  final ValueChanged<String> onChanged;

  const _FrequencySelector({
    required this.selectedFrequency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FrequencyOption(
          label: 'Daily',
          value: AppConstants.frequencyDaily,
          icon: Icons.today,
          isSelected: selectedFrequency == AppConstants.frequencyDaily,
          onTap: () => onChanged(AppConstants.frequencyDaily),
        ),
        const SizedBox(width: 12),
        _FrequencyOption(
          label: 'Weekly',
          value: AppConstants.frequencyWeekly,
          icon: Icons.view_week,
          isSelected: selectedFrequency == AppConstants.frequencyWeekly,
          onTap: () => onChanged(AppConstants.frequencyWeekly),
        ),
        const SizedBox(width: 12),
        _FrequencyOption(
          label: 'Monthly',
          value: AppConstants.frequencyMonthly,
          icon: Icons.calendar_month,
          isSelected: selectedFrequency == AppConstants.frequencyMonthly,
          onTap: () => onChanged(AppConstants.frequencyMonthly),
        ),
      ],
    );
  }
}

class _FrequencyOption extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyOption({
    required this.label,
    required this.value,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white24,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white54,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onChanged;

  const _CategorySelector({
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.habitCategories.map((category) {
        final isSelected = category == selectedCategory;
        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (_) => onChanged(category),
          selectedColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
          ),
        );
      }).toList(),
    );
  }
}
