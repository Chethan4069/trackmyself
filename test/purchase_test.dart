import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:track_my_self/core/database/app_database.dart';
import 'package:track_my_self/features/memory/domain/warranty_calculator.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  group('Warranty Calculator Domain Tests', () {
    test('Null expiry date returns status none', () {
      final info = WarrantyInfo.compute(null);
      expect(info.status, WarrantyStatus.none);
      expect(info.daysRemaining, 0);
      expect(info.label, 'No Warranty');
    });

    test('Past date returns status expired with negative days', () {
      final now = DateTime.now();
      final expiredDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 10));
      final info = WarrantyInfo.compute(expiredDate);

      expect(info.status, WarrantyStatus.expired);
      expect(info.daysRemaining, -10);
      expect(info.label, 'Expired');
    });

    test('Date within 30 days returns expiringSoon', () {
      final now = DateTime.now();
      final expiringDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 15));
      final info = WarrantyInfo.compute(expiringDate);

      expect(info.status, WarrantyStatus.expiringSoon);
      expect(info.daysRemaining, 15);
      expect(info.label, '15 days left');
    });

    test('Date exactly 30 days away returns expiringSoon', () {
      final now = DateTime.now();
      final expiringDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 30));
      final info = WarrantyInfo.compute(expiringDate);

      expect(info.status, WarrantyStatus.expiringSoon);
      expect(info.daysRemaining, 30);
      expect(info.label, '30 days left');
    });

    test('Date more than 30 days away returns valid', () {
      final now = DateTime.now();
      final validDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 180));
      final info = WarrantyInfo.compute(validDate);

      expect(info.status, WarrantyStatus.valid);
      expect(info.daysRemaining, 180);
      expect(info.label, contains('left'));
    });
  });

  group('Purchase DAO & Multi-User Isolation Tests', () {
    late AppDatabase db;
    late int aliceId;
    late int bobId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      aliceId = await db.authDao.createUser('alice_p6@example.com', 'hash_alice');
      bobId = await db.authDao.createUser('bob_p6@example.com', 'hash_bob');
    });

    tearDown(() async {
      await db.close();
    });

    test('Purchases are strictly isolated between users', () async {
      final now = DateTime.now();
      final purchaseDate = DateTime(now.year, now.month, now.day);
      final expiryDate = purchaseDate.add(const Duration(days: 365));

      // Alice adds a Laptop
      final alicePurchaseId = await db.purchaseDao.insertPurchase(
        PurchasesCompanion.insert(
          userId: drift.Value(aliceId),
          productName: 'MacBook Pro 14"',
          category: 'electronics',
          price: 1999.99,
          purchaseDate: purchaseDate,
          warrantyExpiryDate: drift.Value(expiryDate),
          store: const drift.Value('Apple Store'),
        ),
      );

      // Bob adds Running Shoes
      await db.purchaseDao.insertPurchase(
        PurchasesCompanion.insert(
          userId: drift.Value(bobId),
          productName: 'Nike Air Zoom',
          category: 'fitness',
          price: 130.00,
          purchaseDate: purchaseDate,
        ),
      );

      // Alice only sees MacBook
      final alicePurchases = await db.purchaseDao.getAllPurchases(userId: aliceId);
      expect(alicePurchases.length, 1);
      expect(alicePurchases.first.productName, 'MacBook Pro 14"');
      expect(alicePurchases.first.price, 1999.99);

      // Bob only sees Nike Shoes
      final bobPurchases = await db.purchaseDao.getAllPurchases(userId: bobId);
      expect(bobPurchases.length, 1);
      expect(bobPurchases.first.productName, 'Nike Air Zoom');
      expect(bobPurchases.first.price, 130.00);

      // Fetch by ID
      final item = await db.purchaseDao.getPurchaseById(alicePurchaseId);
      expect(item, isNotNull);
      expect(item!.userId, aliceId);
    });

    test('Expiring soon query returns only items within window for user', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Item 1: Expiring in 10 days (should be in expiring soon)
      await db.purchaseDao.insertPurchase(
        PurchasesCompanion.insert(
          userId: drift.Value(aliceId),
          productName: 'Bluetooth Headphones',
          category: 'electronics',
          price: 89.99,
          purchaseDate: today.subtract(const Duration(days: 355)),
          warrantyExpiryDate: drift.Value(today.add(const Duration(days: 10))),
        ),
      );

      // Item 2: Expiring in 90 days (should NOT be in expiring soon)
      await db.purchaseDao.insertPurchase(
        PurchasesCompanion.insert(
          userId: drift.Value(aliceId),
          productName: 'Smart Watch',
          category: 'electronics',
          price: 249.99,
          purchaseDate: today.subtract(const Duration(days: 275)),
          warrantyExpiryDate: drift.Value(today.add(const Duration(days: 90))),
        ),
      );

      // Bob also has an expiring item
      await db.purchaseDao.insertPurchase(
        PurchasesCompanion.insert(
          userId: drift.Value(bobId),
          productName: 'Gaming Mouse',
          category: 'electronics',
          price: 59.99,
          purchaseDate: today.subtract(const Duration(days: 350)),
          warrantyExpiryDate: drift.Value(today.add(const Duration(days: 15))),
        ),
      );

      // Stream test for Alice expiring items
      final aliceExpiring = await db.purchaseDao.watchExpiringSoon(userId: aliceId).first;
      expect(aliceExpiring.length, 1);
      expect(aliceExpiring.first.productName, 'Bluetooth Headphones');

      // Stream test for Bob expiring items
      final bobExpiring = await db.purchaseDao.watchExpiringSoon(userId: bobId).first;
      expect(bobExpiring.length, 1);
      expect(bobExpiring.first.productName, 'Gaming Mouse');
    });

    test('Updating and deleting purchases', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final id = await db.purchaseDao.insertPurchase(
        PurchasesCompanion.insert(
          userId: drift.Value(aliceId),
          productName: 'Coffee Maker',
          category: 'home',
          price: 79.99,
          purchaseDate: today,
        ),
      );

      // Update price and name
      await db.purchaseDao.updatePurchase(
        PurchasesCompanion(
          id: drift.Value(id),
          userId: drift.Value(aliceId),
          productName: const drift.Value('Deluxe Espresso Machine'),
          category: const drift.Value('home'),
          price: const drift.Value(149.99),
          purchaseDate: drift.Value(today),
        ),
      );

      final updated = await db.purchaseDao.getPurchaseById(id);
      expect(updated!.productName, 'Deluxe Espresso Machine');
      expect(updated.price, 149.99);

      // Delete
      final deletedCount = await db.purchaseDao.deletePurchase(id);
      expect(deletedCount, 1);

      final postDelete = await db.purchaseDao.getPurchaseById(id);
      expect(postDelete, isNull);
    });
  });
}
