import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/helpers.dart';
import '../domain/habit_model.dart';
import '../domain/completion_model.dart';

class HabitsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _habitsCollection =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(_userId)
          .collection(AppConstants.habitsCollection);

  CollectionReference<Map<String, dynamic>> get _completionsCollection =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(_userId)
          .collection(AppConstants.completionsCollection);

  // Create a new habit
  Future<Habit> createHabit(Habit habit) async {
    if (_userId == null) throw HabitsException('User not authenticated');

    try {
      final docRef = await _habitsCollection.add(habit.toFirestore());
      return habit.copyWith(id: docRef.id);
    } catch (e) {
      throw HabitsException('Failed to create habit');
    }
  }

  // Get all habits for current user
  Stream<List<Habit>> getHabits({bool activeOnly = true}) {
    if (_userId == null) return Stream.value([]);

    Query<Map<String, dynamic>> query = _habitsCollection;
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Habit.fromFirestore(doc)).toList(),
        );
  }

  // Get a single habit by ID
  Future<Habit?> getHabit(String habitId) async {
    if (_userId == null) return null;

    try {
      final doc = await _habitsCollection.doc(habitId).get();
      if (doc.exists) {
        return Habit.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw HabitsException('Failed to get habit');
    }
  }

  // Update a habit
  Future<void> updateHabit(Habit habit) async {
    if (_userId == null) throw HabitsException('User not authenticated');

    try {
      await _habitsCollection.doc(habit.id).update(habit.toFirestore());
    } catch (e) {
      throw HabitsException('Failed to update habit');
    }
  }

  // Delete a habit (soft delete - sets isActive to false)
  Future<void> deleteHabit(String habitId, {bool hardDelete = false}) async {
    if (_userId == null) throw HabitsException('User not authenticated');

    try {
      if (hardDelete) {
        await _habitsCollection.doc(habitId).delete();
        // Also delete all completions for this habit
        final completions = await _completionsCollection
            .where('habitId', isEqualTo: habitId)
            .get();
        for (final doc in completions.docs) {
          await doc.reference.delete();
        }
      } else {
        await _habitsCollection.doc(habitId).update({'isActive': false});
      }
    } catch (e) {
      throw HabitsException('Failed to delete habit');
    }
  }

  // Toggle habit completion for a specific date
  Future<HabitCompletion> toggleCompletion(
    String habitId,
    DateTime date, {
    String? notes,
    int? count,
  }) async {
    if (_userId == null) throw HabitsException('User not authenticated');

    try {
      final normalizedDate = Helpers.startOfDay(date);
      final completionId = HabitCompletion.generateId(habitId, normalizedDate);
      final docRef = _completionsCollection.doc(completionId);

      final existingDoc = await docRef.get();

      if (existingDoc.exists) {
        final existing = HabitCompletion.fromFirestore(existingDoc);
        final updated = existing.copyWith(
          completed: !existing.completed,
          completedAt: !existing.completed ? DateTime.now() : null,
          notes: notes,
          count: count,
        );
        await docRef.update(updated.toFirestore());
        return updated;
      } else {
        final newCompletion = HabitCompletion(
          id: completionId,
          habitId: habitId,
          date: normalizedDate,
          completed: true,
          completedAt: DateTime.now(),
          notes: notes,
          count: count,
        );
        await docRef.set(newCompletion.toFirestore());
        return newCompletion;
      }
    } catch (e) {
      throw HabitsException('Failed to toggle completion');
    }
  }

  // Get completions for a habit
  Stream<List<HabitCompletion>> getCompletions(String habitId) {
    if (_userId == null) return Stream.value([]);

    return _completionsCollection
        .where('habitId', isEqualTo: habitId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => HabitCompletion.fromFirestore(doc)).toList());
  }

  // Get completions for a date range
  Stream<List<HabitCompletion>> getCompletionsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    if (_userId == null) return Stream.value([]);

    return _completionsCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => HabitCompletion.fromFirestore(doc)).toList());
  }

  // Get today's completions
  Stream<List<HabitCompletion>> getTodayCompletions() {
    final today = Helpers.startOfDay(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    return getCompletionsForDateRange(today, tomorrow);
  }

  // Check if habit is completed for a specific date
  Future<bool> isHabitCompletedForDate(String habitId, DateTime date) async {
    if (_userId == null) return false;

    try {
      final normalizedDate = Helpers.startOfDay(date);
      final completionId = HabitCompletion.generateId(habitId, normalizedDate);
      final doc = await _completionsCollection.doc(completionId).get();

      if (doc.exists) {
        final completion = HabitCompletion.fromFirestore(doc);
        return completion.completed;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get habits by category
  Stream<List<Habit>> getHabitsByCategory(String category) {
    if (_userId == null) return Stream.value([]);

    return _habitsCollection
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Habit.fromFirestore(doc)).toList());
  }
}

class HabitsException implements Exception {
  final String message;
  HabitsException(this.message);

  @override
  String toString() => message;
}
