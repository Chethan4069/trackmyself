enum WarrantyStatus {
  none,
  valid,
  expiringSoon,
  expired,
}

class WarrantyInfo {
  final WarrantyStatus status;
  final int daysRemaining;
  final String label;

  const WarrantyInfo({
    required this.status,
    required this.daysRemaining,
    required this.label,
  });

  static WarrantyInfo compute(DateTime? expiryDate, [DateTime? referenceDate]) {
    if (expiryDate == null) {
      return const WarrantyInfo(
        status: WarrantyStatus.none,
        daysRemaining: 0,
        label: 'No Warranty',
      );
    }

    final today = referenceDate ?? DateTime.now();
    final nowNorm = DateTime(today.year, today.month, today.day);
    final expNorm = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    final diff = expNorm.difference(nowNorm).inDays;

    if (diff < 0) {
      return WarrantyInfo(
        status: WarrantyStatus.expired,
        daysRemaining: diff,
        label: 'Expired',
      );
    } else if (diff == 0) {
      return const WarrantyInfo(
        status: WarrantyStatus.expiringSoon,
        daysRemaining: 0,
        label: 'Expires Today!',
      );
    } else if (diff <= 30) {
      return WarrantyInfo(
        status: WarrantyStatus.expiringSoon,
        daysRemaining: diff,
        label: '$diff ${diff == 1 ? 'day' : 'days'} left',
      );
    } else {
      final months = (diff / 30.4375).floor();
      if (months < 12) {
        return WarrantyInfo(
          status: WarrantyStatus.valid,
          daysRemaining: diff,
          label: '$months ${months == 1 ? 'mo' : 'mos'} left',
        );
      } else {
        final years = (months / 12).floor();
        final remMonths = months % 12;
        final text = remMonths == 0
            ? '$years ${years == 1 ? 'yr' : 'yrs'} left'
            : '$years yr $remMonths mo left';
        return WarrantyInfo(
          status: WarrantyStatus.valid,
          daysRemaining: diff,
          label: text,
        );
      }
    }
  }
}
