import 'transaction_party_model.dart';

/// Model representing a receipt for a completed transaction.
class ReceiptModel {
  final String referenceNo;
  final String type;
  final String status;
  final double amount;
  final double fee;
  final double? netAmount;
  final String currency;
  final String? description;
  final String? notes;
  final String? posNumber;
  final DateTime date;
  final TransactionParty? sender;
  final TransactionParty? receiver;

  const ReceiptModel({
    required this.referenceNo,
    required this.type,
    required this.status,
    required this.amount,
    required this.fee,
    this.netAmount,
    required this.currency,
    this.description,
    this.notes,
    this.posNumber,
    required this.date,
    this.sender,
    this.receiver,
  });

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
      default:
        return status;
    }
  }
}
