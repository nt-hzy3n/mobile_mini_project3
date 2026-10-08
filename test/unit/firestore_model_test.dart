import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_qr/core/constants/category_constants.dart';
import 'package:vku_expense_qr/data/models/expense_model.dart';
import 'package:vku_expense_qr/data/repositories/expense_repository.dart';

void main() {
  group('Firestore Expense Model & Repository CRUD Tests', () {
    test(
      'Expense model serialization with Firestore format and banking fields',
      () {
        final now = DateTime(2026, 9, 28, 17, 53);
        final expense = Expense(
          id: 'exp_mb_001',
          amount: 1000000.0,
          merchant: 'NGUYEN THI THUONG',
          recipient: 'NGUYEN THI THUONG',
          category: ExpenseCategory.food,
          date: now,
          transactionTime: '17:53',
          bank: 'MBBank (MB)',
          accountNumber: '41212106082002',
          note: 'NGUYEN THI HUYEN chuyen tien',
          paymentMethod: 'Bank Transfer',
          sourceType: 'HYBRID',
          imageUrl: 'https://firebasestorage.googleapis.com/v0/b/vku-expense-qr.appspot.com/o/expenses%2Fexp_001.jpg',
          imagePath: 'expenses/exp_mb_001/payment_image.jpg',
          createdAt: now,
          updatedAt: now,
        );

        // Verify toFirestore
        final firestoreMap = expense.toFirestore();
        expect(firestoreMap['amount'], 1000000.0);
        expect(firestoreMap['merchant'], 'NGUYEN THI THUONG');
        expect(firestoreMap['recipient'], 'NGUYEN THI THUONG');
        expect(firestoreMap['category'], 'Food');
        expect(firestoreMap['transactionTime'], '17:53');
        expect(firestoreMap['bank'], 'MBBank (MB)');
        expect(firestoreMap['accountNumber'], '41212106082002');
        expect(firestoreMap['note'], 'NGUYEN THI HUYEN chuyen tien');
        expect(firestoreMap['sourceType'], 'HYBRID');
        expect(
          firestoreMap['imageUrl'],
          contains('firebasestorage.googleapis.com'),
        );
        expect(
          firestoreMap['imagePath'],
          'expenses/exp_mb_001/payment_image.jpg',
        );
        expect(firestoreMap['date'], isA<Timestamp>());
        expect(firestoreMap['createdAt'], isA<Timestamp>());
        expect(firestoreMap['updatedAt'], isA<Timestamp>());

        // Verify fromFirestore reconstruction
        final reconstructed = Expense.fromFirestore(firestoreMap, 'exp_mb_001');
        expect(reconstructed.id, 'exp_mb_001');
        expect(reconstructed.amount, 1000000.0);
        expect(reconstructed.merchant, 'NGUYEN THI THUONG');
        expect(reconstructed.recipient, 'NGUYEN THI THUONG');
        expect(reconstructed.effectiveRecipient, 'NGUYEN THI THUONG');
        expect(reconstructed.bank, 'MBBank (MB)');
        expect(reconstructed.accountNumber, '41212106082002');
        expect(reconstructed.maskedAccountNumber, '********2002');
        expect(reconstructed.transactionTime, '17:53');
        expect(reconstructed.imageUrl, contains('expenses%2Fexp_001.jpg'));
        expect(
          reconstructed.imagePath,
          'expenses/exp_mb_001/payment_image.jpg',
        );
      },
    );

    test('ExpenseRepository: CRUD operations and calculations', () async {
      final repo = ExpenseRepository();
      final initialExpenses = await repo.getAllExpenses();
      final initialCount = initialExpenses.length;

      // 1. CREATE
      final newExpense = Expense(
        id: 'test_create_01',
        amount: 50000.0,
        merchant: 'Trà sữa Gong Cha',
        recipient: 'Trà sữa Gong Cha',
        category: ExpenseCategory.entertainment,
        date: DateTime.now(),
        transactionTime: '15:30',
        bank: 'Vietcombank',
        accountNumber: '1234567890',
        note: 'Trà sữa chiều',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newId = await repo.createExpense(newExpense);
      expect(newId, 'test_create_01');

      final updatedList = await repo.getAllExpenses();
      expect(updatedList.length, initialCount + 1);

      // 2. READ
      final fetched = await repo.getExpenseById(newId);
      expect(fetched, isNotNull);
      expect(fetched!.merchant, 'Trà sữa Gong Cha');
      expect(fetched.amount, 50000.0);

      // 3. UPDATE
      final modified = fetched.copyWith(
        amount: 65000.0,
        note: 'Trà sữa thêm trân châu trắng',
      );
      await repo.updateExpense(modified);

      final reFetched = await repo.getExpenseById(newId);
      expect(reFetched!.amount, 65000.0);
      expect(reFetched.note, 'Trà sữa thêm trân châu trắng');

      // 4. DELETE
      await repo.deleteExpense(reFetched);

      final afterDelete = await repo.getAllExpenses();
      expect(afterDelete.length, initialCount);
      expect(await repo.getExpenseById(newId), isNull);
    });

    test(
      'ExpenseRepository: Monthly, Weekly, Category spending analytics',
      () async {
        final repo = ExpenseRepository();
        final now = DateTime.now();

        final monthlyTotal = await repo.getMonthlyTotal(now);
        expect(monthlyTotal, isA<double>());

        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        final weeklyTotal = await repo.getWeeklyTotal(startOfWeek, endOfWeek);
        expect(weeklyTotal, isA<double>());

        final categorySpending = await repo.getCategorySpending();
        expect(categorySpending, isA<Map<String, double>>());
        expect(categorySpending.isNotEmpty, isTrue);
      },
    );
  });
}
