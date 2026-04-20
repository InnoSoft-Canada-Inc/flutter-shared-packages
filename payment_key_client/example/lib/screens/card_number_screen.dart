import 'package:flutter/material.dart';
import 'package:payment_key_client/payment_key_client.dart';

import '../theme/app_tokens.dart';
import '../widgets/section_label.dart';
import 'expiry_cvv_screen.dart';

/// First step: collect card number (PAN) only.
class CardNumberScreen extends StatelessWidget {
  const CardNumberScreen({
    super.key,
    required this.cardData,
    required this.rsaPublicKeyBase64,
  });

  final CardData cardData;
  final String rsaPublicKeyBase64;

  @override
  Widget build(BuildContext context) {
    return _CardNumberScreenBody(
      cardData: cardData,
      rsaPublicKeyBase64: rsaPublicKeyBase64,
    );
  }
}

class _CardNumberScreenBody extends StatefulWidget {
  const _CardNumberScreenBody({
    required this.cardData,
    required this.rsaPublicKeyBase64,
  });

  final CardData cardData;
  final String rsaPublicKeyBase64;

  @override
  State<_CardNumberScreenBody> createState() => _CardNumberScreenBodyState();
}

class _CardNumberScreenBodyState extends State<_CardNumberScreenBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _panController;

  @override
  void initState() {
    super.initState();
    _panController = TextEditingController(
      text: widget.cardData.pan.isNotEmpty
          ? widget.cardData.pan
          : '5424180279791765',
    );
  }

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ExpiryCvvScreen(
          cardData: widget.cardData.copyWith(
            pan: sanitizePan(_panController.text),
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
        title: const Text('Card number'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
              TextFormField(
                controller: _panController,
                decoration: const InputDecoration(
                  labelText: 'Card number (PAN)',
                  hintText: 'Digits only, no spaces',
                ),
                keyboardType: TextInputType.number,
                validator: (String? v) =>
                    validatePan(sanitizePan(v ?? '')),
              ),
              const SizedBox(height: AppTokens.spaceXl),
              FilledButton(
                onPressed: _onNext,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
