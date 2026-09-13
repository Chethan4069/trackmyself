import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../data/memory_provider.dart';

class AddPurchaseScreen extends ConsumerStatefulWidget {
  const AddPurchaseScreen({super.key, this.purchase});

  final Purchase? purchase;

  @override
  ConsumerState<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends ConsumerState<AddPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _storeController;
  late final TextEditingController _notesController;
  late final TextEditingController _customWarrantyController;

  late String _category;
  late DateTime _purchaseDate;
  late bool _hasWarranty;
  int? _warrantyMonths;
  DateTime? _warrantyExpiryDate;
  bool _scheduleReminder = true;
  String? _receiptPath;
  bool _isSaving = false;

  final _picker = ImagePicker();

  static const _categories = [
    ('electronics', 'Electronics', Icons.devices),
    ('appliances', 'Appliances', Icons.kitchen),
    ('clothing', 'Clothing', Icons.checkroom),
    ('books', 'Books', Icons.menu_book),
    ('other', 'Other', Icons.category),
  ];

  static const _quickWarrantyDurations = [
    (6, '6 Mos'),
    (12, '1 Year'),
    (24, '2 Years'),
    (36, '3 Years'),
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.purchase;
    _nameController = TextEditingController(text: p?.productName ?? '');
    _priceController =
        TextEditingController(text: p != null ? p.price.toStringAsFixed(2) : '');
    _storeController = TextEditingController(text: p?.store ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');

    _category = p?.category ?? 'electronics';
    _purchaseDate = p?.purchaseDate ?? DateTime.now();
    _hasWarranty = p?.warrantyExpiryDate != null || (p?.warrantyDurationMonths ?? 0) > 0;
    _warrantyMonths = p?.warrantyDurationMonths;
    _warrantyExpiryDate = p?.warrantyExpiryDate;
    _receiptPath = p?.receiptPath;

    _customWarrantyController = TextEditingController(
      text: _warrantyMonths != null ? _warrantyMonths.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _storeController.dispose();
    _notesController.dispose();
    _customWarrantyController.dispose();
    super.dispose();
  }

  void _recalculateExpiry() {
    if (!_hasWarranty || _warrantyMonths == null || _warrantyMonths! <= 0) {
      _warrantyExpiryDate = null;
    } else {
      final d = _purchaseDate;
      _warrantyExpiryDate = DateTime(
        d.year,
        d.month + _warrantyMonths!,
        d.day,
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked != null) {
        setState(() => _receiptPath = picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not attach photo: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final price = double.parse(_priceController.text.trim());
      String? savedReceiptPath = _receiptPath;

      // If a new temp image was picked, save it to app documents directory
      if (_receiptPath != null && !_receiptPath!.contains('receipt_')) {
        final controller = ref.read(purchaseControllerProvider);
        savedReceiptPath = await controller.saveReceiptFile(_receiptPath!);
      }

      final controller = ref.read(purchaseControllerProvider);
      await controller.savePurchase(
        id: widget.purchase?.id,
        productName: _nameController.text.trim(),
        category: _category,
        price: price,
        purchaseDate: _purchaseDate,
        store: _storeController.text.trim().isNotEmpty
            ? _storeController.text.trim()
            : null,
        warrantyDurationMonths: _hasWarranty ? _warrantyMonths : null,
        warrantyExpiryDate: _hasWarranty ? _warrantyExpiryDate : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        receiptPath: savedReceiptPath,
        scheduleReminder: _hasWarranty && _scheduleReminder,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving purchase: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEditing = widget.purchase != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Purchase' : 'Add Purchase'),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              tooltip: 'Delete Purchase',
              onPressed: () async {
                final confirmed = await showConfirmationDialog(
                  context: context,
                  title: 'Delete Purchase?',
                  message: 'Are you sure you want to remove "${widget.purchase!.productName}"?',
                  confirmLabel: 'Delete',
                  isDestructive: true,
                );
                if (confirmed == true && mounted) {
                  await ref
                      .read(purchaseControllerProvider)
                      .deletePurchase(widget.purchase!.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
      body: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Product Name
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Product Name *',
                hintText: 'e.g. MacBook Pro, Air Fryer, Running Shoes',
                prefixIcon: const Icon(Icons.shopping_bag_outlined),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter a product name' : null,
            ),
            const SizedBox(height: 16),

            // Category Selector
            Text('Category', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((c) {
                  final isSelected = _category == c.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(c.$3, size: 18, color: isSelected ? cs.onPrimary : cs.primary),
                      label: Text(c.$2),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _category = c.$1),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Price & Store row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Price *',
                      prefixText: '\$ ',
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter price';
                      final n = double.tryParse(v.trim());
                      if (n == null || n < 0) return 'Invalid price';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _storeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Store / Retailer',
                      hintText: 'e.g. Amazon, BestBuy',
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Purchase Date
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outlineVariant),
              ),
              leading: Icon(Icons.calendar_today_outlined, color: cs.primary),
              title: const Text('Purchase Date'),
              subtitle: Text(DateFormat('dd MMMM yyyy').format(_purchaseDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _purchaseDate,
                  firstDate: DateTime(2010),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _purchaseDate = picked;
                    _recalculateExpiry();
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // ── Warranty Card ──────────────────────────────────────────────
            Card(
              elevation: 0,
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
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
                        Icon(Icons.verified_user_outlined, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Warranty Tracking',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _hasWarranty,
                          onChanged: (val) {
                            setState(() {
                              _hasWarranty = val;
                              if (val && _warrantyMonths == null) {
                                _warrantyMonths = 12; // default 1 year
                              }
                              _recalculateExpiry();
                            });
                          },
                        ),
                      ],
                    ),
                    if (_hasWarranty) ...[
                      const Divider(height: 24),
                      Text('Duration', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: _quickWarrantyDurations.map((d) {
                          final isSelected = _warrantyMonths == d.$1;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(d.$2),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _warrantyMonths = d.$1;
                                  _customWarrantyController.text = d.$1.toString();
                                  _recalculateExpiry();
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Custom months input
                      TextFormField(
                        controller: _customWarrantyController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Custom Duration (Months)',
                          suffixText: 'Months',
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (val) {
                          final months = int.tryParse(val.trim());
                          setState(() {
                            _warrantyMonths = months;
                            _recalculateExpiry();
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      if (_warrantyExpiryDate != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event_available, color: cs.onPrimaryContainer, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Warranty Expiry: ${DateFormat('dd MMMM yyyy').format(_warrantyExpiryDate!)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Remind 7 days before expiration'),
                          value: _scheduleReminder,
                          onChanged: (v) => setState(() => _scheduleReminder = v ?? true),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Receipt Photo Section ───────────────────────────────────────
            Card(
              elevation: 0,
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
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
                        Icon(Icons.receipt_long_outlined, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Receipt / Proof of Purchase',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_receiptPath != null && File(_receiptPath!).existsSync()) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_receiptPath!),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.white),
                                onPressed: () => setState(() => _receiptPath = null),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: const Text('Take Photo'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Gallery'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Serial number, return policy, warranty terms...',
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isEditing ? 'Update Purchase' : 'Save Purchase',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
