import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/routine_provider.dart';
import 'add_routine_screen.dart';

/// Main Routine & Habit Tracking Screen (Phase 4).
class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selectedDate = ref.watch(selectedRoutineDateProvider);
    final routinesAsync = ref.watch(routinesForDateProvider);
    final stats = ref.watch(routineDayStatsProvider);
    final bestStreak = ref.watch(bestOverallStreakProvider);
    final categoryFilter = ref.watch(routineCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Routine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Pick Date',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                ref.read(selectedRoutineDateProvider.notifier).select(picked);
              }
            },
          ),
          if (!_isToday(selectedDate))
            TextButton(
              onPressed: () =>
                  ref.read(selectedRoutineDateProvider.notifier).goToToday(),
              child: const Text('Today'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Weekly Date Strip
          _WeeklyDateStrip(
            selectedDate: selectedDate,
            onSelectDate: (d) =>
                ref.read(selectedRoutineDateProvider.notifier).select(d),
          ),
          const SizedBox(height: 8),

          // Scrollable Content
          Expanded(
            child: routinesAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.checklist_outlined,
                    title: 'No Routines Yet',
                    message:
                        'Build lasting habits! Tap + below to add your first daily routine.',
                  );
                }

                // Filter by category
                final filtered = categoryFilter == 'all'
                    ? items
                    : items
                        .where((i) => i.routine.category == categoryFilter)
                        .toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // Summary Card
                    _DailyProgressCard(
                      stats: stats,
                      bestStreak: bestStreak,
                      isToday: _isToday(selectedDate),
                    ),
                    const SizedBox(height: 16),

                    // Category Filter Chips
                    _CategoryFilterBar(
                      selected: categoryFilter,
                      onSelect: (cat) => ref
                          .read(routineCategoryFilterProvider.notifier)
                          .setFilter(cat),
                    ),
                    const SizedBox(height: 12),

                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No habits in this category.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filtered.map((item) => _RoutineCard(
                            item: item,
                            date: selectedDate,
                          )),
                    const SizedBox(height: 80), // Fab clearance
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'routine_fab',
        icon: const Icon(Icons.add),
        label: const Text('Add Routine'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddRoutineScreen()),
          );
        },
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

// ─── Weekly Date Strip ─────────────────────────────────────────────────────────

class _WeeklyDateStrip extends StatelessWidget {
  const _WeeklyDateStrip({
    required this.selectedDate,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Generate 7 days centered around selectedDate
    final days = List.generate(7, (i) {
      return selectedDate.subtract(Duration(days: 3 - i));
    });

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((day) {
          final isSelected = day.year == selectedDate.year &&
              day.month == selectedDate.month &&
              day.day == selectedDate.day;
          final isCurrentDay =
              day.year == today.year && day.month == today.month && day.day == today.day;

          final dayLetter = DateFormat('E').format(day).substring(0, 1);
          final dayNum = day.day.toString();

          return GestureDetector(
            onTap: () => onSelectDate(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary
                    : isCurrentDay
                        ? cs.primaryContainer.withValues(alpha: 0.5)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayLetter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? cs.onPrimary
                          : isCurrentDay
                              ? cs.primary
                              : cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNum,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? cs.onPrimary
                          : isCurrentDay
                              ? cs.primary
                              : cs.onSurface,
                    ),
                  ),
                  if (isCurrentDay && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Daily Progress Card ──────────────────────────────────────────────────────

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({
    required this.stats,
    required this.bestStreak,
    required this.isToday,
  });

  final RoutineDayStats stats;
  final int bestStreak;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final percent = (stats.completionPercentage * 100).round();

    final motivationalText = stats.totalScheduled == 0
        ? 'No habits scheduled for this day.'
        : stats.completedCount == stats.totalScheduled
            ? 'All habits completed! Fantastic discipline! 🎉'
            : stats.completedCount > 0
                ? 'Great progress! Keep going! 🚀'
                : 'Start your first habit for the day! ✨';

    return Card(
      elevation: 0,
      color: cs.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday ? "Today's Habit Progress" : "Day's Habit Progress",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        motivationalText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (bestStreak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥 ', style: TextStyle(fontSize: 14)),
                        Text(
                          '$bestStreak d streak',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress bar + metrics
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: stats.completionPercentage,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${stats.completedCount} of ${stats.totalScheduled} Completed',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$percent%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Filter Bar ──────────────────────────────────────────────────────

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.selected,
    required this.onSelect,
  });

  final String selected;
  final ValueChanged<String> onSelect;

  static const _filters = [
    ('all', 'All'),
    ('health', 'Health'),
    ('study', 'Study'),
    ('work', 'Work'),
    ('exercise', 'Exercise'),
    ('personal', 'Personal'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((f) {
          final isSelected = selected == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.$2),
              selected: isSelected,
              onSelected: (_) => onSelect(f.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Routine Card ─────────────────────────────────────────────────────────────

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard({
    required this.item,
    required this.date,
  });

  final RoutineItem item;
  final DateTime date;

  static const _categoryMeta = {
    'health': (Icons.favorite, Colors.teal),
    'study': (Icons.school, Colors.indigo),
    'work': (Icons.work, Colors.amber),
    'exercise': (Icons.fitness_center, Colors.deepOrange),
    'personal': (Icons.person, Colors.purple),
    'other': (Icons.category, Colors.blueGrey),
  };

  String _formatTime(String time) {
    final parts = time.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final dt = DateTime(2026, 1, 1, h, m);
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final routine = item.routine;
    final isDone = item.isCompleted;
    final meta = _categoryMeta[routine.category] ?? _categoryMeta['other']!;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: isDone
          ? cs.surfaceContainerLowest
          : cs.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDone
              ? cs.outlineVariant.withValues(alpha: 0.3)
              : cs.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddRoutineScreen(routineItem: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Checkbox button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(routineControllerProvider).toggleCompletion(
                        routineId: routine.id,
                        date: date,
                        currentlyCompleted: isDone,
                      );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDone ? cs.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone ? cs.primary : cs.outline,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? Icon(Icons.check, color: cs.onPrimary, size: 20)
                      : null,
                ),
              ),
              const SizedBox(width: 14),

              // Routine info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone
                            ? cs.onSurfaceVariant.withValues(alpha: 0.7)
                            : cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: meta.$2.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(meta.$1, size: 11, color: meta.$2),
                              const SizedBox(width: 4),
                              Text(
                                routine.category.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: meta.$2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Time badge
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule,
                                size: 12, color: cs.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Text(
                              _formatTime(routine.time),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),

                        // Streak chip
                        if (item.currentStreak > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '🔥 ${item.currentStreak}d',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Reminder icon if enabled
              if (routine.reminderEnabled)
                Icon(
                  Icons.notifications_active_outlined,
                  size: 16,
                  color: cs.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
