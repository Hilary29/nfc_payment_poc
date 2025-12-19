import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

/// Payload NFC pour le paiement
class NfcPaymentPayload {
  final String token;
  final String merchantId;

  const NfcPaymentPayload({
    required this.token,
    required this.merchantId,
  });

  /// Encode le payload en JSON pour le tag NDEF
  String toNdefPayload() {
    return jsonEncode({
      't': token,
      'm': merchantId,
    });
  }

  /// Décode un payload depuis le tag NDEF
  factory NfcPaymentPayload.fromNdefPayload(String payload) {
    final json = jsonDecode(payload) as Map<String, dynamic>;
    return NfcPaymentPayload(
      token: json['t'] as String,
      merchantId: json['m'] as String,
    );
  }
}

/// Service gérant les opérations NFC
class NfcService {
  // Type MIME personnalisé pour nos paiements
  static const String _mimeType = 'application/vnd.neero.payment';

  // Singleton
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  // Controllers pour les streams
  final _tagReadController = StreamController<NfcPaymentPayload>.broadcast();

  /// Stream notifiant quand un tag est lu (côté client)
  Stream<NfcPaymentPayload> get onTagRead => _tagReadController.stream;

  bool _isEmitting = false;
  bool _isReading = false;

  /// Vérifie si le NFC est disponible sur l'appareil
  Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      debugPrint('NFC availability check failed: $e');
      return false;
    }
  }

  /// Vérifie si on est sur iOS (pour gérer les limitations)
  bool get isIOS => Platform.isIOS;

  /// Vérifie si on est sur Android
  bool get isAndroid => Platform.isAndroid;

  /// Démarre la lecture NFC (côté client)
  Future<NfcPaymentPayload?> startReading({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_isReading) {
      debugPrint('NFC reading already in progress');
      return null;
    }

    _isReading = true;
    final completer = Completer<NfcPaymentPayload?>();
    Timer? timeoutTimer;

    try {
      // Configure le timeout
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          stopReading();
          completer.complete(null);
        }
      });

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final payload = await _readTag(tag);
            if (payload != null && !completer.isCompleted) {
              _tagReadController.add(payload);
              completer.complete(payload);
            }
          } catch (e) {
            debugPrint('Error reading NFC tag: $e');
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          } finally {
            await stopReading();
          }
        },
        onError: (error) async {
          debugPrint('NFC session error: $error');
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      );

      return await completer.future;
    } catch (e) {
      debugPrint('Failed to start NFC reading: $e');
      _isReading = false;
      return null;
    } finally {
      timeoutTimer?.cancel();
    }
  }

  /// Lit les données depuis un tag NFC
  Future<NfcPaymentPayload?> _readTag(NfcTag tag) async {
    final ndef = Ndef.from(tag);
    if (ndef == null) {
      debugPrint('Tag is not NDEF compatible');
      return null;
    }

    final cachedMessage = ndef.cachedMessage;
    if (cachedMessage == null || cachedMessage.records.isEmpty) {
      debugPrint('No NDEF message found');
      return null;
    }

    // Cherche notre record de paiement
    for (final record in cachedMessage.records) {
      // Vérifie le type MIME
      if (record.typeNameFormat == NdefTypeNameFormat.media) {
        final type = String.fromCharCodes(record.type);
        if (type == _mimeType) {
          final payload = String.fromCharCodes(record.payload);
          return NfcPaymentPayload.fromNdefPayload(payload);
        }
      }

      // Fallback: cherche dans les records texte
      if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
        try {
          // Skip le premier byte (language code length)
          final payload = String.fromCharCodes(record.payload.sublist(1));
          if (payload.startsWith('{')) {
            return NfcPaymentPayload.fromNdefPayload(payload);
          }
        } catch (e) {
          continue;
        }
      }
    }

    return null;
  }

  /// Arrête la lecture NFC
  Future<void> stopReading() async {
    if (!_isReading) return;

    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      debugPrint('Error stopping NFC session: $e');
    } finally {
      _isReading = false;
    }
  }

  /// Démarre l'émission NFC (côté marchand) - Android uniquement via HCE
  /// Note: Sur iOS, cette fonction retourne false car HCE n'est pas supporté
  Future<bool> startEmitting(NfcPaymentPayload payload) async {
    if (isIOS) {
      debugPrint('HCE not supported on iOS');
      return false;
    }

    if (_isEmitting) {
      debugPrint('NFC emitting already in progress');
      return false;
    }

    _isEmitting = true;

    try {
      // Sur Android, on utilise le mode écriture de tag
      // Le client viendra lire ce "tag virtuel"
      // Note: Pour un vrai HCE, il faudrait implémenter un service Android natif

      // Pour le POC, on simule en écrivant sur un tag physique
      // ou on utilise une approche simplifiée

      debugPrint('NFC emitting started with token: ${payload.token}');
      return true;
    } catch (e) {
      debugPrint('Failed to start NFC emitting: $e');
      _isEmitting = false;
      return false;
    }
  }

  /// Écrit un payload sur un tag NFC (alternative pour le POC)
  Future<bool> writeToTag(NfcPaymentPayload payload) async {
    if (_isReading) {
      await stopReading();
    }

    final completer = Completer<bool>();

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              debugPrint('Tag is not writable');
              completer.complete(false);
              return;
            }

            final message = NdefMessage([
              NdefRecord.createMime(
                _mimeType,
                utf8.encode(payload.toNdefPayload()),
              ),
            ]);

            await ndef.write(message);
            debugPrint('Successfully wrote to NFC tag');
            completer.complete(true);
          } catch (e) {
            debugPrint('Error writing to NFC tag: $e');
            completer.complete(false);
          } finally {
            await NfcManager.instance.stopSession();
          }
        },
        onError: (error) async {
          debugPrint('NFC session error: $error');
          completer.complete(false);
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          NfcManager.instance.stopSession();
          return false;
        },
      );
    } catch (e) {
      debugPrint('Failed to write NFC tag: $e');
      return false;
    }
  }

  /// Arrête l'émission NFC
  Future<void> stopEmitting() async {
    if (!_isEmitting) return;

    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      debugPrint('Error stopping NFC emitting: $e');
    } finally {
      _isEmitting = false;
    }
  }

  /// Getters d'état
  bool get isEmitting => _isEmitting;
  bool get isReading => _isReading;

  /// Libère les ressources
  void dispose() {
    stopReading();
    stopEmitting();
    _tagReadController.close();
  }
}