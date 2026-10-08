import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/category_constants.dart';
import '../../../data/models/expense_model.dart';
import '../../../providers/expense_provider.dart';
import '../../../widgets/empty_state.dart';
import '../widgets/expense_card.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = ref.watch(filteredExpensesProvider);
    final selectedCategory = ref.watch(expenseCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý chi tiêu'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(expensesProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm cửa hàng, ghi chú...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(expenseSearchQueryProvider.notifier).state =
                              '';
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                ref.read(expenseSearchQueryProvider.notifier).state = val;
              },
            ),
          ),
          // Category Filter Chips
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryFilterChip(
                  label: 'Tất cả',
                  isSelected: selectedCategory == null,
                  onSelected: () {
                    ref.read(expenseCategoryFilterProvider.notifier).state =
                        null;
                  },
                ),
                ...ExpenseCategory.values.map((cat) {
                  final isSelected = selectedCategory == cat.name;
                  return _buildCategoryFilterChip(
                    label: cat.vietnameseName,
                    icon: cat.icon,
                    isSelected: isSelected,
                    onSelected: () {
                      ref.read(expenseCategoryFilterProvider.notifier).state =
                          isSelected ? null : cat.name;
                    },
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Expense Count Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh sách (${expenses.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Vuốt sang trái để xóa',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Expense List
          Expanded(
            child: expenses.isEmpty
                ? EmptyState(
                    title:
                        _searchController.text.isNotEmpty ||
                            selectedCategory != null
                        ? 'Không tìm thấy chi tiêu phù hợp'
                        : 'Chưa có khoản chi nào',
                    message:
                        _searchController.text.isNotEmpty ||
                            selectedCategory != null
                        ? 'Hãy thử tìm kiếm với từ khóa khác hoặc xóa bộ lọc danh mục.'
                        : 'Bấm nút "Quét thanh toán" để thêm khoản chi tiêu đầu tiên.',
                    actionLabel:
                        _searchController.text.isEmpty &&
                            selectedCategory == null
                        ? 'Quét thanh toán'
                        : null,
                    onAction: () => context.push('/scan'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: expenses.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return Dismissible(
                        key: ValueKey(expense.id ?? index),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_forever_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Xóa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await _showDeleteConfirmation(
                            context,
                            expense,
                          );
                        },
                        onDismissed: (direction) async {
                          await ref
                              .read(expensesProvider.notifier)
                              .deleteExpense(expense);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã xóa "${expense.merchant}"'),
                                action: SnackBarAction(
                                  label: 'Hoàn tác',
                                  onPressed: () async {
                                    await ref
                                        .read(expensesProvider.notifier)
                                        .addExpense(expense);
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        child: ExpenseCard(
                          expense: expense,
                          onTap: () {
                            if (expense.id != null) {
                              context.push('/expenses/${expense.id}');
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        avatar: icon != null
            ? Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : theme.colorScheme.primary,
              )
            : null,
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.white
              : (theme.brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    Expense expense,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa khoản chi tiêu "${expense.merchant}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
