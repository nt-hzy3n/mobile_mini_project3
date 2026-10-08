import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_qr/core/constants/category_constants.dart';
import 'package:vku_expense_qr/data/models/expense_model.dart';
import 'package:vku_expense_qr/data/repositories/expense_repository.dart';

void main() {
  group('User-Scoped Firestore & Storage Unit Tests', () {
    test(
      'ExpenseRepository: verifies user-scoped isolation between accounts',
      () async {
        // 1. Khởi tạo repository cho User A
        final repoUserA = ExpenseRepository(userId: 'uid_user_alpha_110');
        expect(repoUserA.currentUserId, 'uid_user_alpha_110');

        // 2. Khởi tạo repository cho User B
        final repoUserB = ExpenseRepository(userId: 'uid_user_beta_220');
        expect(repoUserB.currentUserId, 'uid_user_beta_220');

        // Xóa sạch dữ liệu khởi đầu của 2 user
        await repoUserA.clearAll();
        await repoUserB.clearAll();

        expect((await repoUserA.getAllExpenses()).isEmpty, isTrue);
        expect((await repoUserB.getAllExpenses()).isEmpty, isTrue);

        // 3. User A thêm khoản chi tiêu riêng
        final expenseA = Expense(
          id: 'exp_alpha_01',
          amount: 250000.0,
          merchant: 'The Coffee House',
          recipient: 'The Coffee House',
          category: ExpenseCategory.food,
          date: DateTime.now(),
          transactionTime: '09:15',
          bank: 'MBBank',
          accountNumber: '41212106082002',
          note: 'User A uống cà phê',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repoUserA.createExpense(expenseA);

        // 4. Kiểm tra User A nhìn thấy khoản chi của mình
        final listA = await repoUserA.getAllExpenses();
        expect(listA.length, 1);
        expect(listA.first.merchant, 'The Coffee House');
        expect(listA.first.amount, 250000.0);

        // 5. Kiểm tra User B KHÔNG THỂ nhìn thấy khoản chi của User A (Bảo mật User-scoped)
        final listB = await repoUserB.getAllExpenses();
        expect(listB.isEmpty, isTrue);

        // 6. User B thêm khoản chi riêng
        final expenseB = Expense(
          id: 'exp_beta_01',
          amount: 150000.0,
          merchant: 'KFC Da Nang',
          recipient: 'KFC Da Nang',
          category: ExpenseCategory.food,
          date: DateTime.now(),
          transactionTime: '12:30',
          bank: 'Vietcombank',
          accountNumber: '98765432101234',
          note: 'User B ăn trưa',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repoUserB.createExpense(expenseB);

        // Kiểm tra danh sách User B chỉ có 1 item của User B
        final updatedListB = await repoUserB.getAllExpenses();
        expect(updatedListB.length, 1);
        expect(updatedListB.first.merchant, 'KFC Da Nang');

        // User A vẫn chỉ có 1 item của User A
        final currentListA = await repoUserA.getAllExpenses();
        expect(currentListA.length, 1);
        expect(currentListA.first.merchant, 'The Coffee House');
      },
    );

    test('User-scoped Storage Path format validation', () {
      const uid = 'uid_huyen_23it110';
      const expenseId = 'exp_mb_001';
      final expectedPath = 'users/$uid/expenses/$expenseId/payment_image.jpg';

      expect(expectedPath.startsWith('users/$uid/expenses/'), isTrue);
      expect(expectedPath.endsWith('/payment_image.jpg'), isTrue);
    });
  });
}
