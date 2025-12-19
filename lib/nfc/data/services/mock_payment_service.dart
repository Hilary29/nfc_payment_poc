import 'dart:math';

import 'package:nfc_payment_poc/nfc/data/models/payment_intent.dart';
import 'package:nfc_payment_poc/nfc/data/models/payment_result.dart';
import 'package:nfc_payment_poc/nfc/data/models/payment_status.dart';

/// Service mock simulant le backend 
class MockPaymentService {
  final Map<String, PaymentIntent> _paymentIntents = {};

  static const String _mockMerchantId = 'merchant_001';
  static const String _mockMerchantName = 'Boutique 1';
  static const Duration _paymentIntentTTL = Duration(minutes: 2);

  final Random _random = Random();

  String _generateToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  String _generateId() {
    return 'pi_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}';
  }

  String _generateTransactionId() {
    return 'txn_${DateTime.now().millisecondsSinceEpoch}';
  }


  Future<PaymentIntent> createPaymentIntent({
    required double amount,
    String currency = 'XAF',
    String? merchantId,
    String? merchantName,
  }) async {
    final now = DateTime.now();
    final paymentIntent = PaymentIntent(
      id: _generateId(),
      token: _generateToken(),
      amount: amount,
      currency: currency,
      merchantId: merchantId ?? _mockMerchantId,
      merchantName: merchantName ?? _mockMerchantName,
      status: PaymentStatus.CREATED,
      createdAt: now,
      expiresAt: now.add(_paymentIntentTTL),
    );

    _paymentIntents[paymentIntent.token] = paymentIntent;

    return paymentIntent;
  }

  Future<PaymentIntent?> getPaymentIntent(String token) async {

    final paymentIntent = _paymentIntents[token];

    if (paymentIntent == null) {
      return null;
    }

    // Vérifie l'expiration
    if (paymentIntent.isExpired) {
      final expired = paymentIntent.copyWith(status: PaymentStatus.EXPIRED);
      _paymentIntents[token] = expired;
      return expired;
    }

    // Met à jour le statut si c'était EXPOSED
    if (paymentIntent.status == PaymentStatus.EXPOSED) {
      final read = paymentIntent.copyWith(status: PaymentStatus.READ);
      _paymentIntents[token] = read;
      return read;
    }

    return paymentIntent;
  }

  /// Marque le PaymentIntent comme exposé via NFC
  Future<PaymentIntent?> markAsExposed(String token) async {

    final paymentIntent = _paymentIntents[token];
    if (paymentIntent == null) return null;

    final exposed = paymentIntent.copyWith(status: PaymentStatus.EXPOSED);
    _paymentIntents[token] = exposed;
    return exposed;
  }

  /// Marque le PaymentIntent comme lu par le client
  Future<PaymentIntent?> markAsRead(String token) async {

    final paymentIntent = _paymentIntents[token];
    if (paymentIntent == null) return null;

    final read = paymentIntent.copyWith(status: PaymentStatus.READ);
    _paymentIntents[token] = read;
    return read;
  }

  /// Valide le paiement (appelé par le client après authentification)
  Future<PaymentResult> validatePayment(String token) async {

    final paymentIntent = _paymentIntents[token];

    // Vérifications
    if (paymentIntent == null) {
      return PaymentResult.failed(
        message: 'Paiement introuvable',
      );
    }

    if (paymentIntent.isExpired) {
      _paymentIntents[token] = paymentIntent.copyWith(
        status: PaymentStatus.EXPIRED,
      );
      return PaymentResult.failed(
        message: 'Ce paiement a expiré',
      );
    }

    if (paymentIntent.status == PaymentStatus.AUTHORIZED) {
      return PaymentResult.failed(
        message: 'Ce paiement a déjà été effectué',
      );
    }


    if (paymentIntent.status == PaymentStatus.READ) {
      _paymentIntents[token] = paymentIntent.copyWith(
        status: PaymentStatus.AUTHORIZED,
      );
      return PaymentResult.successful(
        transactionId: _generateTransactionId(),
        message: 'Paiement de ${paymentIntent.formattedAmount} effectué',
      );
    } else {
      _paymentIntents[token] = paymentIntent.copyWith(
        status: PaymentStatus.DECLINED,
      );
      return PaymentResult.failed(
        message: 'Solde insuffisant',
      );
    }
  }

  /// Récupère le statut actuel d'un PaymentIntent (polling marchand)
  Future<PaymentStatus?> getPaymentStatus(String token) async {
    return _paymentIntents[token]?.status;
  }

  /// Annule un PaymentIntent
  Future<bool> cancelPaymentIntent(String token) async {
    final paymentIntent = _paymentIntents[token];
    if (paymentIntent == null) return false;

    _paymentIntents.remove(token);
    return true;
  }

  void cleanExpired() {
    _paymentIntents.removeWhere((_, pi) => pi.isExpired);
  }

  /// liste tous les PaymentIntents
  List<PaymentIntent> get allPaymentIntents => _paymentIntents.values.toList();
}