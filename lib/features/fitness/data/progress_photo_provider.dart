import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../auth/data/auth_provider.dart';

class ProgressPhotoRecord {
  final String id;
  final int? userId;
  final DateTime date;
  final double weightKg;
  final String photoPath;
  final bool isAsset;
  final String? note;

  const ProgressPhotoRecord({
    required this.id,
    this.userId,
    required this.date,
    required this.weightKg,
    required this.photoPath,
    this.isAsset = false,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'photoPath': photoPath,
        'isAsset': isAsset,
        'note': note,
      };

  factory ProgressPhotoRecord.fromJson(Map<String, dynamic> json) =>
      ProgressPhotoRecord(
        id: json['id'] as String,
        userId: json['userId'] as int?,
        date: DateTime.parse(json['date'] as String),
        weightKg: (json['weightKg'] as num).toDouble(),
        photoPath: json['photoPath'] as String,
        isAsset: json['isAsset'] as bool? ?? false,
        note: json['note'] as String?,
      );
}

// ── Default Demo Photos ──────────────────────────────────────────────────────
final List<ProgressPhotoRecord> _defaultDemoPhotos = [
  ProgressPhotoRecord(
    id: 'demo_1',
    date: DateTime(2025, 6, 1),
    weightKg: 70.2,
    photoPath: 'assets/images/sample_progress_1.png',
    isAsset: true,
  ),
  ProgressPhotoRecord(
    id: 'demo_2',
    date: DateTime(2025, 6, 15),
    weightKg: 69.1,
    photoPath: 'assets/images/sample_progress_2.png',
    isAsset: true,
  ),
  ProgressPhotoRecord(
    id: 'demo_3',
    date: DateTime(2025, 8, 1),
    weightKg: 67.8,
    photoPath: 'assets/images/sample_progress_3.png',
    isAsset: true,
  ),
  ProgressPhotoRecord(
    id: 'demo_4',
    date: DateTime(2025, 9, 12),
    weightKg: 66.4,
    photoPath: 'assets/images/sample_progress_4.png',
    isAsset: true,
  ),
];

// ── Sort & Filter State ──────────────────────────────────────────────────────
enum ProgressSortOrder { newestFirst, oldestFirst }

class ProgressSortOrderNotifier extends Notifier<ProgressSortOrder> {
  @override
  ProgressSortOrder build() => ProgressSortOrder.newestFirst;

  void toggle() {
    state = state == ProgressSortOrder.newestFirst
        ? ProgressSortOrder.oldestFirst
        : ProgressSortOrder.newestFirst;
  }
}

final progressSortOrderProvider =
    NotifierProvider<ProgressSortOrderNotifier, ProgressSortOrder>(
  ProgressSortOrderNotifier.new,
);

class ProgressTabNotifier extends Notifier<int> {
  @override
  int build() => 0; // 0: Photos, 1: Comparison, 2: Stats

  void setTab(int index) => state = index;
}

final progressTabProvider =
    NotifierProvider<ProgressTabNotifier, int>(ProgressTabNotifier.new);

// ── Photo Storage & Controller ───────────────────────────────────────────────
class ProgressPhotosNotifier extends AsyncNotifier<List<ProgressPhotoRecord>> {
  @override
  Future<List<ProgressPhotoRecord>> build() async {
    final user = ref.watch(authStateProvider);
    final userId = user?.id;

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'progress_photos_${userId ?? 0}.json'));

    if (!await file.exists()) {
      // First time initialization with demo photos
      return _defaultDemoPhotos;
    }

    try {
      final content = await file.readAsString();
      final List<dynamic> list = jsonDecode(content);
      final items = list.map((e) => ProgressPhotoRecord.fromJson(e as Map<String, dynamic>)).toList();
      return items.isEmpty ? _defaultDemoPhotos : items;
    } catch (_) {
      return _defaultDemoPhotos;
    }
  }

  Future<void> _persist(List<ProgressPhotoRecord> items) async {
    final user = ref.read(authStateProvider);
    final userId = user?.id;
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'progress_photos_${userId ?? 0}.json'));
    final jsonStr = jsonEncode(items.map((e) => e.toJson()).toList());
    await file.writeAsString(jsonStr);
  }

  Future<void> addPhoto({
    required DateTime date,
    required double weightKg,
    required String sourcePath,
    String? note,
  }) async {
    final user = ref.read(authStateProvider);
    final userId = user?.id;

    // Copy to persistent documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final ext = p.extension(sourcePath).isNotEmpty ? p.extension(sourcePath) : '.jpg';
    final fileName = 'progress_${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedFile = await File(sourcePath).copy(p.join(appDir.path, fileName));

    final newRecord = ProgressPhotoRecord(
      id: 'photo_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      date: date,
      weightKg: weightKg,
      photoPath: savedFile.path,
      isAsset: false,
      note: note,
    );

    final current = state.value ?? [];
    final updated = [...current, newRecord];
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> deletePhoto(String id) async {
    final current = state.value ?? [];
    final item = current.firstWhere((e) => e.id == id, orElse: () => current.first);
    if (!item.isAsset) {
      try {
        final f = File(item.photoPath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    final updated = current.where((e) => e.id != id).toList();
    state = AsyncData(updated);
    await _persist(updated);
  }
}

final progressPhotosProvider =
    AsyncNotifierProvider<ProgressPhotosNotifier, List<ProgressPhotoRecord>>(
  ProgressPhotosNotifier.new,
);

// ── Sorted Progress Photos ───────────────────────────────────────────────────
final sortedProgressPhotosProvider = Provider<List<ProgressPhotoRecord>>((ref) {
  final photosAsync = ref.watch(progressPhotosProvider);
  final sortOrder = ref.watch(progressSortOrderProvider);
  final photos = List<ProgressPhotoRecord>.from(photosAsync.value ?? []);

  photos.sort((a, b) => sortOrder == ProgressSortOrder.newestFirst
      ? b.date.compareTo(a.date)
      : a.date.compareTo(b.date));

  return photos;
});

// ── Progress Stats Computation ───────────────────────────────────────────────
class ProgressStats {
  final double startWeight;
  final double latestWeight;
  final double weightChange;
  final DateTime? startDate;
  final DateTime? latestDate;
  final int totalPhotos;

  const ProgressStats({
    required this.startWeight,
    required this.latestWeight,
    required this.weightChange,
    this.startDate,
    this.latestDate,
    required this.totalPhotos,
  });

  bool get hasLostWeight => weightChange < 0;
  String get changeFormatted {
    final abs = weightChange.abs().toStringAsFixed(1);
    if (weightChange < 0) return '↓ -$abs kg';
    if (weightChange > 0) return '↑ +$abs kg';
    return '0.0 kg';
  }
}

final progressStatsProvider = Provider<ProgressStats>((ref) {
  final photosAsync = ref.watch(progressPhotosProvider);
  final photos = List<ProgressPhotoRecord>.from(photosAsync.value ?? []);

  if (photos.isEmpty) {
    return const ProgressStats(
      startWeight: 0,
      latestWeight: 0,
      weightChange: 0,
      totalPhotos: 0,
    );
  }

  // Sort chronological for calculations
  photos.sort((a, b) => a.date.compareTo(b.date));
  final start = photos.first;
  final latest = photos.last;
  final delta = latest.weightKg - start.weightKg;

  return ProgressStats(
    startWeight: start.weightKg,
    latestWeight: latest.weightKg,
    weightChange: delta,
    startDate: start.date,
    latestDate: latest.date,
    totalPhotos: photos.length,
  );
});

// ── Compare Pair Provider ────────────────────────────────────────────────────
class ComparePair {
  final ProgressPhotoRecord before;
  final ProgressPhotoRecord after;

  const ComparePair({required this.before, required this.after});
}

class ComparePairNotifier extends Notifier<ComparePair?> {
  @override
  ComparePair? build() {
    final photosAsync = ref.watch(progressPhotosProvider);
    final photos = List<ProgressPhotoRecord>.from(photosAsync.value ?? []);
    if (photos.length < 2) {
      if (photos.length == 1) return ComparePair(before: photos.first, after: photos.first);
      return null;
    }
    photos.sort((a, b) => a.date.compareTo(b.date));
    return ComparePair(before: photos.first, after: photos.last);
  }

  void setPair(ProgressPhotoRecord before, ProgressPhotoRecord after) {
    state = ComparePair(before: before, after: after);
  }

  void swap() {
    if (state != null) {
      state = ComparePair(before: state!.after, after: state!.before);
    }
  }
}

final comparePairProvider =
    NotifierProvider<ComparePairNotifier, ComparePair?>(ComparePairNotifier.new);
