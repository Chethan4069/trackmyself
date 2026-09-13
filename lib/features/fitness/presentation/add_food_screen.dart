import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/fitness_provider.dart';

class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({super.key, this.entry});
  final FoodEntry? entry;

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _mealType = 'lunch';
  bool _saving = false;

  static const _meals = [
    ('breakfast', 'Breakfast', Icons.wb_sunny_outlined),
    ('morning_snack', 'Morning Snack', Icons.cookie_outlined),
    ('lunch', 'Lunch', Icons.lunch_dining_outlined),
    ('afternoon_snack', 'Afternoon Snack', Icons.emoji_food_beverage_outlined),
    ('dinner', 'Dinner', Icons.dinner_dining_outlined),
    ('other', 'Other', Icons.restaurant_outlined),
  ];

  bool get _isEdit => widget.entry != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.entry!;
      _nameCtrl.text = e.foodName;
      _quantityCtrl.text = e.quantity;
      _caloriesCtrl.text = e.calories.toString();
      _notesCtrl.text = e.notes ?? '';
      _mealType = e.mealType;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _caloriesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final companion = FoodEntriesCompanion(
        id: _isEdit ? drift.Value(widget.entry!.id) : const drift.Value.absent(),
        date: drift.Value(ref.read(selectedFitnessDateProvider)),
        mealType: drift.Value(_mealType),
        foodName: drift.Value(_nameCtrl.text.trim()),
        quantity: drift.Value(_quantityCtrl.text.trim()),
        calories: drift.Value(double.parse(_caloriesCtrl.text)),
        notes: drift.Value(
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ),
      );
      if (_isEdit) {
        await ref.read(todayFoodProvider.notifier).edit(companion);
      } else {
        await ref.read(todayFoodProvider.notifier).add(companion);
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
      appBar: AppBar(title: Text(_isEdit ? 'Edit Food' : 'Add Food')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Meal', style: theme.textTheme.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _meals.map((t) {
                  final (value, label, icon) = t;
                  final sel = _mealType == value;
                  return FilterChip(
                    avatar: Icon(icon,
                        size: 16,
                        color: sel
                            ? cs.onPrimaryContainer
                            : cs.onSurfaceVariant),
                    label: Text(label),
                    selected: sel,
                    onSelected: (_) => setState(() => _mealType = value),
                    selectedColor: cs.primaryContainer,
                    checkmarkColor: cs.onPrimaryContainer,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Food name', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'e.g. Idli with sambar',
                  prefixIcon: Icon(Icons.restaurant_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Text('Quantity / Serving', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _quantityCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. 2 pieces / 1 bowl',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Text('Calories (kcal)', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _caloriesCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  hintText: 'e.g. 250',
                  prefixIcon: Icon(Icons.local_fire_department_outlined),
                  suffixText: 'kcal',
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  return (n == null || n < 0)
                      ? 'Enter valid calories'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              Text('Notes (optional)', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. homemade, with ghee...',
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
                    : Text(_isEdit ? 'Save Changes' : 'Add Food'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
