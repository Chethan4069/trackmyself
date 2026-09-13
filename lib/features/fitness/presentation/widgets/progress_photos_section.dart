import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../data/progress_photo_provider.dart';

class ProgressPhotosSection extends ConsumerStatefulWidget {
  const ProgressPhotosSection({super.key});

  @override
  ConsumerState<ProgressPhotosSection> createState() =>
      _ProgressPhotosSectionState();
}

class _ProgressPhotosSectionState extends ConsumerState<ProgressPhotosSection> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentTab = ref.watch(progressTabProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Section Header ───────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress Photos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Same You, Stronger Every Day',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'About Progress Photos',
              icon: Icon(
                Icons.info_outline_rounded,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
                size: 22,
              ),
              onPressed: () => _showInfoDialog(context),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── 2. "Track your journey visually" Banner ────────────────────────
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 778 / 159,
              child: Image.asset(
                'assets/images/progress_banner.png',
                width: double.infinity,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── 3. Filter Segment Pills ─────────────────────────────────────────
        Row(
          children: [
            _buildTabPill(
              label: 'Photos',
              icon: Icons.photo_library_rounded,
              isSelected: currentTab == 0,
              onTap: () => ref.read(progressTabProvider.notifier).setTab(0),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildTabPill(
              label: 'Comparison',
              icon: Icons.compare_rounded,
              isSelected: currentTab == 1,
              onTap: () => ref.read(progressTabProvider.notifier).setTab(1),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildTabPill(
              label: 'Stats',
              icon: Icons.bar_chart_rounded,
              isSelected: currentTab == 2,
              onTap: () => ref.read(progressTabProvider.notifier).setTab(2),
              isDark: isDark,
            ),
          ],
        ),

        const SizedBox(height: 18),

        // ── 4. Main Tab Content ─────────────────────────────────────────────
        if (currentTab == 0) ...[
          _buildPhotosTimeline(context, isDark),
          const SizedBox(height: 18),
          _buildLatestUpdateCard(context, isDark),
          const SizedBox(height: 18),
          _buildComparePreviewSection(context, isDark),
        ] else if (currentTab == 1) ...[
          _buildComparisonTab(context, isDark),
        ] else ...[
          _buildStatsTab(context, isDark),
        ],

        const SizedBox(height: 20),

        // ── 5. Motivational Quote Box ───────────────────────────────────────
        _buildMotivationalQuoteBox(context, isDark),
      ],
    );
  }

  // ── Tab Pill ──────────────────────────────────────────────────────────────
  Widget _buildTabPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeBg = const Color(0xFF2E6B56);
    final inactiveBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final activeText = Colors.white;
    final inactiveText = isDark ? Colors.white70 : const Color(0xFF475569);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? activeBg
                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? activeText : inactiveText),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? activeText : inactiveText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Timeline Section ──────────────────────────────────────────────────────
  Widget _buildPhotosTimeline(BuildContext context, bool isDark) {
    final sortOrder = ref.watch(progressSortOrderProvider);
    final photos = ref.watch(sortedProgressPhotosProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Header + Sort Dropdown
        Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF2E6B56)),
            const SizedBox(width: 8),
            Text(
              'Your Progress Timeline',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () => ref.read(progressSortOrderProvider.notifier).toggle(),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      sortOrder == ProgressSortOrder.newestFirst
                          ? 'Newest First'
                          : 'Oldest First',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Horizontal Timeline Cards List + Add Photo Card
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: photos.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              // First item or last item: let's put Add Photo card at the start or end
              if (i == photos.length) {
                return _buildAddPhotoCard(context, isDark);
              }
              final item = photos[i];
              return _buildPhotoTimelineCard(context, item, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoTimelineCard(
    BuildContext context,
    ProgressPhotoRecord item,
    bool isDark,
  ) {
    final dateStr = DateFormat('dd MMM yyyy').format(item.date);

    return Container(
      width: 125,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo preview
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.isAsset
                      ? Image.asset(item.photoPath, fit: BoxFit.cover)
                      : Image.file(File(item.photoPath), fit: BoxFit.cover),
                  // Tap to view full image
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showFullscreenPhoto(context, item),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Info row: Date + Weight + 3-dots
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${item.weightKg} kg',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
                  ),
                  onSelected: (val) {
                    if (val == 'view') {
                      _showFullscreenPhoto(context, item);
                    } else if (val == 'delete') {
                      _confirmDelete(context, item);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.zoom_in, size: 18),
                          SizedBox(width: 8),
                          Text('View Photo'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── "+ Add Photo" Card ───────────────────────────────────────────────────
  Widget _buildAddPhotoCard(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => _showAddPhotoBottomSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 125,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF132A24) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2E6B56).withValues(alpha: 0.35),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF2E6B56),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Capture your\nprogress',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── "Latest Update" Card ─────────────────────────────────────────────────
  Widget _buildLatestUpdateCard(BuildContext context, bool isDark) {
    final stats = ref.watch(progressStatsProvider);
    final startDateStr = stats.startDate != null
        ? DateFormat('dd MMM yyyy').format(stats.startDate!)
        : 'day 1';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132B25) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1D4D3D) : const Color(0xFFDCFCE7),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, size: 20, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text(
                'Latest Update',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC8E6C9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  stats.changeFormatted,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'since $startDateStr',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "You've made great progress!",
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Keep going, consistency pays off.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // ── "Compare Photos" Preview Section ─────────────────────────────────────
  Widget _buildComparePreviewSection(BuildContext context, bool isDark) {
    final pair = ref.watch(comparePairProvider);

    if (pair == null) return const SizedBox.shrink();

    final beforeDateStr = DateFormat('dd MMM yyyy').format(pair.before.date);
    final afterDateStr = DateFormat('dd MMM yyyy').format(pair.after.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.compare_rounded, size: 20, color: Color(0xFF2E6B56)),
            const SizedBox(width: 8),
            Text(
              'Compare Photos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () => _showSelectDatesDialog(context),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'Select Dates',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E6B56),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2E6B56)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                // Left Photo (Before)
                Expanded(
                  child: _buildComparisonCard(
                    pair.before,
                    beforeDateStr,
                    isDark,
                  ),
                ),
                const SizedBox(width: 10),
                // Right Photo (After)
                Expanded(
                  child: _buildComparisonCard(
                    pair.after,
                    afterDateStr,
                    isDark,
                  ),
                ),
              ],
            ),
            // Center interactive swap badge
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => ref.read(comparePairProvider.notifier).swap(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    size: 20,
                    color: Color(0xFF2E6B56),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonCard(
    ProgressPhotoRecord item,
    String dateStr,
    bool isDark,
  ) {
    return Container(
      height: 175,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            item.isAsset
                ? Image.asset(item.photoPath, fit: BoxFit.cover)
                : Image.file(File(item.photoPath), fit: BoxFit.cover),
            // Date pill badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Comparison Tab View ───────────────────────────────────────────────────
  Widget _buildComparisonTab(BuildContext context, bool isDark) {
    return _buildComparePreviewSection(context, isDark);
  }

  // ── Stats Tab View ────────────────────────────────────────────────────────
  Widget _buildStatsTab(BuildContext context, bool isDark) {
    final stats = ref.watch(progressStatsProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCol('Start Weight', '${stats.startWeight} kg', isDark),
              _buildStatCol('Current Weight', '${stats.latestWeight} kg', isDark),
              _buildStatCol('Total Change', stats.changeFormatted, isDark,
                  color: const Color(0xFF2E7D32)),
              _buildStatCol('Photos Logged', '${stats.totalPhotos}', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String val, bool isDark, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color ?? (isDark ? Colors.white : const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  // ── Motivational Quote Box ────────────────────────────────────────────────
  Widget _buildMotivationalQuoteBox(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132B25) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1D4D3D) : const Color(0xFFDCFCE7),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '“',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2E6B56).withValues(alpha: 0.7),
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A little progress each day adds up to big results.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '”',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2E6B56).withValues(alpha: 0.7),
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 2.5,
            decoration: BoxDecoration(
              color: const Color(0xFF2E6B56).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add Photo Bottom Sheet Modal ──────────────────────────────────────────
  void _showAddPhotoBottomSheet(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    final weightController = TextEditingController();
    String? pickedPath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Capture Progress Photo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),

                    // Image picker choices
                    if (pickedPath != null) ...[
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(pickedPath!),
                            height: 140,
                            width: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.camera_alt_rounded),
                              label: const Text('Camera'),
                              onPressed: () async {
                                final res = await _picker.pickImage(
                                    source: ImageSource.camera, imageQuality: 85);
                                if (res != null) {
                                  setModalState(() => pickedPath = res.path);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.photo_library_rounded),
                              label: const Text('Gallery'),
                              onPressed: () async {
                                final res = await _picker.pickImage(
                                    source: ImageSource.gallery, imageQuality: 85);
                                if (res != null) {
                                  setModalState(() => pickedPath = res.path);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Weight input field
                    TextField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Current Weight (kg)',
                        hintText: 'e.g. 68.5',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Date selector row
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMMM yyyy').format(selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        TextButton(
                          child: const Text('Change Date'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E6B56),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final weight = double.tryParse(weightController.text);
                          if (weight == null || weight <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid weight')),
                            );
                            return;
                          }
                          if (pickedPath == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please choose or take a photo')),
                            );
                            return;
                          }

                          await ref.read(progressPhotosProvider.notifier).addPhoto(
                                date: selectedDate,
                                weightKg: weight,
                                sourcePath: pickedPath!,
                              );

                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Progress photo recorded successfully! 🎉'),
                              ),
                            );
                          }
                        },
                        child: const Text('Save Progress Photo',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Fullscreen Photo Viewer ───────────────────────────────────────────────
  void _showFullscreenPhoto(BuildContext context, ProgressPhotoRecord item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  '${DateFormat('dd MMM yyyy').format(item.date)} · ${item.weightKg} kg',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              InteractiveViewer(
                child: item.isAsset
                    ? Image.asset(item.photoPath, fit: BoxFit.contain)
                    : Image.file(File(item.photoPath), fit: BoxFit.contain),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ── Delete Confirmation Dialog ────────────────────────────────────────────
  void _confirmDelete(BuildContext context, ProgressPhotoRecord item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Progress Photo'),
        content: const Text('Are you sure you want to delete this photo record?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(progressPhotosProvider.notifier).deletePhoto(item.id);
            },
          ),
        ],
      ),
    );
  }

  // ── Select Dates for Comparison Dialog ────────────────────────────────────
  void _showSelectDatesDialog(BuildContext context) {
    final photos = ref.read(sortedProgressPhotosProvider);
    if (photos.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log at least 2 photos to compare.')),
      );
      return;
    }

    ProgressPhotoRecord before = photos.last;
    ProgressPhotoRecord after = photos.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Select Comparison Dates'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Before Photo:', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  DropdownButton<ProgressPhotoRecord>(
                    isExpanded: true,
                    value: before,
                    items: photos.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(
                          '${DateFormat('dd MMM yyyy').format(p.date)} (${p.weightKg} kg)',
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => before = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('After Photo:', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  DropdownButton<ProgressPhotoRecord>(
                    isExpanded: true,
                    value: after,
                    items: photos.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(
                          '${DateFormat('dd MMM yyyy').format(p.date)} (${p.weightKg} kg)',
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => after = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E6B56)),
                  child: const Text('Compare'),
                  onPressed: () {
                    ref.read(comparePairProvider.notifier).setPair(before, after);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Info Dialog ───────────────────────────────────────────────────────────
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.photo_camera_rounded, color: Color(0xFF2E6B56)),
            SizedBox(width: 8),
            Text('Visual Progress'),
          ],
        ),
        content: const Text(
          'Tracking your fitness progress with photos allows you to see body composition changes that the scale alone might not show.\n\nTake consistent photos under similar lighting and angles every 1 to 2 weeks.',
        ),
        actions: [
          FilledButton(
            child: const Text('Got it!'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}
