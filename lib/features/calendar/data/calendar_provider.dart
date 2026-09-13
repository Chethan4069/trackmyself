import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../../auth/data/auth_provider.dart';

final calendarDaoProvider = Provider<CalendarDao>((ref) {
  return ref.watch(databaseProvider).calendarDao;
});

class SelectedCalendarDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void select(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }

  void goToToday() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, now.day);
  }
}

final selectedCalendarDateProvider =
    NotifierProvider<SelectedCalendarDateNotifier, DateTime>(
  SelectedCalendarDateNotifier.new,
);

class DisplayedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month, 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }

  void goToCurrentMonth() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, 1);
  }
}

final displayedMonthProvider =
    NotifierProvider<DisplayedMonthNotifier, DateTime>(
  DisplayedMonthNotifier.new,
);

final eventsForSelectedDateProvider =
    StreamProvider<List<CalendarEvent>>((ref) {
  final dao = ref.watch(calendarDaoProvider);
  final date = ref.watch(selectedCalendarDateProvider);
  final user = ref.watch(authStateProvider);
  return dao.watchEventsForDate(date, userId: user?.id);
});

final eventsForDisplayedMonthProvider =
    StreamProvider<List<CalendarEvent>>((ref) {
  final dao = ref.watch(calendarDaoProvider);
  final month = ref.watch(displayedMonthProvider);
  final user = ref.watch(authStateProvider);
  return dao.watchEventsForMonth(month, userId: user?.id);
});

final eventDatesInMonthProvider = Provider<Set<String>>((ref) {
  final eventsAsync = ref.watch(eventsForDisplayedMonthProvider);
  return eventsAsync.when(
    data: (events) {
      final dates = <String>{};
      for (final e in events) {
        final key =
            '${e.date.year.toString().padLeft(4, '0')}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
        dates.add(key);
      }
      return dates;
    },
    loading: () => const {},
    error: (_, _) => const {},
  );
});

final calendarControllerProvider = Provider<CalendarController>((ref) {
  final dao = ref.watch(calendarDaoProvider);
  final user = ref.watch(authStateProvider);
  return CalendarController(dao, user?.id);
});

class CalendarController {
  final CalendarDao _dao;
  final int? _userId;

  CalendarController(this._dao, [this._userId]);

  Future<int> saveEvent({
    int? id,
    required String title,
    String? description,
    required DateTime date,
    required String time, // 'HH:mm'
    required int reminderMinutes,
    required bool reminderEnabled,
  }) async {
    final cleanDate = DateTime(date.year, date.month, date.day);

    if (id == null) {
      final newId = await _dao.insertEvent(
        CalendarEventsCompanion.insert(
          userId: Value(_userId),
          title: title.trim(),
          description: Value(description?.trim()),
          date: cleanDate,
          time: time,
          reminderMinutes: Value(reminderMinutes),
          reminderEnabled: Value(reminderEnabled),
          createdAt: Value(DateTime.now()),
        ),
      );

      if (reminderEnabled) {
        final parts = time.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final eventDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );

        await NotificationService.instance.scheduleCalendarEventReminder(
          id: newId,
          title: title.trim(),
          eventDateTime: eventDateTime,
          reminderMinutes: reminderMinutes,
        );
      }

      return newId;
    } else {
      final existing = await _dao.getEventById(id);
      if (existing != null) {
        await _dao.updateEvent(
          CalendarEventsCompanion(
            id: Value(id),
            userId: Value(existing.userId ?? _userId),
            title: Value(title.trim()),
            description: Value(description?.trim()),
            date: Value(cleanDate),
            time: Value(time),
            reminderMinutes: Value(reminderMinutes),
            reminderEnabled: Value(reminderEnabled),
            createdAt: Value(existing.createdAt),
            updatedAt: Value(DateTime.now()),
          ),
        );

        if (reminderEnabled) {
          final parts = time.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final eventDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            hour,
            minute,
          );

          await NotificationService.instance.scheduleCalendarEventReminder(
            id: id,
            title: title.trim(),
            eventDateTime: eventDateTime,
            reminderMinutes: reminderMinutes,
          );
        } else {
          await NotificationService.instance.cancel(id);
        }
      }
      return id;
    }
  }

  Future<void> deleteEvent(int id) async {
    await NotificationService.instance.cancel(id);
    await _dao.deleteEvent(id);
  }
}
