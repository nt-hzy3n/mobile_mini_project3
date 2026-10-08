import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_qr/features/analytics/widgets/category_donut_chart.dart';
import 'package:vku_expense_qr/features/analytics/widgets/weekly_bar_chart.dart';

void main() {
  group('CustomPainter Charts Widget Tests', () {
    testWidgets('CategoryDonutChart renders CustomPaint and legends properly', (
      WidgetTester tester,
    ) async {
      final categorySpending = {
        'Food': 150000.0,
        'Study': 220000.0,
        'Travel': 85000.0,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDonutChart(
              categorySpending: categorySpending,
              totalAmount: 455000.0,
            ),
          ),
        ),
      );

      // Verify CustomPaint is present
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Tổng chi'), findsOneWidget);

      // Verify category legend labels
      expect(find.textContaining('Ăn uống'), findsOneWidget);
      expect(find.textContaining('Học tập'), findsOneWidget);
      expect(find.textContaining('Di chuyển'), findsOneWidget);
    });

    testWidgets('WeeklyBarChart renders days T2 through CN and CustomPaint', (
      WidgetTester tester,
    ) async {
      final weeklySpending = {
        1: 50000.0,
        2: 120000.0,
        3: 80000.0,
        4: 0.0,
        5: 200000.0,
        6: 150000.0,
        7: 45000.0,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WeeklyBarChart(weeklySpending: weeklySpending)),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('T2'), findsOneWidget);
      expect(find.text('T3'), findsOneWidget);
      expect(find.text('T4'), findsOneWidget);
      expect(find.text('T5'), findsOneWidget);
      expect(find.text('T6'), findsOneWidget);
      expect(find.text('T7'), findsOneWidget);
      expect(find.text('CN'), findsOneWidget);
    });
  });
}
