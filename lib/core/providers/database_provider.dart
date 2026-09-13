import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

/// Provides the singleton [AppDatabase] instance.
/// The actual instance is injected via ProviderScope override in main.dart.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(
    'databaseProvider must be overridden in ProviderScope',
  ),
);
