import '../../auth/data/auth_provider.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/profile_provider.dart';
import '../domain/calculator/bmi_calculator.dart';
import '../domain/calculator/bmr_calculator.dart';
import '../domain/calculator/calorie_calculator.dart';

/// Full profile edit screen accessible from Home (gear icon).
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  String _gender = 'male';
  String _activityLevel = 'lightly_active';
  String _fitnessGoal = 'maintain';
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _loadProfile(UserProfile p) {
    if (_loaded) return;
    _nameCtrl.text = p.name;
    _ageCtrl.text = p.age.toString();
    _heightCtrl.text = p.heightCm.toString();
    _weightCtrl.text = p.weightKg.toString();
    _gender = p.gender;
    _activityLevel = p.activityLevel;
    _fitnessGoal = p.fitnessGoal;
    _loaded = true;
  }

  Future<void> _save(UserProfile existing) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(userProfileProvider.notifier).save(
            UserProfilesCompanion(
              id: drift.Value(existing.id),
              name: drift.Value(_nameCtrl.text.trim()),
              age: drift.Value(int.parse(_ageCtrl.text)),
              gender: drift.Value(_gender),
              heightCm: drift.Value(double.parse(_heightCtrl.text)),
              weightKg: drift.Value(double.parse(_weightCtrl.text)),
              activityLevel: drift.Value(_activityLevel),
              fitnessGoal: drift.Value(_fitnessGoal),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved!')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found.'));
          }
          _loadProfile(profile);

          // Live stats preview
          final bmr = BmrCalculator.calculate(
            weightKg: double.tryParse(_weightCtrl.text) ?? profile.weightKg,
            heightCm: double.tryParse(_heightCtrl.text) ?? profile.heightCm,
            age: int.tryParse(_ageCtrl.text) ?? profile.age,
            gender: _gender,
          );
          final tdee = CalorieCalculator.calculateTdee(
            bmr: bmr,
            activityLevel: _activityLevel,
          );
          final target = CalorieCalculator.dailyCalorieTarget(
            tdee: tdee,
            fitnessGoal: _fitnessGoal,
          );
          final bmi = BmiCalculator.calculate(
            weightKg: double.tryParse(_weightCtrl.text) ?? profile.weightKg,
            heightCm: double.tryParse(_heightCtrl.text) ?? profile.heightCm,
          );
          final bmiCat = BmiCalculator.category(bmi);

          return SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats preview card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatChip(
                          label: 'BMI',
                          value: '$bmi',
                          sub: bmiCat.label,
                        ),
                        _StatChip(
                          label: 'BMR',
                          value: '${bmr.round()}',
                          sub: 'kcal/day',
                        ),
                        _StatChip(
                          label: 'Target',
                          value: '$target',
                          sub: 'kcal/day',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  _Label('Name'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        hintText: 'Your name',
                        prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  _Label('Age'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        hintText: 'Years',
                        prefixIcon: Icon(Icons.cake_outlined)),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n < 10 || n > 120)
                          ? 'Enter valid age'
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _Label('Gender'),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'male',
                          label: Text('Male'),
                          icon: Icon(Icons.male)),
                      ButtonSegment(
                          value: 'female',
                          label: Text('Female'),
                          icon: Icon(Icons.female)),
                      ButtonSegment(
                          value: 'other',
                          label: Text('Other'),
                          icon: Icon(Icons.person)),
                    ],
                    selected: {_gender},
                    onSelectionChanged: (s) =>
                        setState(() => _gender = s.first),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Height (cm)'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _heightCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  hintText: '175',
                                  suffixText: 'cm'),
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                return (n == null || n < 50 || n > 250)
                                    ? '50–250 cm'
                                    : null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Weight (kg)'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _weightCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  hintText: '70',
                                  suffixText: 'kg'),
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                return (n == null || n < 20 || n > 300)
                                    ? '20–300 kg'
                                    : null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _Label('Activity Level'),
                  const SizedBox(height: 10),
                  _DropdownField<String>(
                    value: _activityLevel,
                    items: const [
                      DropdownMenuItem(
                          value: 'sedentary', child: Text('Sedentary')),
                      DropdownMenuItem(
                          value: 'lightly_active',
                          child: Text('Lightly Active')),
                      DropdownMenuItem(
                          value: 'moderately_active',
                          child: Text('Moderately Active')),
                      DropdownMenuItem(
                          value: 'very_active', child: Text('Very Active')),
                    ],
                    onChanged: (v) =>
                        setState(() => _activityLevel = v ?? _activityLevel),
                  ),
                  const SizedBox(height: 16),

                  _Label('Fitness Goal'),
                  const SizedBox(height: 10),
                  _DropdownField<String>(
                    value: _fitnessGoal,
                    items: const [
                      DropdownMenuItem(
                          value: 'lose_weight', child: Text('Lose Weight')),
                      DropdownMenuItem(
                          value: 'maintain', child: Text('Maintain Weight')),
                      DropdownMenuItem(
                          value: 'improve', child: Text('Improve Fitness')),
                      DropdownMenuItem(
                          value: 'gain_weight', child: Text('Gain Weight')),
                      DropdownMenuItem(
                          value: 'build_strength',
                          child: Text('Build Strength')),
                    ],
                    onChanged: (v) =>
                        setState(() => _fitnessGoal = v ?? _fitnessGoal),
                  ),
                  const SizedBox(height: 36),

                  FilledButton(
                    onPressed: _saving ? null : () => _save(profile),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Profile'),
                  ),
                  const SizedBox(height: 24),
                  // Log Out Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showConfirmationDialog(
                        context: context,
                        title: 'Log Out?',
                        message: 'Are you sure you want to log out of your account?',
                        confirmLabel: 'Log Out',
                        isDestructive: true,
                      );
                      if (confirmed == true) {
                        await ref.read(authStateProvider.notifier).logout(); ref.read(userProfileProvider.notifier).clear();
                      }
                    },
                    icon: Icon(Icons.logout, color: cs.error),
                    label: Text('Log Out', style: TextStyle(color: cs.error)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
      );
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.value, required this.sub});
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      children: [
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: cs.onPrimaryContainer)),
        const SizedBox(height: 2),
        Text(value,
            style: theme.textTheme.titleMedium?.copyWith(
                color: cs.onPrimaryContainer, fontWeight: FontWeight.w700)),
        Text(sub,
            style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onPrimaryContainer.withValues(alpha: 0.7))),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
