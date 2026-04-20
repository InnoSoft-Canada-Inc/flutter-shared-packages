import 'package:flutter/material.dart';
import 'package:payment_key_client/payment_key_client.dart';

import '../theme/app_tokens.dart';
import '../widgets/section_label.dart';
import 'payment_key_sample_screen.dart';

/// Second step: collect expiry (MM/YY) and CVV.
class ExpiryCvvScreen extends StatelessWidget {
  const ExpiryCvvScreen({
    super.key,
    required this.cardData,
    required this.rsaPublicKeyBase64,
  });

  final CardData cardData;
  final String rsaPublicKeyBase64;

  @override
  Widget build(BuildContext context) {
    return _ExpiryCvvScreenBody(
      cardData: cardData,
      rsaPublicKeyBase64: rsaPublicKeyBase64,
    );
  }
}

class _ExpiryCvvScreenBody extends StatefulWidget {
  const _ExpiryCvvScreenBody({
    required this.cardData,
    required this.rsaPublicKeyBase64,
  });

  final CardData cardData;
  final String rsaPublicKeyBase64;

  @override
  State<_ExpiryCvvScreenBody> createState() => _ExpiryCvvScreenBodyState();
}

class _ExpiryCvvScreenBodyState extends State<_ExpiryCvvScreenBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _expiryMonthController;
  late final TextEditingController _expiryYearController;
  late final TextEditingController _cvvController;

  @override
  void initState() {
    super.initState();
    _expiryMonthController = TextEditingController(
      text: widget.cardData.expiryMonth.isNotEmpty
          ? widget.cardData.expiryMonth
          : '06',
    );
    _expiryYearController = TextEditingController(
      text: widget.cardData.expiryYear.isNotEmpty
          ? widget.cardData.expiryYear
          : '34',
    );
    _cvvController = TextEditingController(
      text: widget.cardData.cvv.isNotEmpty ? widget.cardData.cvv : '123',
    );
  }

  @override
  void dispose() {
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _onBack() {
    Navigator.of(context).pop();
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => PaymentKeySampleScreen(
          cardData: widget.cardData.copyWith(
            expiryMonth: _expiryMonthController.text.trim(),
            expiryYear: _expiryYearController.text.trim(),
            cvv: _cvvController.text.trim(),
          ),
          rsaPublicKeyBase64: widget.rsaPublicKeyBase64,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expiry & CVV'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spaceLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionLabel(
                text: 'Card details (encrypted on device before sending)',
              ),
              const SizedBox(height: AppTokens.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryMonthController,
                      decoration: const InputDecoration(labelText: 'MM'),
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      validator: (String? v) =>
                          validateExpiryMonth(v?.trim() ?? ''),
                    ),
                  ),
                  const SizedBox(width: AppTokens.spaceMd),
                  Expanded(
                    child: TextFormField(
                      controller: _expiryYearController,
                      decoration: const InputDecoration(labelText: 'YY'),
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      validator: (String? v) =>
                          validateExpiryYear(v?.trim() ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spaceMd),
              TextFormField(
                controller: _cvvController,
                decoration: const InputDecoration(labelText: 'CVV'),
                keyboardType: TextInputType.number,
                obscureText: true,
                validator: (String? v) => validateCvv(v?.trim() ?? ''),
              ),
              const SizedBox(height: AppTokens.spaceXl),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _onBack,
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: AppTokens.spaceMd),
                  Expanded(
                    child: FilledButton(
                      onPressed: _onNext,
                      child: const Text('Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
