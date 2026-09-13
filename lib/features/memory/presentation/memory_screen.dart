import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/memory_provider.dart';
import '../domain/warranty_calculator.dart';
import 'add_purchase_screen.dart';
import 'purchase_detail_screen.dart';

class MemoryScreen extends ConsumerWidget {
  const MemoryScreen({super.key});

  static const _categories = [
    ('all', 'All', Icons.apps),
    ('electronics', 'Electronics', Icons.devices),
    ('appliances', 'Appliances', Icons.kitchen),
    ('clothing', 'Clothing', Icons.checkroom),
    ('books', 'Books', Icons.menu_book),
    ('other', 'Other', Icons.category),
  ];

  IconData _categoryIcon(String category) => switch (category) {
        'electronics' => Icons.devices,
        'appliances' => Icons.kitchen,
        'clothing' => Icons.checkroom,
        'books' => Icons.menu_book,
        _ => Icons.category,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final stats = ref.watch(memoryStatsProvider);
    final selectedCategory = ref.watch(selectedPurchaseCategoryProvider);
    final purchasesAsync = ref.watch(filteredPurchasesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory & Purchases'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Overview Summary Cards ──────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Card(
                          elevation: 0,
                          color: cs.primaryContainer.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: cs.outlineVariant),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Spent',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${stats.totalSpent.toStringAsFixed(2)}',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${stats.totalCount} ${stats.totalCount == 1 ? 'item' : 'items'} tracked',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Card(
                          elevation: 0,
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: cs.outlineVariant),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Warranties',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${stats.activeWarranties}',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Active protection',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Expiring Soon Warning Banner ─────────────────────────
                  if (stats.expiringSoon > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${stats.expiringSoon} ${stats.expiringSoon == 1 ? 'warranty' : 'warranties'} expiring within 30 days!',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // ── Search Field ─────────────────────────────────────────
                  TextField(
                    onChanged: (v) =>
                        ref.read(purchaseSearchQueryProvider.notifier).update(v),
                    decoration: InputDecoration(
                      hintText: 'Search purchases or stores...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Category Filter Chips ────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((c) {
                        final isSelected = selectedCategory == c.$1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: Icon(
                              c.$3,
                              size: 16,
                              color: isSelected ? cs.onPrimary : cs.primary,
                            ),
                            label: Text(c.$2),
                            selected: isSelected,
                            onSelected: (_) => ref
                                .read(selectedPurchaseCategoryProvider.notifier)
                                .select(c.$1),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Purchases List ───────────────────────────────────────────────
          purchasesAsync.when(
            data: (purchases) {
              if (purchases.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No Purchases Found',
                    message:
                        'Keep track of warranties, price tags, and receipts.\nTap + below to add your first item.',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = purchases[index];
                      final warranty = WarrantyInfo.compute(item.warrantyExpiryDate);
                      final hasReceipt = item.receiptPath != null &&
                          File(item.receiptPath!).existsSync();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: cs.outlineVariant),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PurchaseDetailScreen(purchase: item),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail or category icon
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: hasReceipt
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            File(item.receiptPath!),
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Icon(
                                          _categoryIcon(item.category),
                                          color: cs.primary,
                                        ),
                                ),
                                const SizedBox(width: 12),

                                // Product Title & Subtitle
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.store != null
                                            ? '${item.store} • ${DateFormat('dd MMM yyyy').format(item.purchaseDate)}'
                                            : DateFormat('dd MMM yyyy').format(item.purchaseDate),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      _WarrantyBadge(info: warranty),
                                    ],
                                  ),
                                ),

                                // Price tag & Receipt Indicator
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${item.price.toStringAsFixed(2)}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: cs.primary,
                                      ),
                                    ),
                                    if (hasReceipt) ...[
                                      const SizedBox(height: 4),
                                      Icon(
                                        Icons.receipt_long,
                                        size: 16,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: purchases.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(child: Text('Error loading purchases: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Purchase'),
        heroTag: 'memory_fab',
      ),
    );
  }
}

class _WarrantyBadge extends StatelessWidget {
  const _WarrantyBadge({required this.info});
  final WarrantyInfo info;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (info.status) {
      case WarrantyStatus.valid:
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade800;
        break;
      case WarrantyStatus.expiringSoon:
        bg = Colors.orange.withValues(alpha: 0.2);
        fg = Colors.orange.shade900;
        break;
      case WarrantyStatus.expired:
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red.shade800;
        break;
      case WarrantyStatus.none:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
