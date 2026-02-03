import 'package:cloud_firestore/cloud_firestore.dart';

class HabitCompletion {
  final String id; // Format: {date}_{habitId}
  final String habitId;
  final DateTime date;
  final bool completed;
  final int? count; // For habits with targetCount
  final String? notes;
  final DateTime? completedAt;

  HabitCompletion({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
    this.count,
    this.notes,
    this.completedAt,
  });

  factory HabitCompletion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HabitCompletion(
      id: doc.id,
      habitId: data['habitId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completed: data['completed'] ?? false,
      count: data['count'],
      notes: data['notes'],
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'habitId': habitId,
      'date': Timestamp.fromDate(date),
      'completed': completed,
      'count': count,
      'notes': notes,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  HabitCompletion copyWith({
    String? id,
    String? habitId,
    DateTime? date,
    bool? completed,
    int? count,
    String? notes,
    DateTime? completedAt,
  }) {
    return HabitCompletion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      count: count ?? this.count,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Generate document ID for a completion
  static String generateId(String habitId, DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${dateStr}_$habitId';
  }
}
