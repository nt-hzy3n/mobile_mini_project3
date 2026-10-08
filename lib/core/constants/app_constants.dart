class AppConstants {
  static const String appName = 'VKU Expense QR';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Quản lý chi tiêu thông minh bằng cách quét mã QR thanh toán và OCR trên thiết bị.';
  static const String schoolName = 'VKU - Trường Đại học CNTT & TT Việt - Hàn';
  static const String courseName = 'Cross-Platform Mobile App Development';
  static const String miniProject =
      'Mini-Project 3: Payment Screenshot Expense Tracker (Week 8)';

  // Database
  static const String dbName = 'vku_expense_qr.db';
  static const int dbVersion = 2;
  static const String tableExpenses = 'expenses';

  // Shared Preferences Keys
  static const String prefThemeMode = 'app_theme_mode';
  static const String prefDemoSeeded = 'demo_data_seeded';

  // Default Payment Method
  static const String defaultPaymentMethod = 'QR Payment';
}
