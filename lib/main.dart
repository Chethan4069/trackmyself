import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';
import 'core/notifications/notification_service.dart';
import 'core/providers/database_provider.dart';
import 'features/auth/data/auth_provider.dart';
import 'features/profile/data/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise local notifications
  await NotificationService.instance.initialise();

  // Initialise the database once at startup
  final database = AppDatabase();

  // Pre-load initial auth and profile state to avoid startup async flicker
  final initialUser = await database.authDao.getLoggedInUser();
  UserProfile? initialProfile;
  if (initialUser != null) {
    initialProfile = await database.profileDao.getProfile(userId: initialUser.id);
  }

  runApp(
    ProviderScope(
      overrides: [
        // Inject the real database instance
        databaseProvider.overrideWithValue(database),
        initialUserProvider.overrideWithValue(initialUser),
        initialProfileProvider.overrideWithValue(initialProfile),
      ],
      child: const TrackMySelfApp(),
    ),
  );
}
