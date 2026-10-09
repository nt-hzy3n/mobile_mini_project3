import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/expense_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase theo cấu hình DefaultFirebaseOptions
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Khôi phục phiên đăng nhập bền vững từ bộ nhớ máy (hỗ trợ offline/demo APK)
  await AuthRepository.restoreSession();

  // Tự động nạp dữ liệu mẫu ban đầu nếu chạy lần đầu
  try {
    final prefs = await SharedPreferences.getInstance();
    final hasSeeded = prefs.getBool(AppConstants.prefDemoSeeded) ?? false;
    if (!hasSeeded) {
      final repo = ExpenseRepository();
      final existing = await repo.getAllExpenses();
      if (existing.isEmpty) {
        await repo.seedDemoData();
        await prefs.setBool(AppConstants.prefDemoSeeded, true);
      }
    }
  } catch (e) {
    debugPrint('SharedPreferences init notice: $e');
  }

  runApp(const ProviderScope(child: VkuExpenseQrApp()));
}
