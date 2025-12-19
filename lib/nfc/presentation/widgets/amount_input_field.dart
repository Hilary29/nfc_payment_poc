import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountInputField extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final String? Function(String?)? validator;
  final bool enabled;

  const AmountInputField({
    super.key,
    required this.controller,
    this.currency = 'XAF',
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: 'Montant',
        hintText: 'Entrez le montant',
        prefixIcon: const Icon(Icons.attach_money),
        suffixText: currency,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
      ),
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un montant';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Montant invalide';
            }
            return null;
          },
    );
  }
}
