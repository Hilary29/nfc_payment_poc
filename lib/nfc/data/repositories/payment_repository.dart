import 'package:nfc_payment_poc/nfc/data/models/payment_intent.dart';
import 'package:nfc_payment_poc/nfc/data/models/payment_result.dart';
import 'package:nfc_payment_poc/nfc/data/models/payment_status.dart';
import 'package:nfc_payment_poc/nfc/data/services/mock_payment_service.dart';
import 'package:nfc_payment_poc/nfc/data/services/nfc_service.dart';

class PaymentRepository {
  final MockPaymentService _paymentService;
  final NfcService _nfcService;

  PaymentRepository({
    MockPaymentService? paymentService,
    NfcService? nfcService,
  })  : _paymentService = paymentService ?? MockPaymentService(),
        _nfcService = nfcService ?? NfcService();

  /// Vérifie si le NFC est disponible
  Future<bool> isNfcAvailable() => _nfcService.isAvailable();

  Future<PaymentIntent> createPaymentIntent({
    required double amount,
    String currency = 'XAF',
    String? merchantId,
    String? merchantName,
  }) async {
    return _paymentService.createPaymentIntent(
      amount: amount,
      currency: currency,
      merchantId: merchantId,
      merchantName: merchantName,
    );
  }

  /// Démarre l'émission NFC du token (marchand)
  Future<bool> startNfcEmission(PaymentIntent paymentIntent) async {
    // Marque comme exposé dans le backend
    await _paymentService.markAsExposed(paymentIntent.token);

    // Démarre l'émission NFC
    final payload = NfcPaymentPayload(
      token: paymentIntent.token,
      merchantId: paymentIntent.merchantId,
    );

    return _nfcService.startEmitting(payload);
  }

  /// Écrit le PaymentIntent sur un tag NFC physique (alternative POC)
  Future<bool> writePaymentToTag(PaymentIntent paymentIntent) async {
    final payload = NfcPaymentPayload(
      token: paymentIntent.token,
      merchantId: paymentIntent.merchantId,
    );

    final success = await _nfcService.writeToTag(payload);

    if (success) {
      await _paymentService.markAsExposed(paymentIntent.token);
    }

    return success;
  }

  /// Arrête l'émission NFC
  Future<void> stopNfcEmission() => _nfcService.stopEmitting();

  /// Récupère le statut actuel d'un paiement (polling)
  Future<PaymentStatus?> getPaymentStatus(String token) {
    return _paymentService.getPaymentStatus(token);
  }

  /// Annule un PaymentIntent
  Future<bool> cancelPaymentIntent(String token) {
    return _paymentService.cancelPaymentIntent(token);
  }
 /// Démarre le scan NFC (client)
  Future<String?> startNfcScan({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final payload = await _nfcService.startReading(timeout: timeout);
    return payload?.token;
  }

  Future<void> stopNfcScan() => _nfcService.stopReading();

  Future<PaymentIntent?> getPaymentIntent(String token) async {
    final paymentIntent = await _paymentService.getPaymentIntent(token);

    if (paymentIntent != null) {
      await _paymentService.markAsRead(token);
    }

    return paymentIntent;
  }

  Future<PaymentResult> validatePayment(String token) {
    return _paymentService.validatePayment(token);
  }


  /// Stream des tags lus 
  Stream<NfcPaymentPayload> get onTagRead => _nfcService.onTagRead;

  /// État de lecture NFC
  bool get isReading => _nfcService.isReading;

  /// État d'émission NFC
  bool get isEmitting => _nfcService.isEmitting;

  /// Libère les ressources
  void dispose() {
    _nfcService.dispose();
  }
}