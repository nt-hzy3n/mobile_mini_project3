import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/models/expense_model.dart';
import '../data/repositories/expense_repository.dart';
import 'auth_provider.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  return ExpenseRepository(userId: user?.uid);
});

/// Firestore Realtime Stream Provider
final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.watchExpenses();
});

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    final repo = ref.watch(expenseRepositoryProvider);
    return await repo.getAllExpenses();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(expenseRepositoryProvider);
      return await repo.getAllExpenses();
    });
  }

  Future<String> addExpense(Expense expense, {File? imageFile}) async {
    final repo = ref.read(expenseRepositoryProvider);
    final id = await repo.addExpense(expense, imageFile: imageFile);
    await refresh();
    return id;
  }

  Future<void> updateExpense(Expense expense, {File? newImageFile}) async {
    final repo = ref.read(expenseRepositoryProvider);
    await repo.updateExpense(expense, newImageFile: newImageFile);
    await refresh();
  }

  Future<void> deleteExpense(Expense expense) async {
    final repo = ref.read(expenseRepositoryProvider);
    await repo.deleteExpense(expense);
    await refresh();
  }

  Future<void> clearAll() async {
    final repo = ref.read(expenseRepositoryProvider);
    await repo.clearAll();
    await refresh();
  }

  Future<void> seedDemoData() async {
    final repo = ref.read(expenseRepositoryProvider);
    await repo.seedDemoData();
    await refresh();
  }
}

final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(
  () {
    return ExpensesNotifier();
  },
);

/// Search query provider
final expenseSearchQueryProvider = StateProvider<String>((ref) => '');

/// Category filter provider (null = all)
final expenseCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Filtered expenses based on search and category
final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final asyncExpenses = ref.watch(expensesProvider);
  final query = ref.watch(expenseSearchQueryProvider).trim().toLowerCase();
  final categoryFilter = ref.watch(expenseCategoryFilterProvider);

  return asyncExpenses.maybeWhen(
    data: (expenses) {
      return expenses.where((exp) {
        final matchesQuery =
            query.isEmpty ||
            exp.merchant.toLowerCase().contains(query) ||
            exp.note.toLowerCase().contains(query);
        final matchesCategory =
            categoryFilter == null ||
            exp.category.name.toLowerCase() == categoryFilter.toLowerCase() ||
            exp.category.vietnameseName.toLowerCase() ==
                categoryFilter.toLowerCase();
        return matchesQuery && matchesCategory;
      }).toList();
    },
    orElse: () => [],
  );
});

/// 5 khoản chi tiêu gần đây nhất cho Home
final recentExpensesProvider = Provider<List<Expense>>((ref) {
  final asyncExpenses = ref.watch(expensesProvider);
  return asyncExpenses.maybeWhen(
    data: (expenses) => expenses.take(5).toList(),
    orElse: () => [],
  );
});

/// Tổng chi tiêu trong tháng hiện tại
final monthlyTotalProvider = Provider<double>((ref) {
  final asyncExpenses = ref.watch(expensesProvider);
  final now = DateTime.now();

  return asyncExpenses.maybeWhen(
    data: (expenses) {
      return expenses
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .fold<double>(0.0, (sum, e) => sum + e.amount);
    },
    orElse: () => 0.0,
  );
});

/// Tổng chi tiêu trong tuần hiện tại
final weeklyTotalProvider = Provider<double>((ref) {
  final asyncExpenses = ref.watch(expensesProvider);
  final now = DateTime.now();
  // Monday of this week
  final monday = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final nextMonday = monday.add(const Duration(days: 7));

  return asyncExpenses.maybeWhen(
    data: (expenses) {
      return expenses
          .where(
            (e) =>
                (e.date.isAfter(monday) || e.date.isAtSameMomentAs(monday)) &&
                e.date.isBefore(nextMonday),
          )
          .fold<double>(0.0, (sum, e) => sum + e.amount);
    },
    orElse: () => 0.0,
  );
});

/// Tổng chi tiêu hôm nay
final todayTotalProvider = Provider<double>((ref) {
  final asyncExpenses = ref.watch(expensesProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  return asyncExpenses.maybeWhen(
    data: (expenses) {
      return expenses
          .where(
            (e) =>
                (e.date.isAfter(today) || e.date.isAtSameMomentAs(today)) &&
                e.date.isBefore(tomorrow),
          )
          .fold<double>(0.0, (sum, e) => sum + e.amount);
    },
    orElse: () => 0.0,
  );
});

/// Phân phối chi tiêu theo từng thứ trong tuần (1: Thứ Hai -> 7: Chủ Nhật)
final weeklySpendingProvider = Provider<Map<int, double>>((ref) {
  final asyncExpenses = ref.watch(expensesProvider);
  final now = DateTime.now();
  final monday = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final nextMonday = monday.add(const Duration(days: 7));

  final result = <int, double>{
    1: 0.0,
    2: 0.0,
    3: 0.0,
    4: 0.0,
    5: 0.0,
    6: 0.0,
    7: 0.0,
  };

  return asyncExpenses.maybeWhen(
    data: (expenses) {
      for (final e in expenses) {
        if ((e.date.isAfter(monday) || e.date.isAtSameMomentAs(monday)) &&
            e.date.isBefore(nextMonday)) {
          final day = e.date.weekday;
          result[day] = (result[day] ?? 0.0) + e.amount;
        }
      }
      return result;
    },
    orElse: () => result,
  );
});

/// Phân phối chi tiêu theo danh mục
final categorySpendingProvider = Provider<Map<String, double>>((ref) {
  final asyncExpenses = ref.watch(expensesProvider);

  return asyncExpenses.maybeWhen(
    data: (expenses) {
      final map = <String, double>{};
      for (final e in expenses) {
        final cat = e.category.vietnameseName;
        map[cat] = (map[cat] ?? 0.0) + e.amount;
      }
      return map;
    },
    orElse: () => {},
  );
});
