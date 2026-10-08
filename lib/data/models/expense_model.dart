import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/category_constants.dart';

@immutable
class Expense {
  final String? id; // Cloud Firestore Document ID
  final double amount;
  final String merchant;
  final String? recipient;
  final ExpenseCategory category;
  final DateTime date;
  final String? transactionTime; // e.g. '17:53'
  final String? bank; // e.g. 'MBBank (MB)'
  final String? accountNumber; // e.g. '41212106082002'
  final String note;
  final String paymentMethod;
  final String? qrPayload;
  final String sourceType; // 'qr', 'ocr', 'hybrid', 'manual'
  final String? imageUrl; // Firebase Storage download URL
  final String?
  imagePath; // Firebase Storage storage reference path / local path
  final DateTime createdAt;
  final DateTime updatedAt;

  const Expense({
    this.id,
    required this.amount,
    required this.merchant,
    this.recipient,
    required this.category,
    required this.date,
    this.transactionTime,
    this.bank,
    this.accountNumber,
    this.note = '',
    this.paymentMethod = 'QR Payment',
    this.qrPayload,
    this.sourceType = 'manual',
    this.imageUrl,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  String get effectiveRecipient =>
      (recipient != null && recipient!.trim().isNotEmpty)
      ? recipient!.trim()
      : merchant;

  Expense copyWith({
    String? id,
    double? amount,
    String? merchant,
    String? recipient,
    ExpenseCategory? category,
    DateTime? date,
    String? transactionTime,
    String? bank,
    String? accountNumber,
    String? note,
    String? paymentMethod,
    String? qrPayload,
    String? sourceType,
    String? imageUrl,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      recipient: recipient ?? this.recipient,
      category: category ?? this.category,
      date: date ?? this.date,
      transactionTime: transactionTime ?? this.transactionTime,
      bank: bank ?? this.bank,
      accountNumber: accountNumber ?? this.accountNumber,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      qrPayload: qrPayload ?? this.qrPayload,
      sourceType: sourceType ?? this.sourceType,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Chuyển đổi dữ liệu sang Map chuẩn lưu trữ Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'merchant': merchant,
      'recipient': effectiveRecipient,
      'category': category.name,
      'date': Timestamp.fromDate(date),
      'transactionTime': transactionTime,
      'bank': bank,
      'accountNumber': accountNumber,
      'note': note,
      'paymentMethod': paymentMethod,
      'qrPayload': qrPayload,
      'sourceType': sourceType,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Hỗ trợ chuyển đổi sang Map thông thường (cho test và JSON)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'merchant': merchant,
      'recipient': effectiveRecipient,
      'category': category.name,
      'date': date.toIso8601String(),
      'transaction_time': transactionTime,
      'bank': bank,
      'account_number': accountNumber,
      'note': note,
      'payment_method': paymentMethod,
      'qr_payload': qrPayload,
      'source_type': sourceType,
      'image_url': imageUrl,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Tái tạo Expense từ Map hoặc Firestore Document
  factory Expense.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawDate = map['date'];
    final DateTime parsedDate = switch (rawDate) {
      Timestamp() => rawDate.toDate(),
      String() => DateTime.tryParse(rawDate) ?? DateTime.now(),
      DateTime() => rawDate,
      _ => DateTime.now(),
    };

    final rawCreatedAt = map['createdAt'] ?? map['created_at'];
    final DateTime parsedCreatedAt = switch (rawCreatedAt) {
      Timestamp() => rawCreatedAt.toDate(),
      String() => DateTime.tryParse(rawCreatedAt) ?? DateTime.now(),
      DateTime() => rawCreatedAt,
      _ => DateTime.now(),
    };

    final rawUpdatedAt = map['updatedAt'] ?? map['updated_at'];
    final DateTime parsedUpdatedAt = switch (rawUpdatedAt) {
      Timestamp() => rawUpdatedAt.toDate(),
      String() => DateTime.tryParse(rawUpdatedAt) ?? DateTime.now(),
      DateTime() => rawUpdatedAt,
      _ => DateTime.now(),
    };

    return Expense(
      id: id ?? map['id']?.toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      merchant: map['merchant'] as String? ?? 'Chưa rõ',
      recipient: map['recipient'] as String?,
      category: ExpenseCategory.fromString(map['category'] as String?),
      date: parsedDate,
      transactionTime:
          map['transactionTime'] as String? ??
          map['transaction_time'] as String?,
      bank: map['bank'] as String?,
      accountNumber:
          map['accountNumber'] as String? ?? map['account_number'] as String?,
      note: map['note'] as String? ?? '',
      paymentMethod:
          map['paymentMethod'] as String? ??
          map['payment_method'] as String? ??
          'QR Payment',
      qrPayload: map['qrPayload'] as String? ?? map['qr_payload'] as String?,
      sourceType:
          map['sourceType'] as String? ??
          map['source_type'] as String? ??
          'manual',
      imageUrl: map['imageUrl'] as String? ?? map['image_url'] as String?,
      imagePath: map['imagePath'] as String? ?? map['image_path'] as String?,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Khởi tạo từ Map dữ liệu và Document ID của Cloud Firestore
  factory Expense.fromFirestore(Map<String, dynamic> data, String id) {
    return Expense.fromMap(data, id: id);
  }

  /// Khởi tạo trực tiếp từ DocumentSnapshot của Cloud Firestore
  factory Expense.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return Expense.fromMap(data, id: snapshot.id);
  }

  /// Số tài khoản được che mờ bảo mật dạng '********2002'
  String? get maskedAccountNumber {
    if (accountNumber == null || accountNumber!.trim().isEmpty) return null;
    final acc = accountNumber!.trim();
    if (acc.length <= 4) return '****$acc';
    final suffix = acc.substring(acc.length - 4);
    return '********$suffix';
  }

  String get sourceBadgeText {
    return switch (sourceType.toLowerCase()) {
      'qr' => 'Mã QR xác thực',
      'ocr' => 'Nhận diện OCR',
      'hybrid' => 'Kết hợp QR + OCR',
      _ => 'Nhập thủ công',
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          amount == other.amount &&
          merchant == other.merchant &&
          category == other.category &&
          date == other.date &&
          transactionTime == other.transactionTime &&
          bank == other.bank &&
          accountNumber == other.accountNumber &&
          note == other.note &&
          paymentMethod == other.paymentMethod &&
          qrPayload == other.qrPayload &&
          sourceType == other.sourceType &&
          imageUrl == other.imageUrl &&
          imagePath == other.imagePath;

  @override
  int get hashCode =>
      id.hashCode ^
      amount.hashCode ^
      merchant.hashCode ^
      category.hashCode ^
      date.hashCode ^
      transactionTime.hashCode ^
      bank.hashCode ^
      accountNumber.hashCode ^
      note.hashCode ^
      paymentMethod.hashCode ^
      qrPayload.hashCode ^
      sourceType.hashCode ^
      imageUrl.hashCode ^
      imagePath.hashCode;
}
