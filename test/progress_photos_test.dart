import 'package:flutter_test/flutter_test.dart';
import 'package:track_my_self/features/fitness/data/progress_photo_provider.dart';

void main() {
  group('ProgressPhotoRecord Model & Serialization', () {
    test('toJson and fromJson work reversibly', () {
      final now = DateTime(2025, 6, 1);
      final record = ProgressPhotoRecord(
        id: 'photo_test_1',
        userId: 42,
        date: now,
        weightKg: 70.2,
        photoPath: 'assets/images/sample_progress_1.png',
        isAsset: true,
        note: 'Starting journey',
      );

      final json = record.toJson();
      expect(json['id'], 'photo_test_1');
      expect(json['userId'], 42);
      expect(json['weightKg'], 70.2);
      expect(json['isAsset'], isTrue);
      expect(json['note'], 'Starting journey');

      final reconstructed = ProgressPhotoRecord.fromJson(json);
      expect(reconstructed.id, record.id);
      expect(reconstructed.userId, record.userId);
      expect(reconstructed.date, record.date);
      expect(reconstructed.weightKg, record.weightKg);
      expect(reconstructed.isAsset, record.isAsset);
      expect(reconstructed.note, record.note);
    });
  });

  group('ProgressStats Calculations', () {
    test('Calculates exact weight loss delta and formatting', () {
      const stats = ProgressStats(
        startWeight: 70.2,
        latestWeight: 66.4,
        weightChange: -3.8,
        totalPhotos: 4,
      );

      expect(stats.hasLostWeight, isTrue);
      expect(stats.changeFormatted, '↓ -3.8 kg');
      expect(stats.totalPhotos, 4);
    });

    test('Calculates weight gain delta formatting', () {
      const stats = ProgressStats(
        startWeight: 65.0,
        latestWeight: 67.5,
        weightChange: 2.5,
        totalPhotos: 3,
      );

      expect(stats.hasLostWeight, isFalse);
      expect(stats.changeFormatted, '↑ +2.5 kg');
    });

    test('Zero weight change formatting', () {
      const stats = ProgressStats(
        startWeight: 70.0,
        latestWeight: 70.0,
        weightChange: 0.0,
        totalPhotos: 2,
      );

      expect(stats.changeFormatted, '0.0 kg');
    });
  });

  group('ComparePair Swapping', () {
    test('Pair swap inverts before and after items', () {
      final p1 = ProgressPhotoRecord(
        id: 'p1',
        date: DateTime(2025, 6, 1),
        weightKg: 70.2,
        photoPath: 'path1',
      );
      final p2 = ProgressPhotoRecord(
        id: 'p2',
        date: DateTime(2025, 9, 12),
        weightKg: 66.4,
        photoPath: 'path2',
      );

      final pair = ComparePair(before: p1, after: p2);
      expect(pair.before.id, 'p1');
      expect(pair.after.id, 'p2');

      final swapped = ComparePair(before: pair.after, after: pair.before);
      expect(swapped.before.id, 'p2');
      expect(swapped.after.id, 'p1');
    });
  });
}
