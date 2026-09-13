import 'package:drift/drift.dart';

/// User accounts for Authentication
class AppUsers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get passwordHash => text()();
  BoolColumn get isLoggedIn => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// User profile — one per user
class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable().references(AppUsers, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get age => integer()();
  TextColumn get gender => text()(); // 'male' | 'female' | 'other'
  RealColumn get heightCm => real()();
  RealColumn get weightKg => real()();
  TextColumn get activityLevel => text()(); // 'sedentary' | 'lightly_active' | 'moderately_active' | 'very_active'
  TextColumn get fitnessGoal => text()(); // 'maintain' | 'improve' | 'lose_weight' | 'gain_weight' | 'build_strength'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Food log entries
class FoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable().references(AppUsers, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get mealType => text()(); // 'breakfast' | 'morning_snack' | 'lunch' | 'afternoon_snack' | 'dinner' | 'other'
  TextColumn get foodName => text().withLength(min: 1, max: 200)();
  TextColumn get quantity => text().withLength(min: 1, max: 100)();
  RealColumn get calories => real()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Exercise log entries
class ExerciseEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable().references(AppUsers, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get exerciseType => text()(); // 'walking' | 'running' | etc.
  IntColumn get durationMinutes => integer()();
  TextColumn get intensity => text()(); // 'low' | 'moderate' | 'high'
  RealColumn get estimatedCalories => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Recurring routines (template — not per-day)
class Routines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable().references(AppUsers, #id)();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get time => text()(); // stored as 'HH:mm'
  TextColumn get category => text()(); // 'health' | 'study' | 'work' | 'personal' | 'exercise' | 'other'
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Days of the week a routine repeats on
class RoutineDays extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId => integer().references(Routines, #id, onDelete: KeyAction.cascade)();
  IntColumn get dayOfWeek => integer()(); // 1=Monday … 7=Sunday (ISO 8601)
}

/// Daily completion records for routines
class RoutineCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId => integer().references(Routines, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()(); // date only (time ignored)
  TextColumn get status => text()(); // 'pending' | 'completed' | 'skipped' | 'missed'
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// Dated calendar events
class CalendarEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable().references(AppUsers, #id)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get time => text()(); // 'HH:mm'
  IntColumn get reminderMinutes => integer().withDefault(const Constant(30))();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Purchase/warranty records
class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable().references(AppUsers, #id)();
  TextColumn get productName => text().withLength(min: 1, max: 200)();
  TextColumn get category => text()(); // 'electronics' | 'clothing' | 'books' | 'appliances' | 'other'
  RealColumn get price => real()();
  DateTimeColumn get purchaseDate => dateTime()();
  TextColumn get store => text().nullable()();
  IntColumn get warrantyDurationMonths => integer().nullable()();
  DateTimeColumn get warrantyExpiryDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get receiptPath => text().nullable()(); // local file path
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
