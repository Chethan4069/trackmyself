import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/calendar_provider.dart';
import 'add_event_screen.dart';

/// Full Interactive Calendar & Events Screen (Phase 5).
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final displayedMonth = ref.watch(displayedMonthProvider);
    final eventsAsync = ref.watch(eventsForSelectedDateProvider);
    final eventDatesInMonth = ref.watch(eventDatesInMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar & Events'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.today, size: 18),
            label: const Text('Today'),
            onPressed: () {
              ref.read(selectedCalendarDateProvider.notifier).goToToday();
              ref.read(displayedMonthProvider.notifier).goToCurrentMonth();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Month navigation bar
          _MonthNavigator(
            displayedMonth: displayedMonth,
            onPrevMonth: () =>
                ref.read(displayedMonthProvider.notifier).previousMonth(),
            onNextMonth: () =>
                ref.read(displayedMonthProvider.notifier).nextMonth(),
          ),

          // Monthly calendar grid
          _CalendarGrid(
            displayedMonth: displayedMonth,
            selectedDate: selectedDate,
            eventDates: eventDatesInMonth,
            onSelectDate: (d) =>
                ref.read(selectedCalendarDateProvider.notifier).select(d),
          ),
          const SizedBox(height: 10),

          const Divider(height: 1),

          // Selected day events agenda header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.event, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      _formatAgendaDate(selectedDate),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                eventsAsync.when(
                  data: (events) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${events.length} ${events.length == 1 ? 'Event' : 'Events'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Selected Day Event List
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'No Events Scheduled',
                    message:
                        'Nothing planned for ${_formatAgendaDate(selectedDate)}.\nTap + below to add an event or appointment.',
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final ev = events[index];
                    return _EventCard(event: ev);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'calendar_fab',
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddEventScreen(initialDate: selectedDate),
            ),
          );
        },
      ),
    );
  }

  String _formatAgendaDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today (${DateFormat('MMM d').format(d)})';
    }
    return DateFormat('EEEE, MMM d').format(d);
  }
}

// ─── Month Navigator ──────────────────────────────────────────────────────────

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.displayedMonth,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final DateTime displayedMonth;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthStr = DateFormat('MMMM yyyy').format(displayedMonth);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous Month',
            onPressed: onPrevMonth,
          ),
          Text(
            monthStr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next Month',
            onPressed: onNextMonth,
          ),
        ],
      ),
    );
  }
}

// ─── Calendar Grid ────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.displayedMonth,
    required this.selectedDate,
    required this.eventDates,
    required this.onSelectDate,
  });

  final DateTime displayedMonth;
  final DateTime selectedDate;
  final Set<String> eventDates;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    const dayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final firstDayOfMonth =
        DateTime(displayedMonth.year, displayedMonth.month, 1);
    final daysInMonth =
        DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;

    // ISO weekday: Monday = 1, Sunday = 7
    final leadingEmpty = firstDayOfMonth.weekday - 1;

    final totalCells = ((leadingEmpty + daysInMonth + 6) ~/ 7) * 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Weekday header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayHeaders.map((h) {
              return SizedBox(
                width: 38,
                child: Center(
                  child: Text(
                    h,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),

          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final dayNum = index - leadingEmpty + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date =
                  DateTime(displayedMonth.year, displayedMonth.month, dayNum);
              final isSelected = date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;

              final dateKey =
                  '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              final hasEvents = eventDates.contains(dateKey);

              return GestureDetector(
                onTap: () => onSelectDate(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary
                        : isToday
                            ? cs.primaryContainer.withValues(alpha: 0.5)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(color: cs.primary, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? cs.onPrimary
                              : isToday
                                  ? cs.primary
                                  : cs.onSurface,
                        ),
                      ),
                      // Event dot
                      if (hasEvents)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected ? cs.onPrimary : cs.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 7),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final CalendarEvent event;

  String _formatTime(String time) {
    final parts = time.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final dt = DateTime(2026, 1, 1, h, m);
    return DateFormat('hh:mm a').format(dt);
  }

  String _reminderText(int minutes) {
    if (minutes == 0) return 'At event time';
    if (minutes < 60) return '$minutes mins before';
    if (minutes == 60) return '1 hr before';
    return '1 day before';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddEventScreen(event: event),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.event_note,
                        size: 20, color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 14, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(event.time),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (event.reminderEnabled) ...[
                              const SizedBox(width: 10),
                              Icon(Icons.notifications_active,
                                  size: 13, color: cs.primary),
                              const SizedBox(width: 3),
                              Text(
                                _reminderText(event.reminderMinutes),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: cs.outline),
                ],
              ),
              if (event.description != null &&
                  event.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  event.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
