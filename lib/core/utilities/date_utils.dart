import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// App-wide date and time utilities.
abstract class AppDateUtils {
  // Formatters
  static final _dateFormatter = DateFormat('dd MMM yyyy');
  static final _timeFormatter = DateFormat('hh:mm a');
  static final _monthFormatter = DateFormat('MMMM yyyy');
  static final _dayFormatter = DateFormat('EEEE, d MMMM');
  static final _shortDayFormatter = DateFormat('EEE');
  static final _hhmm = DateFormat('HH:mm');

  /// e.g. "06 Sep 2026"
  static String formatDate(DateTime date) => _dateFormatter.format(date);

  /// e.g. "07:00 AM"
  static String formatTime(DateTime dt) => _timeFormatter.format(dt);

  /// e.g. "September 2026"
  static String formatMonth(DateTime date) => _monthFormatter.format(date);

  /// e.g. "Sunday, 6 September"
  static String formatFullDay(DateTime date) => _dayFormatter.format(date);

  /// e.g. "Mon"
  static String formatShortDay(DateTime date) => _shortDayFormatter.format(date);

  /// 24-hour "HH:mm" string from a DateTime
  static String toTimeString(DateTime dt) => _hhmm.format(dt);

  /// Parse a "HH:mm" string back to a TimeOfDay
  static TimeOfDay parseTimeString(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// Combine a date and a TimeOfDay into a DateTime
  static DateTime combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// Returns a DateTime representing only the date part (midnight).
  static DateTime dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  /// Greeting based on current hour
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  /// ISO weekday of [date] (1 = Monday … 7 = Sunday)
  static int isoWeekday(DateTime date) => date.weekday;

  /// Warranty expiry date given purchase date + duration in months
  static DateTime warrantyExpiry(DateTime purchaseDate, int durationMonths) {
    int month = purchaseDate.month + durationMonths;
    int year = purchaseDate.year + (month - 1) ~/ 12;
    month = ((month - 1) % 12) + 1;
    final maxDay = DateTime(year, month + 1, 0).day;
    final day = purchaseDate.day.clamp(1, maxDay);
    return DateTime(year, month, day);
  }

  /// Days remaining until [expiryDate] from today.
  static int daysRemaining(DateTime expiryDate) {
    final today = dateOnly(DateTime.now());
    final expiry = dateOnly(expiryDate);
    return expiry.difference(today).inDays;
  }
}
