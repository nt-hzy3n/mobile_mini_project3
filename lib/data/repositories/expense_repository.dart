import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/category_constants.dart';
import '../../core/services/firebase_storage_service.dart';
import '../models/expense_model.dart';
import 'auth_repository.dart';

class ExpenseRepository {
  final FirebaseFirestore? _customFirestore;
  final FirebaseStorageService? _customStorageService;
  final String? _customUserId;

  // In-memory fallback cache dùng khi offline, test hoặc chưa kết nối mạng
  // Lưu trữ theo Map<String, List<Expense>>: userId -> list of expenses
  static final Map<String, List<Expense>> _userMemoryFallback = {};
  static bool _hasSeededDefault = false;

  ExpenseRepository({
    FirebaseFirestore? firestore,
    FirebaseStorageService? storageService,
    String? userId,
  }) : _customFirestore = firestore,
       _customStorageService = storageService,
       _customUserId = userId {
    final uid = currentUserId;
    if (uid != null && !_userMemoryFallback.containsKey(uid)) {
      _initSampleMemoryForUser(uid);
    } else if (uid == null && !_hasSeededDefault) {
      _initSampleMemoryForUser('default_user');
      _hasSeededDefault = true;
    }
  }

  /// Lấy UID người dùng hiện tại (từ customUserId hoặc AuthRepository)
  String? get currentUserId {
    final uid = _customUserId;
    if (uid != null && uid.isNotEmpty) {
      return uid;
    }
    return AuthRepository.currentUserId;
  }

  FirebaseStorageService get _storageService =>
      _customStorageService ?? FirebaseStorageService();

  /// CollectionReference trỏ đến subcollection: `users/{uid}/expenses`
  CollectionReference<Map<String, dynamic>>? get _collection {
    final uid = currentUserId;
    if (uid == null || uid.isEmpty) return null;

    try {
      return (_customFirestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(uid)
          .collection('expenses');
    } catch (_) {
      return null;
    }
  }

  List<Expense> get _currentMemoryList {
    final uid = currentUserId ?? 'default_user';
    return _userMemoryFallback.putIfAbsent(uid, () => []);
  }

  void _initSampleMemoryForUser(String uid) {
    final now = DateTime.now();
    _userMemoryFallback[uid] = [
      Expense(
        id: 'sample_01',
        amount: 150000,
        merchant: 'Highlands Coffee',
        recipient: 'Highlands Coffee',
        category: ExpenseCategory.food,
        date: now.subtract(const Duration(hours: 3)),
        transactionTime: '08:30',
        bank: 'MBBank (MB)',
        accountNumber: '41212106082002',
        note: 'Cà phê sáng với nhóm Mini-Project',
        paymentMethod: 'QR Payment',
        sourceType: 'qr',
        qrPayload: '00020101021238540010A00000072701240006970422011003456789010208QRIBFTTA530370454061500005802VN5916HIGHLANDS COFFEE62190815Thanh toan cafe6304E8A9',
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
      Expense(
        id: 'sample_02',
        amount: 85000,
        merchant: 'Grab Transport',
        recipient: 'Grab Transport',
        category: ExpenseCategory.travel,
        date: now.subtract(const Duration(days: 1, hours: 2)),
        transactionTime: '17:53',
        bank: 'Vietcombank (VCB)',
        accountNumber: '98765432101234',
        note: 'Di chuyển từ KTX đến trường VKU',
        paymentMethod: 'QR Payment',
        sourceType: 'hybrid',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        updatedAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      Expense(
        id: 'sample_03',
        amount: 220000,
        merchant: 'Nhà sách FAHASA',
        recipient: 'Nhà sách FAHASA',
        category: ExpenseCategory.study,
        date: now.subtract(const Duration(days: 2, hours: 4)),
        transactionTime: '10:15',
        bank: 'Techcombank (TCB)',
        accountNumber: '19034567891234',
        note: 'Giáo trình Lập trình Di động Đa nền tảng',
        paymentMethod: 'QR Payment',
        sourceType: 'ocr',
        createdAt: now.subtract(const Duration(days: 2, hours: 4)),
        updatedAt: now.subtract(const Duration(days: 2, hours: 4)),
      ),
      Expense(
        id: 'sample_04',
        amount: 180000,
        merchant: 'CGV Vincom Đà Nẵng',
        recipient: 'CGV Vincom Đà Nẵng',
        category: ExpenseCategory.entertainment,
        date: now.subtract(const Duration(days: 3, hours: 6)),
        transactionTime: '20:00',
        bank: 'BIDV',
        accountNumber: '68686868682002',
        note: 'Xem phim cuối tuần',
        paymentMethod: 'QR Payment',
        sourceType: 'qr',
        createdAt: now.subtract(const Duration(days: 3, hours: 6)),
        updatedAt: now.subtract(const Duration(days: 3, hours: 6)),
      ),
      Expense(
        id: 'sample_05',
        amount: 750000,
        merchant: 'GearVN Đà Nẵng',
        recipient: 'GearVN Đà Nẵng',
        category: ExpenseCategory.gear,
        date: now.subtract(const Duration(days: 4, hours: 5)),
        transactionTime: '14:20',
        bank: 'MBBank (MB)',
        accountNumber: '09876543212002',
        note: 'Bàn phím cơ lập trình',
        paymentMethod: 'QR Payment',
        sourceType: 'hybrid',
        createdAt: now.subtract(const Duration(days: 4, hours: 5)),
        updatedAt: now.subtract(const Duration(days: 4, hours: 5)),
      ),
      Expense(
        id: 'sample_06',
        amount: 45000,
        merchant: 'Cơm tấm Sài Gòn',
        recipient: 'Cơm tấm Sài Gòn',
        category: ExpenseCategory.food,
        date: now.subtract(const Duration(days: 5, hours: 1)),
        transactionTime: '11:45',
        bank: 'Agribank',
        accountNumber: '55001234567890',
        note: 'Ăn trưa gần trường',
        paymentMethod: 'QR Payment',
        sourceType: 'qr',
        createdAt: now.subtract(const Duration(days: 5, hours: 1)),
        updatedAt: now.subtract(const Duration(days: 5, hours: 1)),
      ),
      Expense(
        id: 'sample_07',
        amount: 120000,
        merchant: 'Xanh SM Taxi',
        recipient: 'Xanh SM Taxi',
        category: ExpenseCategory.travel,
        date: now.subtract(const Duration(days: 6, hours: 3)),
        transactionTime: '09:10',
        bank: 'VPBank',
        accountNumber: '12345678902002',
        note: 'Đi gặp khách hàng',
        paymentMethod: 'QR Payment',
        sourceType: 'manual',
        createdAt: now.subtract(const Duration(days: 6, hours: 3)),
        updatedAt: now.subtract(const Duration(days: 6, hours: 3)),
      ),
    ];
  }

  // =========================================================================
  // CREATE
  // =========================================================================

  /// Tạo khoản chi tiêu mới trên Cloud Firestore: `users/{uid}/expenses/{expenseId}`
  /// và lưu ảnh lên Firebase Storage: `users/{uid}/expenses/{expenseId}/payment_image.jpg`
  Future<String> createExpense(Expense expense, {File? imageFile}) async {
    final col = _collection;
    final docRef = (col != null)
        ? ((expense.id != null && expense.id!.isNotEmpty)
              ? col.doc(expense.id)
              : col.doc())
        : null;
    final expenseId =
        docRef?.id ??
        (expense.id ?? 'exp_${DateTime.now().millisecondsSinceEpoch}');

    String? imageUrl = expense.imageUrl;
    String? imagePath = expense.imagePath;

    // 1. Tải ảnh lên Firebase Storage (User-scoped) nếu có
    File? fileToUpload = imageFile;
    if (fileToUpload == null &&
        expense.imagePath != null &&
        expense.imagePath!.isNotEmpty &&
        !expense.imagePath!.startsWith('http') &&
        !expense.imagePath!.startsWith('users/') &&
        !expense.imagePath!.startsWith('expenses/')) {
      final localFile = File(expense.imagePath!);
      if (localFile.existsSync()) {
        fileToUpload = localFile;
      }
    }

    if (fileToUpload != null) {
      try {
        final uploadResult = await _storageService.uploadExpenseImage(
          expenseId: expenseId,
          imageFile: fileToUpload,
          userId: currentUserId,
        );
        if (uploadResult != null) {
          imageUrl = uploadResult.imageUrl;
          imagePath = uploadResult.imagePath;
        }
      } catch (e) {
        debugPrint('Lỗi tải ảnh lên Firebase Storage: $e');
      }
    }

    final finalExpense = expense.copyWith(
      id: expenseId,
      imageUrl: imageUrl,
      imagePath: imagePath,
      updatedAt: DateTime.now(),
    );

    // 2. Lưu document vào Cloud Firestore
    if (docRef != null) {
      try {
        await docRef.set(finalExpense.toFirestore());
      } catch (e) {
        debugPrint('Lưu Firestore dự phòng qua bộ nhớ cục bộ: $e');
      }
    }

    // Cập nhật bộ nhớ đệm theo user
    final memList = _currentMemoryList;
    memList.removeWhere((e) => e.id == expenseId);
    memList.insert(0, finalExpense);

    return expenseId;
  }

  /// Alias cho createExpense
  Future<String> addExpense(Expense expense, {File? imageFile}) {
    return createExpense(expense, imageFile: imageFile);
  }

  // =========================================================================
  // READ
  // =========================================================================

  /// Lấy danh sách toàn bộ khoản chi tiêu của người dùng từ Cloud Firestore
  Future<List<Expense>> getExpenses() async {
    final col = _collection;
    if (col != null) {
      try {
        final snapshot = await col.orderBy('date', descending: true).get();

        if (snapshot.docs.isNotEmpty) {
          final list = snapshot.docs.map((doc) {
            return Expense.fromFirestore(doc.data(), doc.id);
          }).toList();

          // Đồng bộ với cache của user
          final memList = _currentMemoryList;
          memList.clear();
          memList.addAll(list);
          return list;
        }
      } catch (e) {
        debugPrint('Không thể tải từ Firestore, sử dụng cache bộ nhớ: $e');
      }
    }

    final list = List<Expense>.from(_currentMemoryList);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Alias cho getExpenses
  Future<List<Expense>> getAllExpenses() => getExpenses();

  /// Lắng nghe luồng dữ liệu thời gian thực từ Cloud Firestore: `users/{uid}/expenses`
  Stream<List<Expense>> watchExpenses() {
    final col = _collection;
    if (col != null) {
      try {
        return col.orderBy('date', descending: true).snapshots().map((
          snapshot,
        ) {
          if (snapshot.docs.isNotEmpty) {
            return snapshot.docs.map((doc) {
              return Expense.fromFirestore(doc.data(), doc.id);
            }).toList();
          }
          return List<Expense>.from(_currentMemoryList);
        });
      } catch (_) {}
    }
    return Stream.value(List<Expense>.from(_currentMemoryList));
  }

  /// Lấy chi tiết một khoản chi tiêu theo Firestore Document ID
  Future<Expense?> getExpenseById(String id) async {
    final col = _collection;
    if (col != null) {
      try {
        final doc = await col.doc(id).get();
        if (doc.exists && doc.data() != null) {
          return Expense.fromFirestore(doc.data()!, doc.id);
        }
      } catch (e) {
        debugPrint('Lỗi đọc Firestore theo ID $id: $e');
      }
    }

    try {
      return _currentMemoryList.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // UPDATE
  // =========================================================================

  /// Cập nhật thông tin khoản chi tiêu trên Cloud Firestore
  Future<void> updateExpense(Expense expense, {File? newImageFile}) async {
    final expenseId = expense.id;
    if (expenseId == null || expenseId.isEmpty) return;

    String? imageUrl = expense.imageUrl;
    String? imagePath = expense.imagePath;

    if (newImageFile != null) {
      try {
        final uploadResult = await _storageService.uploadExpenseImage(
          expenseId: expenseId,
          imageFile: newImageFile,
          userId: currentUserId,
        );
        if (uploadResult != null) {
          imageUrl = uploadResult.imageUrl;
          imagePath = uploadResult.imagePath;
        }
      } catch (e) {
        debugPrint('Lỗi cập nhật ảnh Firebase Storage: $e');
      }
    }

    final updated = expense.copyWith(
      imageUrl: imageUrl,
      imagePath: imagePath,
      updatedAt: DateTime.now(),
    );

    final col = _collection;
    if (col != null) {
      try {
        await col.doc(expenseId).update(updated.toFirestore());
      } catch (e) {
        debugPrint('Lỗi cập nhật Firestore: $e');
      }
    }

    final memList = _currentMemoryList;
    final idx = memList.indexWhere((e) => e.id == expenseId);
    if (idx != -1) {
      memList[idx] = updated;
    }
  }

  // =========================================================================
  // DELETE
  // =========================================================================

  /// Xóa khoản chi tiêu:
  /// 1. Xóa document trên Cloud Firestore (`users/{uid}/expenses/{id}`).
  /// 2. Xóa ảnh đính kèm trên Firebase Storage nếu có.
  Future<void> deleteExpense(Expense expense) async {
    final expenseId = expense.id;
    if (expenseId == null || expenseId.isEmpty) return;

    // 1. Xóa ảnh trên Firebase Storage
    if (expense.imagePath != null || expense.imageUrl != null) {
      try {
        await _storageService.deleteExpenseImage(
          imagePath: expense.imagePath,
          imageUrl: expense.imageUrl,
        );
      } catch (e) {
        debugPrint('Lỗi xóa ảnh Storage (bỏ qua an toàn): $e');
      }
    }

    // 2. Xóa document trên Cloud Firestore
    final col = _collection;
    if (col != null) {
      try {
        await col.doc(expenseId).delete();
      } catch (e) {
        debugPrint('Lỗi xóa Firestore: $e');
      }
    }

    _currentMemoryList.removeWhere((e) => e.id == expenseId);
  }

  // =========================================================================
  // ANALYTICS & QUERY METHODS (USER-SCOPED)
  // =========================================================================

  Future<List<Expense>> getRecentExpenses({int limit = 5}) async {
    final all = await getAllExpenses();
    return all.take(limit).toList();
  }

  Future<List<Expense>> searchExpenses(String query) async {
    final all = await getAllExpenses();
    final q = query.toLowerCase();
    return all
        .where(
          (e) =>
              e.merchant.toLowerCase().contains(q) ||
              e.effectiveRecipient.toLowerCase().contains(q) ||
              e.note.toLowerCase().contains(q) ||
              (e.bank?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  Future<List<Expense>> filterByCategory(String category) async {
    final all = await getAllExpenses();
    return all
        .where(
          (e) =>
              e.category.name.toLowerCase() == category.toLowerCase() ||
              e.category.vietnameseName.toLowerCase() == category.toLowerCase(),
        )
        .toList();
  }

  Future<List<Expense>> filterByDateRange(DateTime start, DateTime end) async {
    final all = await getAllExpenses();
    return all
        .where(
          (e) =>
              (e.date.isAfter(start) || e.date.isAtSameMomentAs(start)) &&
              (e.date.isBefore(end) || e.date.isAtSameMomentAs(end)),
        )
        .toList();
  }

  Future<double> getMonthlyTotal(DateTime month) async {
    final all = await getAllExpenses();
    return all
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .fold<double>(0.0, (total, e) => total + e.amount);
  }

  Future<double> getWeeklyTotal(
    DateTime startOfWeek,
    DateTime endOfWeek,
  ) async {
    final all = await getAllExpenses();
    return all
        .where(
          (e) =>
              (e.date.isAfter(startOfWeek) ||
                  e.date.isAtSameMomentAs(startOfWeek)) &&
              e.date.isBefore(endOfWeek),
        )
        .fold<double>(0.0, (total, e) => total + e.amount);
  }

  Future<Map<int, double>> getWeeklyDailyTotals(DateTime startOfWeek) async {
    final all = await getAllExpenses();
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final totals = <int, double>{
      1: 0.0,
      2: 0.0,
      3: 0.0,
      4: 0.0,
      5: 0.0,
      6: 0.0,
      7: 0.0,
    };
    for (final e in all) {
      if ((e.date.isAfter(startOfWeek) ||
              e.date.isAtSameMomentAs(startOfWeek)) &&
          e.date.isBefore(endOfWeek)) {
        totals[e.date.weekday] = (totals[e.date.weekday] ?? 0.0) + e.amount;
      }
    }
    return totals;
  }

  Future<Map<String, double>> getCategorySpending({DateTime? month}) async {
    final all = await getAllExpenses();
    final list = month != null
        ? all
              .where(
                (e) => e.date.year == month.year && e.date.month == month.month,
              )
              .toList()
        : all;
    final map = <String, double>{};
    for (final e in list) {
      final cat = e.category.vietnameseName;
      map[cat] = (map[cat] ?? 0.0) + e.amount;
    }
    return map;
  }

  Future<void> clearAll() async {
    final col = _collection;
    if (col != null) {
      try {
        final snapshot = await col.get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('Lỗi xóa toàn bộ Firestore: $e');
      }
    }
    _currentMemoryList.clear();
  }

  Future<void> seedDemoData() async {
    final uid = currentUserId ?? 'default_user';
    _initSampleMemoryForUser(uid);
    final col = _collection;
    if (col != null) {
      try {
        for (final exp in _currentMemoryList) {
          await col.doc(exp.id).set(exp.toFirestore());
        }
      } catch (e) {
        debugPrint('Lỗi đồng bộ dữ liệu mẫu lên Firestore: $e');
      }
    }
  }
}
