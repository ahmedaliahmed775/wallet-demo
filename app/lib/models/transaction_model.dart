import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class TransactionModel extends Equatable {
  final String id;
  final String type; // PAYMENT, TRANSFER, CASH_OUT, CASH_IN, REFUND, RECHARGE, BILL_PAYMENT
  final String status; // PENDING, COMPLETED, FAILED, EXPIRED, REVERSED, CANCELLED
  final String? senderWalletId;
  final String? receiverWalletId;
  final double amount;
  final double fee;
  final double netAmount;
  final String currency;
  final String? referenceNo;
  final String? transactionRef;
  final String? description;
  final String? notes;
  final bool isIdentityHidden;
  final DateTime createdAt;
  // Extra fields from API joins
  final String? senderName;
  final String? receiverName;
  final String? senderPhone;
  final String? receiverPhone;

  TransactionModel({
    required this.id,
    required this.type,
    required this.status,
    this.senderWalletId,
    this.receiverWalletId,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.currency,
    this.referenceNo,
    this.transactionRef,
    this.description,
    this.notes,
    this.isIdentityHidden = false,
    required this.createdAt,
    this.senderName,
    this.receiverName,
    this.senderPhone,
    this.receiverPhone,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: (json['id'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'PAYMENT',
      status: (json['status'] as String?) ?? 'PENDING',
      senderWalletId: json['senderWalletId'] as String?,
      receiverWalletId: json['receiverWalletId'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      netAmount: json['netAmount'] != null
          ? (json['netAmount'] as num).toDouble()
          : 0.0,
      currency: (json['currency'] as String?) ?? 'YER',
      referenceNo: json['referenceNo'] as String?,
      transactionRef: json['transactionRef'] as String?,
      description: json['description'] as String?,
      notes: json['notes'] as String?,
      isIdentityHidden: json['isIdentityHidden'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      senderName: json['senderName'] as String?,
      receiverName: json['receiverName'] as String?,
      senderPhone: json['senderPhone'] as String?,
      receiverPhone: json['receiverPhone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'status': status,
      'senderWalletId': senderWalletId,
      'receiverWalletId': receiverWalletId,
      'amount': amount,
      'fee': fee,
      'netAmount': netAmount,
      'currency': currency,
      'referenceNo': referenceNo,
      'transactionRef': transactionRef,
      'description': description,
      'notes': notes,
      'isIdentityHidden': isIdentityHidden,
      'createdAt': createdAt.toIso8601String(),
      'senderName': senderName,
      'receiverName': receiverName,
      'senderPhone': senderPhone,
      'receiverPhone': receiverPhone,
    };
  }

  /// Whether this transaction is outgoing from the current user's perspective.
  /// For simplicity, we consider PAYMENT, CASH_OUT, and TRANSFER with senderWalletId as outgoing.
  @override
  List<Object?> get props => [
        id, type, status, senderWalletId, receiverWalletId,
        amount, fee, netAmount, currency, referenceNo,
        transactionRef, description, notes, isIdentityHidden,
        createdAt, senderName, receiverName, senderPhone, receiverPhone,
      ];

  bool get isOutgoing =>
      type == 'PAYMENT' ||
      type == 'CASH_OUT' ||
      (type == 'TRANSFER' && senderWalletId != null);

  bool get isIncome =>
      type == 'CASH_IN' ||
      type == 'RECHARGE' ||
      (type == 'REFUND');

  String get typeAr {
    switch (type) {
      case 'PAYMENT':
        return 'دفع إلكتروني';
      case 'TRANSFER':
        return 'تحويل';
      case 'CASH_OUT':
        return 'سحب نقدي';
      case 'CASH_IN':
        return 'إيداع نقدي';
      case 'REFUND':
        return 'استرجاع';
      case 'RECHARGE':
        return 'شحن رصيد';
      case 'BILL_PAYMENT':
        return 'سداد فاتورة';
      default:
        return type;
    }
  }

  String get statusAr {
    switch (status) {
      case 'PENDING':
        return 'معلق';
      case 'COMPLETED':
        return 'مكتمل';
      case 'FAILED':
        return 'فاشل';
      case 'EXPIRED':
        return 'منتهي';
      case 'REVERSED':
        return 'معكوس';
      case 'CANCELLED':
        return 'ملغي';
      default:
        return status;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'PAYMENT':
        return Icons.payment;
      case 'TRANSFER':
        return Icons.swap_horiz;
      case 'CASH_OUT':
        return Icons.money_off;
      case 'CASH_IN':
        return Icons.attach_money;
      case 'REFUND':
        return Icons.refresh;
      case 'RECHARGE':
        return Icons.phone_android;
      case 'BILL_PAYMENT':
        return Icons.receipt_long;
      default:
        return Icons.receipt;
    }
  }

  /// Get the counterparty name for display.
  String get counterpartyName {
    if (isOutgoing) {
      if (isIdentityHidden) return 'مستخدم مخفي';
      return receiverName ?? receiverPhone ?? description ?? '';
    } else {
      if (isIdentityHidden) return 'مستخدم مخفي';
      return senderName ?? senderPhone ?? description ?? '';
    }
  }

  TransactionModel copyWith({
    String? id,
    String? type,
    String? status,
    String? senderWalletId,
    String? receiverWalletId,
    double? amount,
    double? fee,
    double? netAmount,
    String? currency,
    String? referenceNo,
    String? transactionRef,
    String? description,
    String? notes,
    bool? isIdentityHidden,
    DateTime? createdAt,
    String? senderName,
    String? receiverName,
    String? senderPhone,
    String? receiverPhone,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      senderWalletId: senderWalletId ?? this.senderWalletId,
      receiverWalletId: receiverWalletId ?? this.receiverWalletId,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      netAmount: netAmount ?? this.netAmount,
      currency: currency ?? this.currency,
      referenceNo: referenceNo ?? this.referenceNo,
      transactionRef: transactionRef ?? this.transactionRef,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      isIdentityHidden: isIdentityHidden ?? this.isIdentityHidden,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      receiverName: receiverName ?? this.receiverName,
      senderPhone: senderPhone ?? this.senderPhone,
      receiverPhone: receiverPhone ?? this.receiverPhone,
    );
  }
}
