import 'package:equatable/equatable.dart';

abstract class NfcEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CreatePaymentIntentEvent extends NfcEvent {
  final double amount;
  final String merchantId;
  final String merchantName;
  final String currency;

  CreatePaymentIntentEvent({
    required this.amount,
    required this.merchantId,
    required this.merchantName,
    this.currency = 'XAF',
  });

  @override
  List<Object?> get props => [amount, merchantId, merchantName, currency];
}

class StartNfcEmissionEvent extends NfcEvent {
  final String paymentIntentId;

  StartNfcEmissionEvent({required this.paymentIntentId});

  @override
  List<Object?> get props => [paymentIntentId];
}

class WriteToTagEvent extends NfcEvent {
  final String paymentIntentId;

  WriteToTagEvent({required this.paymentIntentId});

  @override
  List<Object?> get props => [paymentIntentId];
}

class StopNfcEmissionEvent extends NfcEvent {}

class StartNfcScanEvent extends NfcEvent {}

class StopNfcScanEvent extends NfcEvent {}

class PaymentIntentReadEvent extends NfcEvent {
  final String token;

  PaymentIntentReadEvent({required this.token});

  @override
  List<Object?> get props => [token];
}

class ValidatePaymentEvent extends NfcEvent {
  final String paymentIntentId;
  final bool authorized;
  final String? reason;

  ValidatePaymentEvent({
    required this.paymentIntentId,
    required this.authorized,
    this.reason,
  });

  @override
  List<Object?> get props => [paymentIntentId, authorized, reason];
}

class CancelPaymentEvent extends NfcEvent {}

class ResetNfcEvent extends NfcEvent {}
