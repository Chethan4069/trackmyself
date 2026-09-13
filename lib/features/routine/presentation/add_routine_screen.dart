import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../data/routine_provider.dart';

class AddRoutineScreen extends ConsumerStatefulWidget {
  const AddRoutineScreen({super.key, this.routineItem});

  final RoutineItem? routineItem;

  @override
  ConsumerState<AddRoutineScreen> createState() => _AddRoutineScreenState();
}

class _AddRoutineScreenState extends ConsumerState<AddRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  late String _category;
  late TimeOfDay _time;
  late Set<int> _selectedDays;
  late bool _reminderEnabled;
  bool _isSaving = false;

  static const _categories = [
    ('health', 'Health', Icons.favorite, Colors.teal),
    ('study', 'Study', Icons.school, Colors.indigo),
    ('work', 'Work', Icons.work, Colors.amber),
    ('exercise', 'Exercise', Icons.fitness_center, Colors.deepOrange),
    ('personal', 'Personal', Icons.person, Colors.purple),
    ('other', 'Other', Icons.category, Colors.blueGrey),
  ];

  static const _suggestions = [
    'Drink 2L Water',
    'Morning Workout',
    'Read for 20 mins',
    'Meditate 10 mins',
    'Take Vitamins',
    'Evening Walk',
    'Journal Thoughts',
    'Review Goals',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.routineItem;
    _nameController = TextEditingController(text: item?.routine.name ?? '');
    _category = item?.routine.category ?? 'health';

    if (item != null) {
      final parts = item.routine.time.split(':');
      final h = int.tryParse(parts[0]) ?? 8;
      final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      _time = TimeOfDay(hour: h, minute: m);
      _selectedDays = item.scheduledDays.toSet();
      _reminderEnabled = item.routine.reminderEnabled;
    } else {
      _time = const TimeOfDay(hour: 8, minute: 0);
      _selectedDays = {1, 2, 3, 4, 5, 6, 7};
      _reminderEnabled = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  String _timeString(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _applyPresetDays(String preset) {
    setState(() {
      if (preset == 'all') {
        _selectedDays = {1, 2, 3, 4, 5, 6, 7};
      } else if (preset == 'weekdays') {
        _selectedDays = {1, 2, 3, 4, 5};
      } else if (preset == 'weekends') {
        _selectedDays = {6, 7};
      }
    });
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission is disabled in settings.'),
          ),
        );
      }
    }
    setState(() => _reminderEnabled = value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final controller = ref.read(routineControllerProvider);
      final sortedDays = _selectedDays.toList()..sort();

      await controller.saveRoutine(
        id: widget.routineItem?.routine.id,
        name: _nameController.text.trim(),
        time: _timeString(_time),
        category: _category,
        reminderEnabled: _reminderEnabled,
        daysOfWeek: sortedDays,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.routineItem == null
                  ? 'Routine created!'
                  : 'Routine updated!',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save routine: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete Routine?',
      message:
          'Are you sure you want to delete "${widget.routineItem!.routine.name}"? All completion history will be removed.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final controller = ref.read(routineControllerProvider);
      await controller.deleteRoutine(widget.routineItem!.routine.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEditing = widget.routineItem != null;

    final dayLabels = [
      (1, 'M', 'Mon'),
      (2, 'T', 'Tue'),
      (3, 'W', 'Wed'),
      (4, 'T', 'Thu'),
      (5, 'F', 'Fri'),
      (6, 'S', 'Sat'),
      (7, 'S', 'Sun'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Routine' : 'New Routine'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Routine',
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Routine Name',
                hintText: 'e.g. Drink 2L Water, Morning Run',
                prefixIcon: const Icon(Icons.edit_outlined),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a routine name' : null,
            ),
            const SizedBox(height: 12),

            // Quick suggestions
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _suggestions.map((s) {
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  avatar: const Icon(Icons.add, size: 14),
                  onPressed: () {
                    _nameController.text = s;
                    _nameController.selection = TextSelection.fromPosition(
                      TextPosition(offset: s.length),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Category picker
            Text(
              'Category',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _category == cat.$1;
                return ChoiceChip(
                  avatar: Icon(
                    cat.$3,
                    size: 16,
                    color: isSelected ? cs.onPrimary : cat.$4,
                  ),
                  label: Text(cat.$2),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _category = cat.$1);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Time Picker Tile
            Text(
              'Scheduled Time',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: cs.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.access_time, color: cs.onPrimaryContainer),
                ),
                title: Text(
                  _formatTimeOfDay(_time),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('Tap to change time'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickTime,
              ),
            ),
            const SizedBox(height: 24),

            // Repeat Days
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Repeat Days',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                PopupMenuButton<String>(
                  onSelected: _applyPresetDays,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'all', child: Text('Every Day')),
                    PopupMenuItem(value: 'weekdays', child: Text('Weekdays (Mon–Fri)')),
                    PopupMenuItem(value: 'weekends', child: Text('Weekends (Sat–Sun)')),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Presets',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: cs.primary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: dayLabels.map((d) {
                final isSelected = _selectedDays.contains(d.$1);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDays.remove(d.$1);
                      } else {
                        _selectedDays.add(d.$1);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? cs.primary : cs.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          d.$2,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? cs.onPrimary : cs.onSurface,
                          ),
                        ),
                        Text(
                          d.$3,
                          style: TextStyle(
                            fontSize: 9,
                            color: isSelected
                                ? cs.onPrimary.withValues(alpha: 0.8)
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Notification Reminder Switch
            Card(
              elevation: 0,
              color: cs.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _reminderEnabled
                            ? cs.primaryContainer
                            : cs.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _reminderEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off_outlined,
                        color: _reminderEnabled ? cs.primary : cs.outline,
                      ),
                    ),
                    title: const Text('Daily Reminder'),
                    subtitle: Text(
                      _reminderEnabled
                          ? 'Notify at ${_formatTimeOfDay(_time)}'
                          : 'No reminders will be sent',
                    ),
                    value: _reminderEnabled,
                    onChanged: _toggleReminder,
                  ),
                  if (_reminderEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.send_outlined, size: 18, color: cs.primary),
                      title: Text(
                        'Send Test Reminder Now',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                      subtitle: const Text('Tap to verify notification popup on your device'),
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final granted = await NotificationService.instance.requestPermission();
                        if (!granted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text("Please allow notification permission in Android Settings."),
                            ),
                          );
                          return;
                        }
                        await NotificationService.instance.showInstantTestNotification(
                          title: 'Routine Reminder: ${_nameController.text.isEmpty ? "Drink Water" : _nameController.text}',
                          body: 'Time for your habit at ${_formatTimeOfDay(_time)}!',
                        );
                        messenger.showSnackBar(
                          const SnackBar(content: Text("Test notification sent! Check your notification bar.")),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(
                isEditing ? 'Update Routine' : 'Create Routine',
                style: const TextStyle(fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
