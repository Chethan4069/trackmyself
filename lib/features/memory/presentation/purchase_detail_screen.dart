import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../data/memory_provider.dart';
import '../domain/warranty_calculator.dart';
import 'add_purchase_screen.dart';

class PurchaseDetailScreen extends ConsumerWidget {
  const PurchaseDetailScreen({super.key, required this.purchase});

  final Purchase purchase;

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
    final warranty = WarrantyInfo.compute(purchase.warrantyExpiryDate);

    final hasReceipt =
        purchase.receiptPath != null && File(purchase.receiptPath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(purchase.productName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddPurchaseScreen(purchase: purchase),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error),
            tooltip: 'Delete',
            onPressed: () async {
              final confirmed = await showConfirmationDialog(
                context: context,
                title: 'Delete Purchase?',
                message: 'Delete "${purchase.productName}" and remove its warranty reminder?',
                confirmLabel: 'Delete',
                isDestructive: true,
              );
              if (confirmed == true && context.mounted) {
                await ref.read(purchaseControllerProvider).deletePurchase(purchase.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Card with Price & Category
          Card(
            elevation: 0,
            color: cs.primaryContainer.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: cs.primary,
                    child: Icon(_categoryIcon(purchase.category), color: cs.onPrimary, size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    purchase.productName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${purchase.price.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
                  ),
                  if (purchase.store != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Purchased at ${purchase.store}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                  Text(
                    'Date: ${DateFormat('dd MMMM yyyy').format(purchase.purchaseDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Warranty Card ──────────────────────────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: warranty.status == WarrantyStatus.valid
                            ? Colors.green
                            : warranty.status == WarrantyStatus.expiringSoon
                                ? Colors.orange
                                : cs.outline,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Warranty Status',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      _WarrantyPill(info: warranty),
                    ],
                  ),
                  if (purchase.warrantyExpiryDate != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Expires: ${DateFormat('dd MMMM yyyy').format(purchase.warrantyExpiryDate!)}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (purchase.warrantyDurationMonths != null)
                      Text(
                        'Duration: ${purchase.warrantyDurationMonths} Months',
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Receipt Proof ──────────────────────────────────────────────
          if (hasReceipt) ...[
            Text('Receipt Photo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onTap: () {
                  // View full receipt
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(10),
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(purchase.receiptPath!)),
                        ),
                      ),
                    ),
                  );
                },
                child: Image.file(
                  File(purchase.receiptPath!),
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap receipt image to zoom & inspect details',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],

          // Notes
          if (purchase.notes != null && purchase.notes!.isNotEmpty) ...[
            Text('Notes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text(purchase.notes!, style: theme.textTheme.bodyMedium),
            ),
          ],
        ],
      ),
    );
  }
}

class _WarrantyPill extends StatelessWidget {
  const _WarrantyPill({required this.info});
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
