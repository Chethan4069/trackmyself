import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

/// First-launch welcome screen. Leads into profile setup.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              // Hero icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.self_improvement,
                  size: 44,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to\nTrackMySelf',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your personal dashboard for fitness, daily routines, '
                'events and purchases — all offline, all private.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
              const Spacer(flex: 3),
              // Feature highlights
              _FeatureRow(
                icon: Icons.fitness_center,
                color: cs.primary,
                text: 'Track calories & workouts',
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.checklist,
                color: cs.secondary,
                text: 'Build consistent daily routines',
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.calendar_month,
                color: cs.tertiary,
                text: 'Never miss an event or deadline',
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.inventory_2,
                color: Colors.orange,
                text: 'Track purchases & warranties',
              ),
              const Spacer(flex: 2),
              FilledButton(
                onPressed: () => context.go(AppRoutes.profileSetup),
                child: const Text("Let's get started"),
              ),
              const SizedBox(height: 12),
              Text(
                'All data stays on your device. No accounts, no cloud.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
