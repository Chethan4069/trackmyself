import 'package:drift/drift.dart';
import '../app_database.dart';

part 'purchase_dao.g.dart';

@DriftAccessor(tables: [Purchases])
class PurchaseDao extends DatabaseAccessor<AppDatabase>
    with _$PurchaseDaoMixin {
  PurchaseDao(super.db);

  Future<List<Purchase>> getAllPurchases({int? userId}) {
    return (select(purchases)
          ..where((p) {
            if (userId != null) return p.userId.equals(userId);
            return p.userId.isNull();
          })
          ..orderBy([(p) => OrderingTerm.desc(p.purchaseDate)]))
        .get();
  }

  Stream<List<Purchase>> watchAllPurchases({int? userId}) {
    return (select(purchases)
          ..where((p) {
            if (userId != null) return p.userId.equals(userId);
            return p.userId.isNull();
          })
          ..orderBy([(p) => OrderingTerm.desc(p.purchaseDate)]))
        .watch();
  }

  Stream<List<Purchase>> watchPurchasesByCategory(String category, {int? userId}) {
    return (select(purchases)
          ..where((p) {
            final userMatch = userId != null ? p.userId.equals(userId) : p.userId.isNull();
            return userMatch & p.category.equals(category);
          })
          ..orderBy([(p) => OrderingTerm.desc(p.purchaseDate)]))
        .watch();
  }

  Stream<List<Purchase>> watchExpiringSoon({int days = 30, int? userId}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit = today.add(Duration(days: days));

    return (select(purchases)
          ..where((p) {
            final userMatch = userId != null ? p.userId.equals(userId) : p.userId.isNull();
            return userMatch &
                p.warrantyExpiryDate.isNotNull() &
                p.warrantyExpiryDate.isBiggerOrEqualValue(today) &
                p.warrantyExpiryDate.isSmallerOrEqualValue(limit);
          })
          ..orderBy([(p) => OrderingTerm.asc(p.warrantyExpiryDate)]))
        .watch();
  }

  Future<Purchase?> getPurchaseById(int id) =>
      (select(purchases)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<int> insertPurchase(PurchasesCompanion purchase) =>
      into(purchases).insert(purchase);

  Future<bool> updatePurchase(PurchasesCompanion purchase) =>
      update(purchases).replace(purchase);

  Future<int> deletePurchase(int id) =>
      (delete(purchases)..where((p) => p.id.equals(id))).go();
}
