import 'currency_formatter.dart';

class Validators {
  static String? validateMerchant(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tên người nhận hoặc cửa hàng';
    }
    if (value.trim().length < 2) {
      return 'Tên người nhận phải có ít nhất 2 ký tự';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số tiền giao dịch';
    }
    if (value.contains('-')) {
      return 'Số tiền không được là số âm';
    }
    final amount = CurrencyFormatter.parseAmount(value);
    if (amount == null || amount <= 0) {
      return 'Số tiền phải là số hợp lệ và lớn hơn 0 đ';
    }
    return null;
  }

  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Vui lòng chọn ngày giao dịch hợp lệ';
    }
    return null;
  }

  static String? validateTime(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final match = RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$')
          .hasMatch(value.trim());
      if (!match) {
        return 'Thời gian phải theo định dạng HH:mm (ví dụ: 17:53)';
      }
    }
    return null;
  }

  static String? validateNote(String? value) {
    if (value != null && value.length > 255) {
      return 'Nội dung chuyển khoản không được quá 255 ký tự';
    }
    return null;
  }
}
