import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/fitness_provider.dart';

class AddExerciseScreen extends ConsumerStatefulWidget {
  const AddExerciseScreen({super.key, this.entry});
  final ExerciseEntry? entry;

  @override
  ConsumerState<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends ConsumerState<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _exerciseType = 'walking';
  String _intensity = 'moderate';
  bool _saving = false;

  static const _exerciseTypes = [
    'walking', 'running', 'cycling', 'swimming', 'yoga',
    'weight_training', 'hiit', 'sports', 'other',
  ];
  static const _intensities = [
    ('low', 'Low', Icons.battery_2_bar),
    ('moderate', 'Moderate', Icons.battery_4_bar),
    ('high', 'High', Icons.battery_full),
  ];

  bool get _isEdit => widget.entry != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.entry!;
      _exerciseType = e.exerciseType;
      _durationCtrl.text = e.durationMinutes.toString();
      _intensity = e.intensity;
      _caloriesCtrl.text = e.estimatedCalories?.toString() ?? '';
      _notesCtrl.text = e.notes ?? '';
    }
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    _caloriesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _label(String type) => type
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final companion = ExerciseEntriesCompanion(
        id: _isEdit
            ? drift.Value(widget.entry!.id)
            : const drift.Value.absent(),
        date: drift.Value(ref.read(selectedFitnessDateProvider)),
        exerciseType: drift.Value(_exerciseType),
        durationMinutes: drift.Value(int.parse(_durationCtrl.text)),
        intensity: drift.Value(_intensity),
        estimatedCalories: drift.Value(
          _caloriesCtrl.text.trim().isEmpty
              ? null
              : double.tryParse(_caloriesCtrl.text),
        ),
        notes: drift.Value(
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ),
      );
      if (_isEdit) {
        await ref.read(todayExerciseProvider.notifier).edit(companion);
      } else {
        await ref.read(todayExerciseProvider.notifier).add(companion);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? 'Edit Exercise' : 'Log Exercise')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Exercise Type', style: theme.textTheme.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _exerciseTypes.map((t) {
                  final sel = _exerciseType == t;
                  return FilterChip(
                    label: Text(_label(t)),
                    selected: sel,
                    onSelected: (_) => setState(() => _exerciseType = t),
                    selectedColor: cs.primaryContainer,
                    checkmarkColor: cs.onPrimaryContainer,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Duration (minutes)', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _durationCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'e.g. 30',
                  prefixIcon: Icon(Icons.timer_outlined),
                  suffixText: 'min',
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n <= 0) ? 'Enter valid duration' : null;
                },
              ),
              const SizedBox(height: 20),
              Text('Intensity', style: theme.textTheme.labelLarge),
              const SizedBox(height: 10),
              Row(
                children: _intensities.map((t) {
                  final (value, label, icon) = t;
                  final sel = _intensity == value;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _intensity = value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: sel
                                ? cs.primaryContainer
                                : cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel ? cs.primary : cs.outlineVariant,
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Column(children: [
                            Icon(icon,
                                size: 22,
                                color: sel
                                    ? cs.onPrimaryContainer
                                    : cs.onSurfaceVariant),
                            const SizedBox(height: 4),
                            Text(label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: sel
                                      ? cs.onPrimaryContainer
                                      : cs.onSurfaceVariant,
                                  fontWeight: sel
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                )),
                          ]),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Calories Burned (optional)',
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _caloriesCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  hintText: 'e.g. 180',
                  prefixIcon: Icon(Icons.local_fire_department_outlined),
                  suffixText: 'kcal',
                ),
              ),
              const SizedBox(height: 16),
              Text('Notes (optional)', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. morning run in the park...',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Save Changes' : 'Log Exercise'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
