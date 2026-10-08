import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/category_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/expense_model.dart';
import '../../../providers/expense_provider.dart';
import '../../../widgets/app_card.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final String expenseId;

  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  Expense? _expense;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpense();
  }

  Future<void> _loadExpense() async {
    final repo = ref.read(expenseRepositoryProvider);
    final item = await repo.getExpenseById(widget.expenseId);
    if (mounted) {
      setState(() {
        _expense = item;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_expense == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết chi tiêu')),
        body: const Center(child: Text('Không tìm thấy khoản chi tiêu này')),
      );
    }

    final exp = _expense!;
    final category = exp.category;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết chi tiêu'),
        actions: [
          IconButton(
            tooltip: 'Chỉnh sửa',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditDialog(exp),
          ),
          IconButton(
            tooltip: 'Xóa khoản chi',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(exp),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Amount Card
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(category.icon, color: category.color, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    exp.merchant,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.formatVND(exp.amount),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Source Badge
                  _buildSourceBadge(exp.sourceType),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Info Details Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Ngày giao dịch',
                    value: DateFormatter.format(exp.date),
                  ),
                  if (exp.transactionTime != null &&
                      exp.transactionTime!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      icon: Icons.access_time_rounded,
                      label: 'Thời gian',
                      value: exp.transactionTime!,
                    ),
                  ],
                  if (exp.bank != null && exp.bank!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      icon: Icons.account_balance_rounded,
                      label: 'Ngân hàng',
                      value: exp.bank!,
                    ),
                  ],
                  if (exp.accountNumber != null &&
                      exp.accountNumber!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      icon: Icons.credit_card_rounded,
                      label: 'Số tài khoản',
                      value: exp.maskedAccountNumber ?? exp.accountNumber!,
                    ),
                  ],
                  const Divider(height: 24),
                  _buildDetailRow(
                    icon: Icons.category_rounded,
                    label: 'Danh mục',
                    value: category.vietnameseName,
                    valueColor: category.color,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    icon: Icons.payment_rounded,
                    label: 'Phương thức',
                    value: exp.paymentMethod,
                  ),
                  if (exp.note.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      icon: Icons.notes_rounded,
                      label: 'Nội dung chuyển khoản',
                      value: exp.note,
                    ),
                  ],
                ],
              ),
            ),
            // Stored Image preview (Firebase Storage / Local File)
            if ((exp.imageUrl != null && exp.imageUrl!.isNotEmpty) ||
                (exp.imagePath != null &&
                    !exp.imagePath!.startsWith('expenses/') &&
                    File(exp.imagePath!).existsSync())) ...[
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ảnh giao dịch thanh toán (Firebase Storage)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: exp.imageUrl != null && exp.imageUrl!.isNotEmpty
                          ? Image.network(
                              exp.imageUrl!,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  height: 220,
                                  color: Colors.grey.withOpacity(0.1),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 220,
                                    color: Colors.grey.withOpacity(0.1),
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                            )
                          : Image.file(
                              File(exp.imagePath!),
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ],
                ),
              ),
            ],
            // QR Payload Raw Data (Section 36)
            if (exp.qrPayload != null && exp.qrPayload!.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.qr_code_2_rounded,
                              size: 20,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Dữ liệu mã QR gốc',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          tooltip: 'Sao chép chuỗi QR',
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: exp.qrPayload!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Đã sao chép chuỗi mã QR vào clipboard',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF161920)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF2E3440)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        exp.qrPayload!,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color:
                valueColor ??
                (theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceBadge(String sourceType) {
    final (label, icon, color) = switch (sourceType.toLowerCase()) {
      'qr' => (
        'Xác thực từ mã QR',
        Icons.qr_code_rounded,
        const Color(0xFF2E7D32),
      ),
      'ocr' => (
        'Nhận diện từ ảnh (OCR)',
        Icons.document_scanner_rounded,
        const Color(0xFF1976D2),
      ),
      'hybrid' => (
        'Kết hợp QR + OCR',
        Icons.auto_awesome_rounded,
        const Color(0xFF7B1FA2),
      ),
      _ => ('Nhập thủ công', Icons.edit_note_rounded, Colors.grey.shade700),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(Expense exp) async {
    final merchantCtrl = TextEditingController(text: exp.merchant);
    final amountCtrl = TextEditingController(
      text: exp.amount.toStringAsFixed(0),
    );
    final noteCtrl = TextEditingController(text: exp.note);
    var selectedCat = exp.category;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Chỉnh sửa chi tiêu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: merchantCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cửa hàng / Người nhận',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số tiền (VND)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ExpenseCategory>(
                  value: selectedCat,
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  items: ExpenseCategory.values.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Icon(c.icon, size: 18, color: c.color),
                          const SizedBox(width: 8),
                          Text(c.vietnameseName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedCat = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amt =
                    double.tryParse(
                      amountCtrl.text.replaceAll(RegExp(r'[^\d.]'), ''),
                    ) ??
                    exp.amount;
                final updated = exp.copyWith(
                  merchant: merchantCtrl.text.trim().isNotEmpty
                      ? merchantCtrl.text.trim()
                      : exp.merchant,
                  amount: amt,
                  category: selectedCat,
                  note: noteCtrl.text.trim(),
                  updatedAt: DateTime.now(),
                );
                await ref
                    .read(expensesProvider.notifier)
                    .updateExpense(updated);
                setState(() {
                  _expense = updated;
                });
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Expense exp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "${exp.merchant}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(expensesProvider.notifier).deleteExpense(exp);
      if (mounted) {
        context.pop();
      }
    }
  }
}
