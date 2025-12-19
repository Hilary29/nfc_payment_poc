import 'package:nfc_payment_poc/nfc/data/models/payment_status.dart';

class PaymentIntent {
  String? id;
  double? amount;
  String? currency;
  String? merchantId;
  PaymentStatus? status;

  PaymentIntent({
    required this.id,
    required this.amount,
    required this.currency,
    required this.merchantId,
    required this.status,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    return PaymentIntent(
      id: json['id'],
      amount: json['amount'],
      currency: json['currency'],
      merchantId: json['merchantId'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'merchantId': merchantId,
      'status': status,
    };
  }
}


