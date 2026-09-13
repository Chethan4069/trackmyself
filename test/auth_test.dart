import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:track_my_self/core/database/app_database.dart';
import 'package:track_my_self/features/auth/domain/password_hasher.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  group('PasswordHasher', () {
    test('hashes password to deterministic SHA-256 string', () {
      final hash1 = PasswordHasher.hash('secret123');
      final hash2 = PasswordHasher.hash('secret123');
      expect(hash1, hash2);
      expect(hash1.length, 64);
    });

    test('different passwords produce different hashes', () {
      final hash1 = PasswordHasher.hash('passwordA');
      final hash2 = PasswordHasher.hash('passwordB');
      expect(hash1, isNot(hash2));
    });

    test('verifies correct password against hash', () {
      final hash = PasswordHasher.hash('mySecretPassword');
      expect(PasswordHasher.verify('mySecretPassword', hash), isTrue);
      expect(PasswordHasher.verify('wrongPassword', hash), isFalse);
    });
  });

  group('Auth & Scoped Profile DB Operations', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Register new user creates active session', () async {
      final hash = PasswordHasher.hash('pass123');
      final userId = await db.authDao.createUser('test@example.com', hash);
      expect(userId, greaterThan(0));

      final loggedIn = await db.authDao.getLoggedInUser();
      expect(loggedIn, isNotNull);
      expect(loggedIn!.id, userId);
      expect(loggedIn.email, 'test@example.com');
      expect(loggedIn.isLoggedIn, isTrue);
    });

    test('New user starts with null profile until completed', () async {
      final hash = PasswordHasher.hash('pass123');
      final userId = await db.authDao.createUser('user1@example.com', hash);

      final profile = await db.profileDao.getProfile(userId: userId);
      expect(profile, isNull, reason: 'Brand new user must have no profile until filled');
    });

    test('Profile setup saves and is scoped to user', () async {
      final hash = PasswordHasher.hash('pass123');
      final userId = await db.authDao.createUser('user2@example.com', hash);

      await db.profileDao.upsertProfile(
        UserProfilesCompanion.insert(
          userId: drift.Value(userId),
          name: 'Alex',
          age: 26,
          gender: 'male',
          heightCm: 178,
          weightKg: 72,
          activityLevel: 'moderately_active',
          fitnessGoal: 'improve',
        ),
      );

      final profile = await db.profileDao.getProfile(userId: userId);
      expect(profile, isNotNull);
      expect(profile!.name, 'Alex');
      expect(profile.userId, userId);
      expect(profile.fitnessGoal, 'improve');
    });

    test('Logging out clears active session and logs back in smoothly', () async {
      final hash = PasswordHasher.hash('pass123');
      final userId = await db.authDao.createUser('user3@example.com', hash);

      await db.authDao.logoutAll();
      final noUser = await db.authDao.getLoggedInUser();
      expect(noUser, isNull);

      await db.authDao.setLoggedIn(userId, true);
      final loggedBackIn = await db.authDao.getLoggedInUser();
      expect(loggedBackIn, isNotNull);
      expect(loggedBackIn!.id, userId);
    });
  });

  group('Multi-User Data Isolation Tests', () {
    late AppDatabase db;
    late int user1Id;
    late int user2Id;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      user1Id = await db.authDao.createUser('alice@example.com', PasswordHasher.hash('pass1'));
      user2Id = await db.authDao.createUser('bob@example.com', PasswordHasher.hash('pass2'));
    });

    tearDown(() async {
      await db.close();
    });

    test('Food entries are strictly isolated by userId', () async {
      final now = DateTime.now();

      // Alice adds a food entry
      await db.fitnessDao.insertFood(
        FoodEntriesCompanion.insert(
          userId: drift.Value(user1Id),
          date: now,
          mealType: 'breakfast',
          foodName: 'Oatmeal with Berries',
          quantity: '1 bowl',
          calories: 350.0,
        ),
      );

      // Alice should see 1 food entry
      final aliceFood = await db.fitnessDao.getFoodForDate(now, userId: user1Id);
      expect(aliceFood.length, 1);
      expect(aliceFood.first.foodName, 'Oatmeal with Berries');

      // Bob should see 0 food entries
      final bobFood = await db.fitnessDao.getFoodForDate(now, userId: user2Id);
      expect(bobFood, isEmpty);

      // Bob adds his own food entry
      await db.fitnessDao.insertFood(
        FoodEntriesCompanion.insert(
          userId: drift.Value(user2Id),
          date: now,
          mealType: 'lunch',
          foodName: 'Chicken Salad',
          quantity: '300g',
          calories: 450.0,
        ),
      );

      // Verify each user only sees their own
      final aliceFinal = await db.fitnessDao.getFoodForDate(now, userId: user1Id);
      final bobFinal = await db.fitnessDao.getFoodForDate(now, userId: user2Id);

      expect(aliceFinal.length, 1);
      expect(aliceFinal.first.foodName, 'Oatmeal with Berries');
      expect(bobFinal.length, 1);
      expect(bobFinal.first.foodName, 'Chicken Salad');
    });

    test('Routines are strictly isolated by userId', () async {
      // Alice creates a routine
      await db.routineDao.insertRoutine(
        RoutinesCompanion.insert(
          userId: drift.Value(user1Id),
          name: 'Morning Yoga',
          time: '07:00',
          category: 'health',
        ),
      );

      // Bob should see NO routines
      final bobRoutines = await db.routineDao.getAllActiveRoutines(userId: user2Id);
      expect(bobRoutines, isEmpty);

      // Alice sees her routine
      final aliceRoutines = await db.routineDao.getAllActiveRoutines(userId: user1Id);
      expect(aliceRoutines.length, 1);
      expect(aliceRoutines.first.name, 'Morning Yoga');
    });

    test('Calendar events are strictly isolated by userId', () async {
      final today = DateTime.now();

      // Alice creates a calendar event
      await db.calendarDao.insertEvent(
        CalendarEventsCompanion.insert(
          userId: drift.Value(user1Id),
          title: 'Dentist Appointment',
          date: today,
          time: '14:00',
        ),
      );

      // Bob should see 0 events
      final bobEvents = await db.calendarDao.getEventsForDate(today, userId: user2Id);
      expect(bobEvents, isEmpty);

      // Alice sees her event
      final aliceEvents = await db.calendarDao.getEventsForDate(today, userId: user1Id);
      expect(aliceEvents.length, 1);
      expect(aliceEvents.first.title, 'Dentist Appointment');
    });
  });
}
