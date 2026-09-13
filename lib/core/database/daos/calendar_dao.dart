import 'package:drift/drift.dart';
import '../app_database.dart';

part 'calendar_dao.g.dart';

@DriftAccessor(tables: [CalendarEvents])
class CalendarDao extends DatabaseAccessor<AppDatabase>
    with _$CalendarDaoMixin {
  CalendarDao(super.db);

  Future<List<CalendarEvent>> getEventsForDate(DateTime date, {int? userId}) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(calendarEvents)
          ..where((e) {
            final match = e.date.isBetweenValues(start, end);
            if (userId != null) {
              return match & e.userId.equals(userId);
            }
            return match & e.userId.isNull();
          })
          ..orderBy([(e) => OrderingTerm.asc(e.time)]))
        .get();
  }

  Stream<List<CalendarEvent>> watchEventsForDate(DateTime date, {int? userId}) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(calendarEvents)
          ..where((e) {
            final match = e.date.isBetweenValues(start, end);
            if (userId != null) {
              return match & e.userId.equals(userId);
            }
            return match & e.userId.isNull();
          })
          ..orderBy([(e) => OrderingTerm.asc(e.time)]))
        .watch();
  }

  Stream<List<CalendarEvent>> watchEventsForMonth(DateTime month, {int? userId}) {
    final start = DateTime(month.year, month.month, 1);
    final nextMonth = month.month == 12
        ? DateTime(month.year + 1, 1, 1)
        : DateTime(month.year, month.month + 1, 1);
    return (select(calendarEvents)
          ..where((e) {
            final match = e.date.isBiggerOrEqualValue(start) &
                e.date.isSmallerThanValue(nextMonth);
            if (userId != null) {
              return match & e.userId.equals(userId);
            }
            return match & e.userId.isNull();
          })
          ..orderBy([
            (e) => OrderingTerm.asc(e.date),
            (e) => OrderingTerm.asc(e.time),
          ]))
        .watch();
  }

  Future<List<CalendarEvent>> getUpcomingEvents(DateTime from, {int? userId}) {
    return (select(calendarEvents)
          ..where((e) {
            final match = e.date.isBiggerOrEqualValue(from);
            if (userId != null) {
              return match & e.userId.equals(userId);
            }
            return match & e.userId.isNull();
          })
          ..orderBy([
            (e) => OrderingTerm.asc(e.date),
            (e) => OrderingTerm.asc(e.time),
          ]))
        .get();
  }

  Future<int> insertEvent(CalendarEventsCompanion event) =>
      into(calendarEvents).insert(event);

  Future<bool> updateEvent(CalendarEventsCompanion event) =>
      update(calendarEvents).replace(event);

  Future<int> deleteEvent(int id) =>
      (delete(calendarEvents)..where((e) => e.id.equals(id))).go();

  Future<CalendarEvent?> getEventById(int id) =>
      (select(calendarEvents)..where((e) => e.id.equals(id))).getSingleOrNull();
}
