import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/category_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/expense_model.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/scanner_provider.dart';
import '../models/scan_result.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';

class ReviewExpenseScreen extends ConsumerStatefulWidget {
  const ReviewExpenseScreen({super.key});

  @override
  ConsumerState<ReviewExpenseScreen> createState() =>
      _ReviewExpenseScreenState();
}

class _ReviewExpenseScreenState extends ConsumerState<ReviewExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  late TextEditingController _amountController;
  late TextEditingController _recipientController;
  late TextEditingController _bankController;
  late TextEditingController _accountController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _noteController;

  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _recipientFocusNode = FocusNode();
  final FocusNode _bankFocusNode = FocusNode();
  final FocusNode _accountFocusNode = FocusNode();
  final FocusNode _timeFocusNode = FocusNode();
  final FocusNode _noteFocusNode = FocusNode();

  late ExpenseCategory _selectedCategory;
  late DateTime _selectedDate;
  bool _isSaving = false;
  bool _showFullAccount = false;

  @override
  void initState() {
    super.initState();
    final scanResult = ref.read(scannerProvider).result;

    final initialAmount = scanResult?.amount != null && scanResult!.amount! > 0
        ? CurrencyFormatter.formatNumber(scanResult.amount!)
        : '';
    final initialRecipient = scanResult?.merchant ?? '';
    final initialBank = scanResult?.bankName ?? '';
    final initialAccount = scanResult?.accountNumber ?? '';
    final initialTime = scanResult?.transactionTime ?? '';
    final initialNote = scanResult?.note ?? '';

    _amountController = TextEditingController(text: initialAmount);
    _recipientController = TextEditingController(text: initialRecipient);
    _bankController = TextEditingController(text: initialBank);
    _accountController = TextEditingController(text: initialAccount);
    _timeController = TextEditingController(text: initialTime);
    _noteController = TextEditingController(text: initialNote);

    _selectedDate = scanResult?.date ?? DateTime.now();
    _dateController = TextEditingController(
      text: DateFormatter.format(_selectedDate),
    );

    _selectedCategory = ExpenseCategory.suggestFromText(
      '$initialRecipient $initialNote',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _noteController.dispose();

    _amountFocusNode.dispose();
    _recipientFocusNode.dispose();
    _bankFocusNode.dispose();
    _accountFocusNode.dispose();
    _timeFocusNode.dispose();
    _noteFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormatter.format(picked);
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng kiểm tra lại các trường thông tin còn thiếu hoặc chưa hợp lệ!',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final scanResult = ref.read(scannerProvider).result;
    final amount = CurrencyFormatter.parseAmount(_amountController.text) ?? 0.0;

    setState(() {
      _isSaving = true;
    });

    final expense = Expense(
      amount: amount,
      merchant: _recipientController.text.trim(),
      recipient: _recipientController.text.trim(),
      category: _selectedCategory,
      date: _selectedDate,
      transactionTime: _timeController.text.trim().isNotEmpty
          ? _timeController.text.trim()
          : null,
      bank: _bankController.text.trim().isNotEmpty
          ? _bankController.text.trim()
          : null,
      accountNumber: _accountController.text.trim().isNotEmpty
          ? _accountController.text.trim()
          : null,
      note: _noteController.text.trim(),
      paymentMethod: 'QR Payment',
      qrPayload: scanResult?.qrPayload,
      sourceType: scanResult?.sourceType ?? 'manual',
      imagePath: scanResult?.imagePath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      File? imageFile;
      final localImgPath = scanResult?.imagePath;
      if (localImgPath != null && localImgPath.isNotEmpty) {
        final f = File(localImgPath);
        if (await f.exists()) {
          imageFile = f;
        }
      }

      await ref
          .read(expensesProvider.notifier)
          .addExpense(expense, imageFile: imageFile)
          .timeout(
            const Duration(seconds: 4),
            onTimeout: () => expense.id ?? 'exp_${DateTime.now().millisecondsSinceEpoch}',
          );

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ref.read(scannerProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu chi tiêu thành công!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể lưu chi tiêu lên Firebase: $e. Vui lòng kiểm tra kết nối mạng.',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scanResult = ref.watch(scannerProvider).result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm tra giao dịch'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ref.read(scannerProvider.notifier).reset();
            context.go('/');
          },
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Detection Source Banner
              _buildDetectionBanner(theme, scanResult),
              const SizedBox(height: 16),

              // 2. Image Preview Card (if available)
              if (scanResult?.imagePath != null &&
                  File(scanResult!.imagePath!).existsSync()) ...[
                AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(scanResult.imagePath!),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ảnh giao dịch thanh toán',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lưu trữ cục bộ bảo mật trên thiết bị',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Amount Field
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Số tiền *',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (scanResult?.amountSource != null)
                          _buildFieldSourceTag(scanResult!.amountSource!),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      keyboardType: TextInputType.number,
                      validator: Validators.validateAmount,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                      decoration: const InputDecoration(
                        hintText: '1,000,000',
                        prefixIcon: Icon(Icons.payments_rounded),
                        suffixText: 'VND',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Recipient / Merchant Field
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Người nhận *',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (scanResult?.merchantSource != null)
                          _buildFieldSourceTag(scanResult!.merchantSource!),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _recipientController,
                      focusNode: _recipientFocusNode,
                      validator: Validators.validateMerchant,
                      decoration: const InputDecoration(
                        hintText: 'Ví dụ: NGUYEN THI THUONG, Highlands...',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = ExpenseCategory.suggestFromText(
                            '$val ${_noteController.text}',
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 5. Bank & Account Number Card
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngân hàng',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bankController,
                      focusNode: _bankFocusNode,
                      decoration: const InputDecoration(
                        hintText: 'Ví dụ: MBBank (MB), Vietcombank...',
                        prefixIcon: Icon(Icons.account_balance_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Số tài khoản',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (_accountController.text.isNotEmpty)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showFullAccount = !_showFullAccount;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _showFullAccount
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _showFullAccount ? 'Che số' : 'Hiện số',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _accountController,
                      focusNode: _accountFocusNode,
                      obscureText:
                          !_showFullAccount &&
                          _accountController.text.length > 4,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: 41212106082002',
                        prefixIcon: const Icon(Icons.credit_card_rounded),
                        helperText: _accountController.text.isNotEmpty
                            ? 'Mã hóa an toàn: ${_maskAccount(_accountController.text)}'
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 6. Date & Time Row Card
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Date Selector
                    InkWell(
                      onTap: _selectDate,
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 20),
                          const SizedBox(width: 12),
                          const Text(
                            'Ngày giao dịch *',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            _dateController.text,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, size: 20),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    // Time Field
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          'Thời gian',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: TextFormField(
                            controller: _timeController,
                            focusNode: _timeFocusNode,
                            validator: Validators.validateTime,
                            textAlign: TextAlign.end,
                            decoration: const InputDecoration(
                              hintText: 'HH:mm (VD: 17:53)',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: UnderlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 7. Transfer Description / Note Field
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nội dung chuyển khoản',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteController,
                      focusNode: _noteFocusNode,
                      maxLines: 2,
                      validator: Validators.validateNote,
                      decoration: const InputDecoration(
                        hintText: 'Ví dụ: NGUYEN THI HUYEN chuyen tien...',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 8. Category Selection Card
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.category_rounded, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Danh mục *',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _selectedCategory.vietnameseName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _selectedCategory.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ExpenseCategory.values.map((cat) {
                        final isSelected = cat == _selectedCategory;
                        return ChoiceChip(
                          avatar: Icon(
                            cat.icon,
                            size: 16,
                            color: isSelected ? Colors.white : cat.color,
                          ),
                          label: Text(cat.vietnameseName),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontWeight: isSelected ? FontWeight.w700 : null,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 9. View Raw QR Data Button (if QR detected)
              if (scanResult?.qrPayload != null &&
                  scanResult!.qrPayload!.isNotEmpty) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: const Text('Xem chuỗi mã QR gốc'),
                  onPressed: () =>
                      _showRawQrBottomSheet(context, scanResult.qrPayload!),
                ),
                const SizedBox(height: 20),
              ],

              // 10. Save Button
              AppButton(
                label: 'LƯU CHI TIÊU',
                icon: Icons.check_circle_rounded,
                isLoading: _isSaving,
                onPressed: _saveExpense,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _maskAccount(String raw) {
    if (raw.length <= 4) return '****$raw';
    return '********${raw.substring(raw.length - 4)}';
  }

  Widget _buildDetectionBanner(ThemeData theme, ScanResult? result) {
    final sourceType = result?.sourceType ?? 'manual';
    final (title, subtitle, icon, color) = switch (sourceType.toLowerCase()) {
      'qr' => (
        'Mã QR xác thực',
        'Đã trích xuất số tiền và thông tin giao dịch từ mã QR thanh toán.',
        Icons.verified_rounded,
        const Color(0xFF2E7D32),
      ),
      'ocr' => (
        'Nhận diện OCR (Fallback)',
        'Đã phân tích văn bản ảnh chuyển khoản bằng Google ML Kit on-device.',
        Icons.document_scanner_rounded,
        const Color(0xFF1976D2),
      ),
      'hybrid' => (
        'Kết hợp QR + OCR',
        'Ưu tiên số tiền từ mã QR, bổ sung người nhận/thời gian từ ảnh biên lai.',
        Icons.auto_awesome_rounded,
        const Color(0xFF7B1FA2),
      ),
      _ => (
        'Nhập thủ công',
        'Vui lòng nhập và kiểm tra các thông tin chi tiêu bên dưới.',
        Icons.edit_note_rounded,
        Colors.grey.shade700,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldSourceTag(String source) {
    final color = source.toUpperCase() == 'QR'
        ? const Color(0xFF2E7D32)
        : const Color(0xFF1976D2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
      ),
      child: Text(
        'Từ $source',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showRawQrBottomSheet(BuildContext context, String payload) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_2_rounded),
                const SizedBox(width: 10),
                const Text(
                  'Chuỗi mã QR gốc',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'Sao chép',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: payload));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép chuỗi QR!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                payload,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
