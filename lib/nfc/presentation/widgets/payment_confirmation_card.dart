import 'package:flutter/material.dart';
import 'package:nfc_payment_poc/nfc/data/models/payment_intent.dart';
import 'package:nfc_payment_poc/nfc/data/models/payment_result.dart';

class PaymentConfirmationCard extends StatelessWidget {
  final PaymentIntent paymentIntent;
  final PaymentResult? paymentResult;

  const PaymentConfirmationCard({
    super.key,
    required this.paymentIntent,
    this.paymentResult,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = paymentResult?.success ?? false;
    final color = paymentResult != null
        ? (isSuccess ? Colors.green.shade700 : Colors.red.shade700)
        : Colors.blue.shade700;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (paymentResult != null)
              Row(
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle : Icons.cancel,
                    color: color,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      paymentResult!.message ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            if (paymentResult != null) const Divider(height: 24),
            _buildInfoRow('Montant', paymentIntent.formattedAmount),
            const SizedBox(height: 12),
            _buildInfoRow('Marchand', paymentIntent.merchantName),
            const SizedBox(height: 12),
            _buildInfoRow('Token', paymentIntent.token),
            if (paymentResult?.transactionId != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Transaction', paymentResult!.transactionId!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
