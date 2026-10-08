import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_qr/core/constants/category_constants.dart';
import 'package:vku_expense_qr/data/models/expense_model.dart';
import 'package:vku_expense_qr/features/expenses/widgets/expense_card.dart';

void main() {
  testWidgets(
    'ExpenseCard renders merchant, amount, category and responds to tap',
    (WidgetTester tester) async {
      bool tapped = false;

      final expense = Expense(
        id: '1',
        amount: 150000,
        merchant: 'Highlands Coffee',
        category: ExpenseCategory.food,
        date: DateTime(2026, 10, 1),
        note: 'Thanh toan cafe',
        sourceType: 'qr',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseCard(
              expense: expense,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Highlands Coffee'), findsOneWidget);
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('QR'), findsOneWidget);
      expect(find.text('Thanh toan cafe'), findsOneWidget);

      await tester.tap(find.byType(ExpenseCard));
      expect(tapped, isTrue);
    },
  );
}
