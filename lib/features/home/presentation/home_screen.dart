import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/expense_provider.dart';
import '../../../widgets/empty_state.dart';
import '../../expenses/widgets/expense_card.dart';
import '../widgets/balance_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncExpenses = ref.watch(expensesProvider);
    final recentExpenses = ref.watch(recentExpensesProvider);
    final monthlyTotal = ref.watch(monthlyTotalProvider);
    final weeklyTotal = ref.watch(weeklyTotalProvider);
    final todayTotal = ref.watch(todayTotalProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(expensesProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              // Greeting & Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Xin chào',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('👋', style: TextStyle(fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'VKU Expense QR',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Cài đặt',
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF2E3440)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: const Icon(Icons.settings_outlined, size: 20),
                        ),
                        onPressed: () => context.push('/settings'),
                      ),
                    ],
                  ),
                ),
              ),

              // Balance Gradient Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: asyncExpenses.maybeWhen(
                    data: (expenses) => BalanceCard(
                      monthlyTotal: monthlyTotal,
                      weeklyTotal: weeklyTotal,
                      todayTotal: todayTotal,
                      transactionCount: expenses.length,
                    ),
                    orElse: () => const BalanceCard(
                      monthlyTotal: 0,
                      weeklyTotal: 0,
                      todayTotal: 0,
                      transactionCount: 0,
                    ),
                  ),
                ),
              ),

              // Recent Expenses Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Khoản chi gần đây',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/expenses'),
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Expense Items or Empty State
              asyncExpenses.when(
                data: (expenses) {
                  if (expenses.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: EmptyState(
                          title: 'Chưa có khoản chi nào',
                          message: 'Quét mã QR thanh toán hoặc ảnh chuyển khoản để ghi nhận chi tiêu tự động.',
                          actionLabel: 'Thêm chi tiêu',
                          onAction: () => context.push('/scan'),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final expense = recentExpenses[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: ExpenseCard(
                            expense: expense,
                            onTap: () {
                              if (expense.id != null) {
                                context.push('/expenses/${expense.id}');
                              }
                            },
                          ),
                        );
                      }, childCount: recentExpenses.length),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text('Lỗi tải dữ liệu: $e'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text(
          'Thêm chi tiêu',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () => context.push('/scan'),
      ),
    );
  }
}
