import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth.dart';
import 'features/habits/habits.dart';

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Main app routes with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          // Home / Dashboard
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),

          // Habits
          GoRoute(
            path: '/habits',
            builder: (context, state) => const HabitsListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const HabitFormScreen(),
              ),
              GoRoute(
                path: ':habitId',
                builder: (context, state) => HabitDetailScreen(
                  habitId: state.pathParameters['habitId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => HabitFormScreen(
                      habitId: state.pathParameters['habitId'],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Profile
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

class IndirectGrowthApp extends ConsumerWidget {
  const IndirectGrowthApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Indirect Growth',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Main scaffold with bottom navigation
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            selectedIcon: Icon(Icons.track_changes),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/habits')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/habits');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }
}

// Home Screen (Dashboard)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsWithStatusAsync = ref.watch(habitsWithStatusProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: currentUserAsync.when(
          data: (user) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
              ),
              Text(
                user?.displayName ?? 'Traveler',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Indirect Growth'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats Card
            _QuickStatsCard(habitsWithStatusAsync: habitsWithStatusAsync),
            const SizedBox(height: 24),

            // Today's Habits Section
            Text(
              "Today's Habits",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _TodayHabitsSection(habitsWithStatusAsync: habitsWithStatusAsync, ref: ref),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _QuickActionsGrid(),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsCard extends StatelessWidget {
  final AsyncValue<List<HabitWithStatus>> habitsWithStatusAsync;

  const _QuickStatsCard({required this.habitsWithStatusAsync});

  @override
  Widget build(BuildContext context) {
    return habitsWithStatusAsync.when(
      data: (habits) {
        final total = habits.length;
        final completed = habits.where((h) => h.isCompletedToday).length;
        final longestStreak = habits.isEmpty
            ? 0
            : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.check_circle,
                  value: '$completed/$total',
                  label: 'Today',
                  color: AppTheme.successColor,
                ),
                _StatItem(
                  icon: Icons.local_fire_department,
                  value: '$longestStreak',
                  label: 'Best Streak',
                  color: AppTheme.warningColor,
                ),
                _StatItem(
                  icon: Icons.track_changes,
                  value: '$total',
                  label: 'Active Habits',
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white54,
              ),
        ),
      ],
    );
  }
}

class _TodayHabitsSection extends StatelessWidget {
  final AsyncValue<List<HabitWithStatus>> habitsWithStatusAsync;
  final WidgetRef ref;

  const _TodayHabitsSection({
    required this.habitsWithStatusAsync,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return habitsWithStatusAsync.when(
      data: (habits) {
        if (habits.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.add_task,
                    size: 48,
                    color: AppTheme.primaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  const Text('No habits yet'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/habits/create'),
                    child: const Text('Add your first habit'),
                  ),
                ],
              ),
            ),
          );
        }

        // Show up to 5 habits
        final displayHabits = habits.take(5).toList();

        return Column(
          children: [
            ...displayHabits.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HabitCard(
                    habitWithStatus: h,
                    onToggle: () {
                      ref
                          .read(habitsNotifierProvider.notifier)
                          .toggleCompletion(h.habit.id, DateTime.now());
                    },
                    onTap: () => context.push('/habits/${h.habit.id}'),
                  ),
                )),
            if (habits.length > 5)
              TextButton(
                onPressed: () => context.go('/habits'),
                child: Text('View all ${habits.length} habits'),
              ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
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
        _QuickActionCard(
          icon: Icons.add,
          label: 'New Habit',
          color: AppTheme.primaryColor,
          onTap: () => context.push('/habits/create'),
        ),
        _QuickActionCard(
          icon: Icons.book,
          label: 'Journal',
          color: AppTheme.secondaryColor,
          onTap: () {
            // TODO: Navigate to diary
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Diary coming soon!')),
            );
          },
        ),
        _QuickActionCard(
          icon: Icons.trending_up,
          label: 'Progress',
          color: AppTheme.accentColor,
          onTap: () {
            // TODO: Navigate to progression
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Progression coming soon!')),
            );
          },
        ),
        _QuickActionCard(
          icon: Icons.psychology,
          label: 'Reflect',
          color: AppTheme.warningColor,
          onTap: () {
            // TODO: Navigate to shadow/reflection
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reflection coming soon!')),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Profile Screen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: currentUserAsync.when(
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  (user?.displayName ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.displayName ?? 'User',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                user?.email ?? '',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white54,
                    ),
              ),
              const SizedBox(height: 32),

              // Settings List
              _SettingsSection(
                title: 'Account',
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () {
                      // TODO: Edit profile
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {
                      // TODO: Notifications settings
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'App',
                children: [
                  _SettingsTile(
                    icon: Icons.color_lens_outlined,
                    title: 'Theme',
                    subtitle: 'Dark',
                    onTap: () {
                      // TODO: Theme settings
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Indirect Growth',
                        applicationVersion: '1.0.0',
                        applicationLegalese: 'A personal development app',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white54,
                ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
