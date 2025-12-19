import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nfc_payment_poc/nfc/business_logic/nfc_bloc.dart';
import 'package:nfc_payment_poc/nfc/business_logic/nfc_event.dart';
import 'package:nfc_payment_poc/nfc/business_logic/nfc_state.dart';
import 'package:nfc_payment_poc/nfc/data/repositories/payment_repository.dart';
import 'package:nfc_payment_poc/nfc/presentation/widgets/nfc_status_indicator.dart';
import 'package:nfc_payment_poc/nfc/presentation/widgets/payment_confirmation_card.dart';

class ClientScreen extends StatelessWidget {
  const ClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NfcBloc(PaymentRepository()),
      child: const _ClientScreenContent(),
    );
  }
}

class _ClientScreenContent extends StatelessWidget {
  const _ClientScreenContent();

  void _startScan(BuildContext context) {
    context.read<NfcBloc>().add(StartNfcScanEvent());
    _showNfcDialog(context, 'Approchez du téléphone marchand...');
  }

  void _validatePayment(BuildContext context, String paymentIntentId) {
    context.read<NfcBloc>().add(ValidatePaymentEvent(
          paymentIntentId: paymentIntentId,
          authorized: true,
        ));
  }

  void _showNfcDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<NfcBloc>().add(ResetNfcEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<NfcBloc, NfcState>(
        listener: (context, state) {
          if (state is NfcScanningState) {
          } else if (state is PaymentIntentReadState) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          } else if (state is NfcLoadingState) {
          } else if (state is PaymentValidatedState) {
          } else if (state is NfcErrorState) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Erreur'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state is NfcInitialState || state is NfcErrorState) ...[
                  const Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.nfc,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucun paiement scanné',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _startScan(context),
                    icon: const Icon(Icons.nfc),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'SCANNER UN PAIEMENT',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                if (state is NfcScanningState) ...[
                  const NfcStatusIndicator(
                    status: NfcStatus.scanning,
                    message: 'Scan en cours...\nApprochez du tag NFC',
                  ),
                ],
                if (state is PaymentIntentReadState) ...[
                  PaymentConfirmationCard(
                    paymentIntent: state.currentPaymentIntent!,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _validatePayment(
                      context,
                      state.currentPaymentIntent!.id,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'CONFIRMER LE PAIEMENT',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<NfcBloc>().add(CancelPaymentEvent());
                    },
                    icon: const Icon(Icons.close),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'ANNULER',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                if (state is NfcLoadingState &&
                    state.currentPaymentIntent != null) ...[
                  PaymentConfirmationCard(
                    paymentIntent: state.currentPaymentIntent!,
                  ),
                  const SizedBox(height: 24),
                  const NfcStatusIndicator(
                    status: NfcStatus.idle,
                    message: 'Validation en cours...',
                  ),
                ],
                if (state is PaymentValidatedState) ...[
                  PaymentConfirmationCard(
                    paymentIntent: state.currentPaymentIntent!,
                    paymentResult: state.paymentResult,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
