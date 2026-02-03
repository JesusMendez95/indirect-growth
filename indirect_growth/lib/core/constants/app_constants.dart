class AppConstants {
  // App Info
  static const String appName = 'Indirect Growth';
  static const String appVersion = '1.0.0';

  // Habit Frequencies
  static const String frequencyDaily = 'daily';
  static const String frequencyWeekly = 'weekly';
  static const String frequencyMonthly = 'monthly';

  // Habit Categories
  static const List<String> habitCategories = [
    'Health',
    'Fitness',
    'Learning',
    'Productivity',
    'Mindfulness',
    'Social',
    'Creative',
    'Financial',
    'Other',
  ];

  // Ability Categories (RPG-style)
  static const Map<String, List<String>> abilityCategories = {
    'Physical': ['Strength', 'Endurance', 'Flexibility', 'Speed', 'Coordination'],
    'Mental': ['Focus', 'Memory', 'Creativity', 'Problem Solving', 'Learning'],
    'Social': ['Communication', 'Empathy', 'Leadership', 'Networking', 'Charisma'],
    'Emotional': ['Self-Awareness', 'Resilience', 'Patience', 'Courage', 'Gratitude'],
    'Spiritual': ['Mindfulness', 'Purpose', 'Compassion', 'Wisdom', 'Inner Peace'],
  };

  // XP and Leveling
  static const int baseXpPerLevel = 100;
  static const double xpMultiplier = 1.5;

  // Mood Options
  static const List<String> moodOptions = [
    'Energetic',
    'Happy',
    'Calm',
    'Neutral',
    'Tired',
    'Anxious',
    'Sad',
    'Frustrated',
  ];

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String habitsCollection = 'habits';
  static const String completionsCollection = 'completions';
  static const String diaryEntriesCollection = 'diaryEntries';
  static const String abilitiesCollection = 'abilities';
  static const String identityCollection = 'identity';
  static const String beliefsCollection = 'beliefs';
  static const String valuesCollection = 'values';
  static const String virtuesCollection = 'virtues';
  static const String shadowCollection = 'shadow';
  static const String relationshipsCollection = 'relationships';
  static const String capsulesCollection = 'capsules';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String displayDateFormat = 'MMM d, yyyy';
  static const String timeFormat = 'HH:mm';
}
