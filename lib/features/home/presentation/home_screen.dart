import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../core/utilities/date_utils.dart' as date_util;
import '../../../features/profile/data/profile_provider.dart';
import '../../../features/profile/domain/calculator/bmi_calculator.dart';
import '../../../features/profile/domain/calculator/bmr_calculator.dart';

/// Phase 7: Executive Home Dashboard matching the reference design:
/// - Scenic mountain sunrise header with live greeting & date
/// - "Your Fitness Overview" 4-tile card + vitals strip
/// - "Quick Actions" 5 colorful navigation cards
/// - Panoramic motivational quote card
/// - "Today's Fitness Tip" with interactive "Got it!" action
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _tipCompleted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    final profileAsync = ref.watch(userProfileProvider);
    final name = ref.watch(userNameProvider);
    final calorieTarget = ref.watch(dailyCalorieTargetProvider);

    // Formatted date (e.g. Fri, 12 Sep 2025)
    final dateStr = DateFormat('EEE, d MMM yyyy').format(now);
    final greeting = date_util.AppDateUtils.greeting();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // ── 1. Scenic Mountain Header ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Background image
                Image.asset(
                  'assets/images/header_sunrise.jpg',
                  height: 330,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
                // Gradient overlay for readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.10),
                          isDark
                              ? const Color(0xFF0F172A).withValues(alpha: 0.95)
                              : const Color(0xFFF8FAFC).withValues(alpha: 0.98),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                // Header Content
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top bar: App Name + Subtitle + Profile Avatar
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TrackMySelf',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0, 1),
                                          blurRadius: 4,
                                          color: Colors.black54,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'A Healthier Today, A Better You Tomorrow',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      shadows: const [
                                        Shadow(
                                          offset: Offset(0, 1),
                                          blurRadius: 3,
                                          color: Colors.black45,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Profile Avatar
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => context.push(AppRoutes.profileEdit),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white70, width: 1.5),
                                  ),
                                  child: const CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Color(0xFF2E6B56),
                                    child: Icon(Icons.person, color: Colors.white, size: 22),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Greeting + User Name
                        Text(
                          '$greeting,',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.95),
                            shadows: const [
                              Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black54),
                            ],
                          ),
                        ),
                        Text(
                          name.isNotEmpty ? '$name!' : 'Friend!',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(offset: Offset(0, 2), blurRadius: 6, color: Colors.black87),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: Text(
                            'Small steps every day lead to a healthier, happier you.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.90),
                              height: 1.3,
                              shadows: const [
                                Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Bottom Header Badges: Live Date & Make Today Count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                                    : Colors.white.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? Colors.white24 : Colors.black12,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24, width: 0.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.wb_sunny_rounded, size: 14, color: Color(0xFFFFD54F)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Make today count!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Body Sections ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Card 1: Your Fitness Overview ───────────────────────────
                profileAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading profile: $e'),
                  data: (profile) {
                    if (profile == null) {
                      return _buildEmptyProfileCard(context, isDark);
                    }

                    final bmi = BmiCalculator.calculate(
                      weightKg: profile.weightKg,
                      heightCm: profile.heightCm,
                    );
                    final bmiCat = BmiCalculator.category(bmi);
                    final bmr = BmrCalculator.calculate(
                      weightKg: profile.weightKg,
                      heightCm: profile.heightCm,
                      age: profile.age,
                      gender: profile.gender,
                    );

                    return _buildFitnessOverviewCard(
                      context: context,
                      isDark: isDark,
                      profile: profile,
                      bmi: bmi,
                      bmiCat: bmiCat,
                      bmr: bmr,
                      calorieTarget: calorieTarget,
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ── Section 2: Quick Actions ────────────────────────────────
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuickActionsRow(context, isDark),

                const SizedBox(height: 24),

                // ── Section 3: Panoramic Motivational Quote Banner ──────────
                _buildMotivationalBanner(context, isDark),

                const SizedBox(height: 24),

                // ── Section 4: Today's Fitness Tip ──────────────────────────
                _buildFitnessTipSection(context, isDark),

                const SizedBox(height: 12),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: Fitness Overview Card ─────────────────────────────────────────
  Widget _buildFitnessOverviewCard({
    required BuildContext context,
    required bool isDark,
    required dynamic profile,
    required double bmi,
    required BmiCategory bmiCat,
    required double bmr,
    required int calorieTarget,
  }) {
    final numberFmt = NumberFormat('#,###');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 3.5,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Your Fitness Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => context.push(AppRoutes.profileEdit),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Profile',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2E7D32)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 4 Metric Tiles Row
          Row(
            children: [
              // 1. BMI Tile
              Expanded(
                child: _buildMetricTile(
                  isDark: isDark,
                  bgColor: isDark ? const Color(0xFF143022) : const Color(0xFFE8F5E9),
                  icon: Icons.scale_rounded,
                  iconColor: const Color(0xFF2E7D32),
                  label: 'BMI',
                  value: '$bmi',
                  badge: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _bmiBadgeBg(bmiCat),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      bmiCat.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _bmiBadgeText(bmiCat),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. BMR Tile
              Expanded(
                child: _buildMetricTile(
                  isDark: isDark,
                  bgColor: isDark ? const Color(0xFF132840) : const Color(0xFFE3F2FD),
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFF1976D2),
                  label: 'BMR',
                  value: numberFmt.format(bmr.round()),
                  subtext: 'kcal/day',
                ),
              ),
              const SizedBox(width: 8),

              // 3. Daily Energy Tile
              Expanded(
                child: _buildMetricTile(
                  isDark: isDark,
                  bgColor: isDark ? const Color(0xFF382915) : const Color(0xFFFFF8E1),
                  icon: Icons.restaurant_rounded,
                  iconColor: const Color(0xFFF57C00),
                  label: 'Daily Energy',
                  value: numberFmt.format(calorieTarget),
                  subtext: 'kcal (est.)',
                ),
              ),
              const SizedBox(width: 8),

              // 4. Goal Tile
              Expanded(
                child: _buildMetricTile(
                  isDark: isDark,
                  bgColor: isDark ? const Color(0xFF361826) : const Color(0xFFFCE4EC),
                  icon: Icons.track_changes_rounded,
                  iconColor: const Color(0xFFD81B60),
                  label: 'Goal',
                  value: _goalShort(profile.fitnessGoal),
                  isBoldSmall: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Personal Vitals Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildVitalItem(Icons.person_outline_rounded, 'Age', '${profile.age}', isDark),
                _buildVitalDivider(isDark),
                _buildVitalItem(Icons.straighten_rounded, 'Height', '${profile.heightCm} cm', isDark),
                _buildVitalDivider(isDark),
                _buildVitalItem(Icons.monitor_weight_outlined, 'Weight', '${profile.weightKg} kg', isDark),
                _buildVitalDivider(isDark),
                _buildVitalItem(Icons.bolt_rounded, 'Activity', _activityShort(profile.activityLevel), isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required bool isDark,
    required Color bgColor,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? subtext,
    Widget? badge,
    bool isBoldSmall = false,
  }) {
    return Container(
      height: 124,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isBoldSmall ? 12 : 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(height: 4),
            badge,
          ] else if (subtext != null) ...[
            const SizedBox(height: 2),
            Text(
              subtext,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalItem(IconData icon, String label, String value, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildVitalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
    );
  }

  // ── Helper: Quick Actions ─────────────────────────────────────────────────
  Widget _buildQuickActionsRow(BuildContext context, bool isDark) {
    final actions = [
      _QuickAction(
        title: 'Fitness',
        subtitle: 'Track Progress',
        icon: Icons.fitness_center_rounded,
        iconColor: const Color(0xFF2E7D32),
        bgColor: isDark ? const Color(0xFF143022) : const Color(0xFFE8F5E9),
        route: AppRoutes.fitness,
      ),
      _QuickAction(
        title: 'Routine',
        subtitle: 'Build Habits',
        icon: Icons.assignment_turned_in_rounded,
        iconColor: const Color(0xFF1976D2),
        bgColor: isDark ? const Color(0xFF132840) : const Color(0xFFE3F2FD),
        route: AppRoutes.routine,
      ),
      _QuickAction(
        title: 'Calendar',
        subtitle: 'Stay Organized',
        icon: Icons.calendar_month_rounded,
        iconColor: const Color(0xFF7B1FA2),
        bgColor: isDark ? const Color(0xFF2D1638) : const Color(0xFFF3E5F5),
        route: AppRoutes.calendar,
      ),
      _QuickAction(
        title: 'Purchases',
        subtitle: 'Track Items',
        icon: Icons.shopping_cart_rounded,
        iconColor: const Color(0xFFE65100),
        bgColor: isDark ? const Color(0xFF382012) : const Color(0xFFFFE0B2),
        route: AppRoutes.memory,
      ),
      _QuickAction(
        title: 'Warranty',
        subtitle: 'Never Miss',
        icon: Icons.verified_user_rounded,
        iconColor: const Color(0xFF00796B),
        bgColor: isDark ? const Color(0xFF122C2A) : const Color(0xFFE0F2F1),
        route: AppRoutes.memory,
      ),
    ];

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final a = actions[i];
          return InkWell(
            onTap: () => context.go(a.route),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              decoration: BoxDecoration(
                color: a.bgColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.04),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(a.icon, size: 24, color: a.iconColor),
                  const SizedBox(height: 6),
                  Text(
                    a.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    a.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Helper: Motivational Banner ───────────────────────────────────────────
  Widget _buildMotivationalBanner(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 804 / 214,
          child: Image.asset(
            'assets/images/quote_banner.png',
            width: double.infinity,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }

  // ── Helper: Today's Fitness Tip ───────────────────────────────────────────
  Widget _buildFitnessTipSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_rounded, size: 20, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Text(
              "Today's Fitness Tip",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () => context.go(AppRoutes.fitness),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See More',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2E7D32)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF142E24) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF1B4D3E) : const Color(0xFFDCFCE7),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/fitness_tip_water.png',
                  width: 76,
                  height: 76,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stay Hydrated',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Drinking enough water helps with metabolism, energy levels and better workout performance.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _tipCompleted
                            ? const Color(0xFF1B5E20)
                            : const Color(0xFF2E6B56),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _tipCompleted = !_tipCompleted;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _tipCompleted
                                  ? 'Awesome! Keep staying hydrated today 💧'
                                  : 'Tip reset',
                            ),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_tipCompleted) ...[
                            const Icon(Icons.check, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            _tipCompleted ? 'Completed!' : 'Got it!',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyProfileCard(BuildContext context, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Complete your profile to view your personalized health targets.'),
            ),
            FilledButton(
              onPressed: () => context.push(AppRoutes.profileSetup),
              child: const Text('Setup'),
            ),
          ],
        ),
      ),
    );
  }

  Color _bmiBadgeBg(BmiCategory cat) => switch (cat) {
        BmiCategory.normal => const Color(0xFFC8E6C9),
        BmiCategory.underweight => const Color(0xFFE1BEE7),
        BmiCategory.overweight => const Color(0xFFFFE0B2),
        BmiCategory.obese => const Color(0xFFFFCDD2),
      };

  Color _bmiBadgeText(BmiCategory cat) => switch (cat) {
        BmiCategory.normal => const Color(0xFF1B5E20),
        BmiCategory.underweight => const Color(0xFF4A148C),
        BmiCategory.overweight => const Color(0xFFE65100),
        BmiCategory.obese => const Color(0xFFB71C1C),
      };

  String _goalShort(String goal) => switch (goal) {
        'lose_weight' => 'Lose\nWeight',
        'gain_weight' => 'Gain\nWeight',
        'build_strength' => 'Build\nStrength',
        'improve' => 'Improve\nFitness',
        _ => 'Maintain\nWeight',
      };

  String _activityShort(String act) => switch (act) {
        'sedentary' => 'Sedentary',
        'lightly_active' => 'Lightly Active',
        'moderately_active' => 'Moderately Active',
        'very_active' => 'Very Active',
        _ => 'Active',
      };
}

class _QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String route;

  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.route,
  });
}
