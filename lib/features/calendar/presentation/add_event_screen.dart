import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../data/calendar_provider.dart';

class AddEventScreen extends ConsumerStatefulWidget {
  const AddEventScreen({
    super.key,
    this.event,
    this.initialDate,
  });

  final CalendarEvent? event;
  final DateTime? initialDate;

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late DateTime _date;
  late TimeOfDay _time;
  late int _reminderMinutes;
  late bool _reminderEnabled;
  bool _isSaving = false;

  static const _suggestions = [
    'Doctor Appointment',
    'Dentist Visit',
    'Team Meeting',
    'Birthday Party',
    'Flight Departure',
    'Car Service',
    'Bill Payment Due',
    'Conference Call',
  ];

  static const _reminderOptions = [
    (0, 'At time of event'),
    (10, '10 minutes before'),
    (15, '15 minutes before'),
    (30, '30 minutes before'),
    (60, '1 hour before'),
    (1440, '1 day before'),
  ];

  @override
  void initState() {
    super.initState();
    final ev = widget.event;
    _titleController = TextEditingController(text: ev?.title ?? '');
    _descriptionController =
        TextEditingController(text: ev?.description ?? '');

    if (ev != null) {
      _date = ev.date;
      final parts = ev.time.split(':');
      final h = int.tryParse(parts[0]) ?? 10;
      final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      _time = TimeOfDay(hour: h, minute: m);
      _reminderMinutes = ev.reminderMinutes;
      _reminderEnabled = ev.reminderEnabled;
    } else {
      final now = DateTime.now();
      _date = widget.initialDate ?? DateTime(now.year, now.month, now.day);
      _time = TimeOfDay(hour: now.hour + 1 > 23 ? 10 : now.hour + 1, minute: 0);
      _reminderMinutes = 15;
      _reminderEnabled = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
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

  Future<void> _toggleReminder(bool val) async {
    if (val) {
      final granted = await NotificationService.instance.requestPermission();
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable notification permission in settings.'),
          ),
        );
      }
    }
    setState(() => _reminderEnabled = val);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final controller = ref.read(calendarControllerProvider);
      await controller.saveEvent(
        id: widget.event?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _date,
        time: _timeString(_time),
        reminderMinutes: _reminderMinutes,
        reminderEnabled: _reminderEnabled,
      );

      // Keep displayed month aligned with saved event
      ref
          .read(displayedMonthProvider.notifier)
          .setMonth(DateTime(_date.year, _date.month, 1));
      ref.read(selectedCalendarDateProvider.notifier).select(_date);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.event == null ? 'Event scheduled!' : 'Event updated!',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save event: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete Event?',
      message: 'Are you sure you want to delete "${widget.event!.title}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final controller = ref.read(calendarControllerProvider);
      await controller.deleteEvent(widget.event!.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEditing = widget.event != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Event' : 'New Event'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Event',
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
            // Title input
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Event Title',
                hintText: 'e.g. Doctor Appointment, Meeting',
                prefixIcon: const Icon(Icons.event_note_outlined),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 12),

            // Suggestions
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _suggestions.map((s) {
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  avatar: const Icon(Icons.add, size: 14),
                  onPressed: () {
                    _titleController.text = s;
                    _titleController.selection = TextSelection.fromPosition(
                      TextPosition(offset: s.length),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Date & Time row
            Row(
              children: [
                // Date card
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: cs.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickDate,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 16, color: cs.primary),
                                const SizedBox(width: 6),
                                Text('Date',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: cs.onSurfaceVariant)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('EEE, MMM d, y').format(_date),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Time card
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: cs.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickTime,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 16, color: cs.primary),
                                const SizedBox(width: 6),
                                Text('Time',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: cs.onSurfaceVariant)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatTimeOfDay(_time),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Reminder section
            Card(
              elevation: 0,
              color: cs.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
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
                      title: const Text('Event Reminder'),
                      subtitle: Text(_reminderEnabled
                          ? 'Notify before event'
                          : 'No reminder'),
                      value: _reminderEnabled,
                      onChanged: _toggleReminder,
                    ),
                    if (_reminderEnabled) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Remind me',
                            border: InputBorder.none,
                          ),
                          initialValue: _reminderMinutes,
                          items: _reminderOptions.map((opt) {
                            return DropdownMenuItem(
                              value: opt.$1,
                              child: Text(opt.$2),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _reminderMinutes = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Notes / Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes & Details (Optional)',
                hintText: 'Add location, meeting link, or details...',
                prefixIcon: const Icon(Icons.notes_outlined),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // Submit button
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
                isEditing ? 'Update Event' : 'Schedule Event',
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
