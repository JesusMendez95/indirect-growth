import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String id;
  final String name;
  final String? description;
  final String frequency; // 'daily', 'weekly', 'monthly'
  final String category;
  final DateTime createdAt;
  final bool isActive;
  final int? targetCount; // For habits with specific counts (e.g., "drink 8 glasses of water")
  final String? linkedAbilityId; // Link to progression system
  final int xpReward; // XP gained on completion

  Habit({
    required this.id,
    required this.name,
    this.description,
    required this.frequency,
    required this.category,
    required this.createdAt,
    this.isActive = true,
    this.targetCount,
    this.linkedAbilityId,
    this.xpReward = 10,
  });

  factory Habit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Habit(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      frequency: data['frequency'] ?? 'daily',
      category: data['category'] ?? 'Other',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      targetCount: data['targetCount'],
      linkedAbilityId: data['linkedAbilityId'],
      xpReward: data['xpReward'] ?? 10,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'frequency': frequency,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'targetCount': targetCount,
      'linkedAbilityId': linkedAbilityId,
      'xpReward': xpReward,
    };
  }

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    String? frequency,
    String? category,
    DateTime? createdAt,
    bool? isActive,
    int? targetCount,
    String? linkedAbilityId,
    int? xpReward,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      targetCount: targetCount ?? this.targetCount,
      linkedAbilityId: linkedAbilityId ?? this.linkedAbilityId,
      xpReward: xpReward ?? this.xpReward,
    );
  }
}
