import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nfc_payment_poc/nfc/business_logic/nfc_event.dart';
import 'package:nfc_payment_poc/nfc/business_logic/nfc_state.dart';
import 'package:nfc_payment_poc/nfc/data/repositories/payment_repository.dart';

class NfcBloc extends Bloc<NfcEvent, NfcState> {
  final PaymentRepository _paymentRepository;
  StreamSubscription? _tagSubscription;

  NfcBloc(this._paymentRepository) : super(const NfcInitialState()) {
    on<CreatePaymentIntentEvent>(_onCreatePaymentIntent);
    on<StartNfcEmissionEvent>(_onStartNfcEmission);
    on<WriteToTagEvent>(_onWriteToTag);
    on<StopNfcEmissionEvent>(_onStopNfcEmission);
    on<StartNfcScanEvent>(_onStartNfcScan);
    on<StopNfcScanEvent>(_onStopNfcScan);
    on<PaymentIntentReadEvent>(_onPaymentIntentRead);
    on<ValidatePaymentEvent>(_onValidatePayment);
    on<CancelPaymentEvent>(_onCancelPayment);
    on<ResetNfcEvent>(_onResetNfc);
  }

  Future<void> _onCreatePaymentIntent(
    CreatePaymentIntentEvent event,
    Emitter<NfcState> emit,
  ) async {
    try {
      emit(NfcLoadingState(
        currentPaymentIntent: state.currentPaymentIntent,
        paymentResult: state.paymentResult,
      ));

      final paymentIntent = await _paymentRepository.createPaymentIntent(
        amount: event.amount,
        currency: event.currency,
        merchantId: event.merchantId,
        merchantName: event.merchantName,
      );

      emit(PaymentIntentCreatedState(paymentIntent: paymentIntent));
    } catch (e) {
      emit(NfcErrorState(
        error: 'Erreur lors de la création du paiement: ${e.toString()}',
        currentPaymentIntent: state.currentPaymentIntent,
        paymentResult: state.paymentResult,
      ));
    }
  }

  Future<void> _onStartNfcEmission(
    StartNfcEmissionEvent event,
    Emitter<NfcState> emit,
  ) async {
    try {
      if (state.currentPaymentIntent == null) {
        emit(const NfcErrorState(
          error: 'Aucun paiement à émettre',
        ));
        return;
      }

      emit(NfcLoadingState(
        currentPaymentIntent: state.currentPaymentIntent,
        paymentResult: state.paymentResult,
      ));

      final success = await _paymentRepository.startNfcEmission(
        state.currentPaymentIntent!,
      );

      if (success) {
        emit(NfcEmittingState(paymentIntent: state.currentPaymentIntent!));
      } else {
        emit(NfcErrorState(
          error: 'Impossible de démarrer l\'émission NFC',
          currentPaymentIntent: state.currentPaymentIntent,
          paymentResult: state.paymentResult,
        ));
      }
    } catch (e) {
      emit(NfcErrorState(
        error: 'Erreur lors du démarrage de l\'émission NFC: ${e.toString()}',
        currentPaymentIntent: state.currentPaymentIntent,
        paymentResult: state.paymentResult,
      ));
    }
  }

  Future<void> _onWriteToTag(
    WriteToTagEvent event,
    Emitter<NfcState> emit,
  ) async {
    try {
      if (state.currentPaymentIntent == null) {
        emit(const NfcErrorState(
          error: 'Aucun paiement à écrire',
        ));
        return;
      }

      emit(NfcLoadingState(
        currentPaymentIntent: state.currentPaymentIntent,
        paymentResult: state.paymentResult,
      ));

      final success = await _paymentRepository.writePaymentToTag(
        state.currentPaymentIntent!,
      );

      if (success) {
        emit(NfcEmittingState(paymentIntent: state.currentPaymentIntent!));
      } else {
        emit(NfcErrorState(
          error: 'Impossible d\'écrire sur le tag NFC',
          currentPaymentIntent: state.currentPaymentIntent,
          paymentResult: state.paymentResult,
        ));
      }
    } catch (e) {
      emit(NfcErrorState(
        error: 'Erreur lors de l\'écriture sur le tag: ${e.toString()}',
        currentPaymentIntent: state.currentPaymentIntent,
        paymentResult: state.paymentResult,
      ));
    }
  }

  Future<void> _onStopNfcEmission(
    StopNfcEmissionEvent event,
    Emitter<NfcState> emit,
  ) async {
    try {
      await _paymentRepository.stopNfcEmission();

      if (state.currentPaymentIntent != null) {
        emit(PaymentIntentCreatedState(
          paymentIntent: state.currentPaymentIntent!,
        ));
      } else {
        emit(const NfcInitialState());
      }
    } catch (e) {
      emit(NfcErrorState(
        error: 'Erreur lors de l\'arrêt de l\'émission NFC: ${e.toString()}',
        currentPaymentIntent: state.currentPaymentIntent,
        paymentResult: state.paymentResult,
      ));
    }
  }

  Future<void> _onStartNfcScan(
    StartNfcScanEvent event,
    Emitter<NfcState> emit,
  ) async {
    try {
      emit(const NfcScanningState());

      await _tagSubscription?.cancel();

      _tagSubscription = _paymentRepository.onTagRead.listen(
        (payload) {
          add(PaymentIntentReadEvent(token: payload.token));
        },
        onError: (error) {
          emit(NfcErrorState(
            error: 'Erreur lors du scan NFC: ${error.toString()}',
          ));
        },
      );

      await _paymentRepository.startNfcScan();
    } catch (e) {
      emit(NfcErrorState(
        error: 'Impossible de démarrer le scan NFC: ${e.toString()}',
      ));
    }
  }

  Future<void> _onStopNfcScan(
    StopNfcScanEvent event,
    Emitter<NfcState> emit,
  ) async {
    try {
      await _tagSubscription?.cancel();
      _tagSubscription = null;
      await _paymentRepository.stopNfcScan();
      emit(const NfcInitialState());
    } catch (e) {
      emit(NfcErrorState(
        error: 'Erreur lors de l\'arrêt du scan: ${e.toString()}',
      ));
    }
  }

  Future<void> _onPaymentIntentRead(
    PaymentIntentReadEvent event,
    Emitter<NfcState> emit,
  ) async {
    try {
      emit(NfcLoadingState(
        currentPaymentIntent: state.currentPaymentIntent,
        paymentResult: state.paymentResult,
      ));

      final paymentIntent = await _paymentRepository.getPaymentIntent(event.token);

      if (paymentIntent == null) {
        emit(const NfcErrorState(
          error: 'Paiement non trouvé ou expiré',
        ));
        return;
      }

      await _tagSubscription?.cancel();
      _tagSubscription = null;
      await _paymentRepository.stopNfcScan();

      emit(PaymentIntentReadState(paymentIntent: paymentIntent));
    } catch (e) {
      emit(NfcErrorState(
        error: 'Erreur lors de la lecture du paiement: ${e.toString()}',
      ));
    }
  }

  Future<void> _onValidatePayment(
    ValidatePaymentEvent event,
    Emitter<NfcState> emit,
  ) async {
    try {
      if (state.currentPaymentIntent == null) {
        emit(const NfcErrorState(
          error: 'Aucun paiement à valider',
        ));
        return;
      }

      emit(NfcLoadingState(
        currentPaymentIntent: state.currentPaymentIntent,
        paymentResult: state.paymentResult,
      ));

      final result = await _paymentRepository.validatePayment(
        state.currentPaymentIntent!.token,
      );

      emit(PaymentValidatedState(
        paymentIntent: state.currentPaymentIntent!,
        result: result,
      ));
    } catch (e) {
      emit(NfcErrorState(
        error: 'Erreur lors de la validation: ${e.toString()}',
        currentPaymentIntent: state.currentPaymentIntent,
      ));
    }
  }

  Future<void> _onCancelPayment(
    CancelPaymentEvent event,
    Emitter<NfcState> emit,
  ) async {
    try {
      await _tagSubscription?.cancel();
      _tagSubscription = null;

      if (_paymentRepository.isReading) {
        await _paymentRepository.stopNfcScan();
      }

      if (_paymentRepository.isEmitting) {
        await _paymentRepository.stopNfcEmission();
      }

      emit(const NfcInitialState());
    } catch (e) {
      emit(NfcErrorState(
        error: 'Erreur lors de l\'annulation: ${e.toString()}',
      ));
    }
  }

  Future<void> _onResetNfc(
    ResetNfcEvent event,
    Emitter<NfcState> emit,
  ) async {
    await _tagSubscription?.cancel();
    _tagSubscription = null;
    emit(const NfcInitialState());
  }

  @override
  Future<void> close() async {
    await _tagSubscription?.cancel();
    return super.close();
  }
}
