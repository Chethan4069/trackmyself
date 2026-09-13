import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/fitness/presentation/fitness_screen.dart';
import '../features/routine/presentation/routine_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/memory/presentation/memory_screen.dart';
import '../features/profile/presentation/welcome_screen.dart';
import '../features/profile/presentation/profile_setup_screen.dart';
import '../features/profile/presentation/fitness_goal_screen.dart';
import '../features/profile/presentation/profile_edit_screen.dart';
import '../features/profile/data/profile_provider.dart';

abstract class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const fitness = '/fitness';
  static const routine = '/routine';
  static const calendar = '/calendar';
  static const memory = '/memory';
  static const onboarding = '/onboarding';
  static const profileSetup = '/profile-setup';
  static const fitnessGoalSetup = '/fitness-goal-setup';
  static const profileEdit = '/profile-edit';
}

const _shellRoutes = [
  AppRoutes.home,
  AppRoutes.fitness,
  AppRoutes.routine,
  AppRoutes.calendar,
  AppRoutes.memory,
];

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
    _ref.listen(userProfileProvider, (_, _) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = ref.read(authStateProvider);
      final profile = ref.read(userProfileProvider).value;

      final isAuthenticated = user != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      // 1. Unauthenticated -> force login or register
      if (!isAuthenticated) {
        return isAuthRoute ? null : AppRoutes.login;
      }

      // 2. Authenticated but NO profile yet -> redirect to /profile-setup
      // Allow /profile-setup and /fitness-goal-setup so the user can complete both steps
      if (profile == null) {
        final onSetupRoute =
            state.matchedLocation == AppRoutes.profileSetup ||
            state.matchedLocation == AppRoutes.fitnessGoalSetup;
        return onSetupRoute ? null : AppRoutes.profileSetup;
      }

      // 3. Authenticated AND has completed profile:
      // Prevent ever re-entering auth, welcome, or setup screens; send directly to home!
      if (isAuthRoute ||
          state.matchedLocation == AppRoutes.onboarding ||
          state.matchedLocation == AppRoutes.profileSetup ||
          state.matchedLocation == AppRoutes.fitnessGoalSetup) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (_, _) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.fitnessGoalSetup,
        builder: (_, _) => const FitnessGoalScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (_, _) => const ProfileEditScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
          GoRoute(path: AppRoutes.fitness, builder: (_, _) => const FitnessScreen()),
          GoRoute(path: AppRoutes.routine, builder: (_, _) => const RoutineScreen()),
          GoRoute(path: AppRoutes.calendar, builder: (_, _) => const CalendarScreen()),
          GoRoute(path: AppRoutes.memory, builder: (_, _) => const MemoryScreen()),
        ],
      ),
    ],
  );
});

class _ScaffoldWithNavBar extends StatelessWidget {
  const _ScaffoldWithNavBar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (index) => context.go(_shellRoutes[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Fitness',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Routine',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Memory',
          ),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.fitness)) return 1;
    if (location.startsWith(AppRoutes.routine)) return 2;
    if (location.startsWith(AppRoutes.calendar)) return 3;
    if (location.startsWith(AppRoutes.memory)) return 4;
    return 0;
  }
}
