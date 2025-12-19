class PaymentResult {
  bool? success;
  String? transactionId;
  String? message;
  DateTime? timestamp;

  PaymentResult({
    this.success,
    this.transactionId,
    this.message,
    this.timestamp,
  });

  factory PaymentResult.successful({
    required String transactionId,
    String? message,
  }) {
    return PaymentResult(
      success: true,
      transactionId: transactionId,
      message: message ?? 'Paiement effectué avec succès',
      timestamp: DateTime.now(),
    );
  }

  factory PaymentResult.failed({
    required String message,
  }) {
    return PaymentResult(
      success: false,
      message: message,
      timestamp: DateTime.now(),
    );
  }

    factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'] as bool,
      transactionId: json['transactionId'] as String?,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'transactionId': transactionId,
      'message': message,
      'timestamp': timestamp?.toIso8601String()
    };
  }

  @override
  String toString() {
    return 'PaymentResult(success: $success, transactionId: $transactionId, message: $message)';
  }
  
}
