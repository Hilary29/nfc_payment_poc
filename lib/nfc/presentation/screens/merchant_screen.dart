import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nfc_payment_poc/nfc/business_logic/nfc_bloc.dart';
import 'package:nfc_payment_poc/nfc/business_logic/nfc_event.dart';
import 'package:nfc_payment_poc/nfc/business_logic/nfc_state.dart';
import 'package:nfc_payment_poc/nfc/data/repositories/payment_repository.dart';
import 'package:nfc_payment_poc/nfc/presentation/widgets/amount_input_field.dart';
import 'package:nfc_payment_poc/nfc/presentation/widgets/nfc_status_indicator.dart';
import 'package:nfc_payment_poc/nfc/presentation/widgets/payment_confirmation_card.dart';

class MerchantScreen extends StatelessWidget {
  const MerchantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NfcBloc(PaymentRepository()),
      child: const _MerchantScreenContent(),
    );
  }
}

class _MerchantScreenContent extends StatefulWidget {
  const _MerchantScreenContent();

  @override
  State<_MerchantScreenContent> createState() => _MerchantScreenContentState();
}

class _MerchantScreenContentState extends State<_MerchantScreenContent> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _createPayment(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      context.read<NfcBloc>().add(CreatePaymentIntentEvent(
            amount: amount,
            merchantId: 'merchant_001',
            merchantName: 'Ma Boutique',
          ));
    }
  }

  void _writeToTag(BuildContext context, String paymentIntentId) {
    context.read<NfcBloc>().add(WriteToTagEvent(
          paymentIntentId: paymentIntentId,
        ));
    _showNfcDialog(context, 'Approchez le tag NFC...');
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
        title: const Text('Mode Marchand'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<NfcBloc>().add(ResetNfcEvent());
              _amountController.clear();
            },
          ),
        ],
      ),
      body: BlocConsumer<NfcBloc, NfcState>(
        listener: (context, state) {
          if (state is NfcLoadingState) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          } else if (state is NfcEmittingState) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          } else if (state is PaymentValidatedState) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
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
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AmountInputField(
                          controller: _amountController,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _createPayment(context),
                          icon: const Icon(Icons.add),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              'Créer le paiement',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (state is NfcLoadingState) ...[
                  const NfcStatusIndicator(
                    status: NfcStatus.idle,
                    message: 'Création du paiement...',
                  ),
                ],
                if (state is PaymentIntentCreatedState) ...[
                  PaymentConfirmationCard(
                    paymentIntent: state.currentPaymentIntent!,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _writeToTag(
                      context,
                      state.currentPaymentIntent!.id,
                    ),
                    icon: const Icon(Icons.nfc),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'Écrire sur tag NFC',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                if (state is NfcEmittingState) ...[
                  PaymentConfirmationCard(
                    paymentIntent: state.currentPaymentIntent!,
                  ),
                  const SizedBox(height: 24),
                  const NfcStatusIndicator(
                    status: NfcStatus.emitting,
                    message: 'Tag NFC écrit avec succès!\nEn attente du client...',
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
