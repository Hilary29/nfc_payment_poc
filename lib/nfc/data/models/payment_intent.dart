import 'package:nfc_payment_poc/nfc/data/models/payment_status.dart';

class PaymentIntent {
  final String id;
  final String token;
  final double amount;
  final String currency;
  final String merchantId;
  final String merchantName;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  const PaymentIntent({
    required this.id,
    required this.token,
    required this.amount,
    required this.currency,
    required this.merchantId,
    required this.merchantName,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    return PaymentIntent(
      id: json['id'],
      token: json['token'],
      amount: json['amount'],
      currency: json['currency'],
      merchantId: json['merchantId'],
      merchantName: json['merchantName'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token': token,
      'amount': amount,
      'currency': currency,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }


  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get formattedAmount {
    final value = amount / 100;
    return '${value.toStringAsFixed(0)} $currency';
  }

    @override
  String toString() {
    return 'PaymentIntent(id: $id, token: $token, amount: $formattedAmount, status: ${status.toString()})';
  }

  PaymentIntent copyWith({PaymentStatus? status}) {
    return PaymentIntent(
      id: id,
      token: token,
      amount: amount,
      currency: currency,
      merchantId: merchantId,
      merchantName: merchantName,
      status: status ?? this.status,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }
}
