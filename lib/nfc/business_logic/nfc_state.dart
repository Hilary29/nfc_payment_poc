import 'package:equatable/equatable.dart';
import 'package:nfc_payment_poc/nfc/data/models/payment_intent.dart';
import 'package:nfc_payment_poc/nfc/data/models/payment_result.dart';

abstract class NfcState extends Equatable {
  final PaymentIntent? currentPaymentIntent;
  final PaymentResult? paymentResult;
  final String? errorMessage;

  const NfcState({
    this.currentPaymentIntent,
    this.paymentResult,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [currentPaymentIntent, paymentResult, errorMessage];
}

class NfcInitialState extends NfcState {
  const NfcInitialState()
      : super(
          currentPaymentIntent: null,
          paymentResult: null,
          errorMessage: null,
        );
}

class NfcLoadingState extends NfcState {
  const NfcLoadingState({
    PaymentIntent? currentPaymentIntent,
    PaymentResult? paymentResult,
  }) : super(
          currentPaymentIntent: currentPaymentIntent,
          paymentResult: paymentResult,
        );
}

class PaymentIntentCreatedState extends NfcState {
  const PaymentIntentCreatedState({
    required PaymentIntent paymentIntent,
  }) : super(currentPaymentIntent: paymentIntent);
}

class NfcEmittingState extends NfcState {
  const NfcEmittingState({
    required PaymentIntent paymentIntent,
  }) : super(currentPaymentIntent: paymentIntent);
}

class NfcScanningState extends NfcState {
  const NfcScanningState({
    PaymentIntent? currentPaymentIntent,
  }) : super(currentPaymentIntent: currentPaymentIntent);
}

class PaymentIntentReadState extends NfcState {
  const PaymentIntentReadState({
    required PaymentIntent paymentIntent,
  }) : super(currentPaymentIntent: paymentIntent);
}

class PaymentValidatedState extends NfcState {
  const PaymentValidatedState({
    required PaymentIntent paymentIntent,
    required PaymentResult result,
  }) : super(
          currentPaymentIntent: paymentIntent,
          paymentResult: result,
        );
}

class NfcErrorState extends NfcState {
  const NfcErrorState({
    required String error,
    PaymentIntent? currentPaymentIntent,
    PaymentResult? paymentResult,
  }) : super(
          currentPaymentIntent: currentPaymentIntent,
          paymentResult: paymentResult,
          errorMessage: error,
        );
}
