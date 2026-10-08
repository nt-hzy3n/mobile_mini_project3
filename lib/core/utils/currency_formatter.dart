import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static final NumberFormat _numberFormat = NumberFormat('#,###', 'vi_VN');

  /// Format số tiền chuẩn Việt Nam: ví dụ `150.000 đ`
  static String formatVND(double amount) {
    return _formatter.format(amount).trim();
  }

  /// Format số không kèm ký hiệu: ví dụ `150.000`
  static String formatNumber(double amount) {
    return _numberFormat.format(amount);
  }

  /// Format thu gọn: ví dụ 3.25M, 150K
  static String formatCompact(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// Parse text chứa số tiền sang double
  static double? parseAmount(String text) {
    final clean = text.replaceAll(RegExp(r'[^\d]'), '').trim();
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }
}
