import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../../auth/data/auth_provider.dart';
import '../domain/warranty_calculator.dart';

// ─── DAO Provider ─────────────────────────────────────────────────────────────

final purchaseDaoProvider = Provider<PurchaseDao>((ref) {
  return ref.watch(databaseProvider).purchaseDao;
});

// ─── Category Filter ─────────────────────────────────────────────────────────

class SelectedPurchaseCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void select(String category) => state = category;
}

final selectedPurchaseCategoryProvider =
    NotifierProvider<SelectedPurchaseCategoryNotifier, String>(
  SelectedPurchaseCategoryNotifier.new,
);

// ─── Search Query ────────────────────────────────────────────────────────────

class PurchaseSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final purchaseSearchQueryProvider =
    NotifierProvider<PurchaseSearchQueryNotifier, String>(
  PurchaseSearchQueryNotifier.new,
);

// ─── All Purchases Stream ────────────────────────────────────────────────────

final allPurchasesStreamProvider = StreamProvider<List<Purchase>>((ref) {
  final dao = ref.watch(purchaseDaoProvider);
  final user = ref.watch(authStateProvider);
  return dao.watchAllPurchases(userId: user?.id);
});

// ─── Expiring Warranties Stream ──────────────────────────────────────────────

final expiringWarrantiesStreamProvider = StreamProvider<List<Purchase>>((ref) {
  final dao = ref.watch(purchaseDaoProvider);
  final user = ref.watch(authStateProvider);
  return dao.watchExpiringSoon(days: 30, userId: user?.id);
});

// ─── Filtered Purchases Provider ─────────────────────────────────────────────

final filteredPurchasesProvider = Provider<AsyncValue<List<Purchase>>>((ref) {
  final purchasesAsync = ref.watch(allPurchasesStreamProvider);
  final category = ref.watch(selectedPurchaseCategoryProvider);
  final query = ref.watch(purchaseSearchQueryProvider).trim().toLowerCase();

  return purchasesAsync.whenData((purchases) {
    var result = purchases;

    if (category != 'all') {
      result = result.where((p) => p.category == category).toList();
    }

    if (query.isNotEmpty) {
      result = result.where((p) {
        final matchesName = p.productName.toLowerCase().contains(query);
        final matchesStore = p.store?.toLowerCase().contains(query) ?? false;
        return matchesName || matchesStore;
      }).toList();
    }

    return result;
  });
});

// ─── Summary Statistics ──────────────────────────────────────────────────────

class MemoryStats {
  final double totalSpent;
  final int totalCount;
  final int activeWarranties;
  final int expiringSoon;

  const MemoryStats({
    required this.totalSpent,
    required this.totalCount,
    required this.activeWarranties,
    required this.expiringSoon,
  });

  static const zero = MemoryStats(
    totalSpent: 0,
    totalCount: 0,
    activeWarranties: 0,
    expiringSoon: 0,
  );
}

final memoryStatsProvider = Provider<MemoryStats>((ref) {
  final purchasesAsync = ref.watch(allPurchasesStreamProvider);
  final purchases = purchasesAsync.value ?? [];

  if (purchases.isEmpty) return MemoryStats.zero;

  double spent = 0;
  int active = 0;
  int expiring = 0;

  for (final p in purchases) {
    spent += p.price;
    final info = WarrantyInfo.compute(p.warrantyExpiryDate);
    if (info.status == WarrantyStatus.valid) active++;
    if (info.status == WarrantyStatus.expiringSoon) {
      active++;
      expiring++;
    }
  }

  return MemoryStats(
    totalSpent: spent,
    totalCount: purchases.length,
    activeWarranties: active,
    expiringSoon: expiring,
  );
});

// ─── Purchase Controller ─────────────────────────────────────────────────────

final purchaseControllerProvider = Provider<PurchaseController>((ref) {
  final dao = ref.watch(purchaseDaoProvider);
  final user = ref.watch(authStateProvider);
  return PurchaseController(dao, user?.id);
});

class PurchaseController {
  final PurchaseDao _dao;
  final int? _userId;

  PurchaseController(this._dao, [this._userId]);

  Future<String> saveReceiptFile(String tempPath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final ext = p.extension(tempPath);
    final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}$ext';
    final targetPath = p.join(docsDir.path, fileName);
    await File(tempPath).copy(targetPath);
    return targetPath;
  }

  Future<int> savePurchase({
    int? id,
    required String productName,
    required String category,
    required double price,
    required DateTime purchaseDate,
    String? store,
    int? warrantyDurationMonths,
    DateTime? warrantyExpiryDate,
    String? notes,
    String? receiptPath,
    bool scheduleReminder = true,
  }) async {
    if (id == null) {
      final newId = await _dao.insertPurchase(
        PurchasesCompanion.insert(
          userId: Value(_userId),
          productName: productName.trim(),
          category: category,
          price: price,
          purchaseDate: purchaseDate,
          store: Value(store?.trim()),
          warrantyDurationMonths: Value(warrantyDurationMonths),
          warrantyExpiryDate: Value(warrantyExpiryDate),
          notes: Value(notes?.trim()),
          receiptPath: Value(receiptPath),
          createdAt: Value(DateTime.now()),
        ),
      );

      if (scheduleReminder && warrantyExpiryDate != null) {
        await NotificationService.instance.scheduleWarrantyReminder(
          id: newId,
          productName: productName.trim(),
          expiryDate: warrantyExpiryDate,
          daysBefore: 7,
        );
      }

      return newId;
    } else {
      final existing = await _dao.getPurchaseById(id);
      if (existing != null) {
        await _dao.updatePurchase(
          PurchasesCompanion(
            id: Value(id),
            userId: Value(existing.userId ?? _userId),
            productName: Value(productName.trim()),
            category: Value(category),
            price: Value(price),
            purchaseDate: Value(purchaseDate),
            store: Value(store?.trim()),
            warrantyDurationMonths: Value(warrantyDurationMonths),
            warrantyExpiryDate: Value(warrantyExpiryDate),
            notes: Value(notes?.trim()),
            receiptPath: Value(receiptPath ?? existing.receiptPath),
            createdAt: Value(existing.createdAt),
            updatedAt: Value(DateTime.now()),
          ),
        );

        if (scheduleReminder && warrantyExpiryDate != null) {
          await NotificationService.instance.scheduleWarrantyReminder(
            id: id,
            productName: productName.trim(),
            expiryDate: warrantyExpiryDate,
            daysBefore: 7,
          );
        } else {
          await NotificationService.instance.cancelWarrantyReminder(id);
        }
      }
      return id;
    }
  }

  Future<void> deletePurchase(int id) async {
    final existing = await _dao.getPurchaseById(id);
    if (existing != null && existing.receiptPath != null) {
      try {
        final file = File(existing.receiptPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Silently ignore receipt delete failure
      }
    }
    await NotificationService.instance.cancelWarrantyReminder(id);
    await _dao.deletePurchase(id);
  }
}
