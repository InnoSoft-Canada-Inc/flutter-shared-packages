import 'package:flutter/material.dart';
import 'package:payment_key_client/payment_key_client.dart';

import '../theme/app_tokens.dart';
import '../widgets/result_message_card.dart';
import '../widgets/section_label.dart';

/// Session & submit screen: collect access token and provider URL, then get payment key.
///
/// When [cardData] is provided (from the Expiry/CVV step), card fields are read-only.
/// When [cardData] is null, the full single-screen form (all card + session fields) is shown.
class PaymentKeySampleScreen extends StatefulWidget {
  const PaymentKeySampleScreen({
    super.key,
    this.rsaPublicKeyBase64,
    this.cardData,
  });

  /// RSA public key (base64 DER SPKI) for encrypting card data.
  final String? rsaPublicKeyBase64;

  /// When set, card data comes from the multi-step flow; session fields are still editable.
  final CardData? cardData;

  @override
  State<PaymentKeySampleScreen> createState() => _PaymentKeySampleScreenState();
}

class _PaymentKeySampleScreenState extends State<PaymentKeySampleScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Single-screen flow only.
  final TextEditingController _panController = TextEditingController(
    text: '5424180279791765',
  );
  final TextEditingController _expiryMonthController = TextEditingController(
    text: '06',
  );
  final TextEditingController _expiryYearController = TextEditingController(
    text: '34',
  );
  final TextEditingController _cvvController = TextEditingController(
    text: '123',
  );

  // Always shown.
  final TextEditingController _accessTokenController = TextEditingController();
  final TextEditingController _providerBaseUrlController =
      TextEditingController(text: 'https://hpc.uat.freedompay.com');

  bool _loading = false;
  String? _resultMessage;
  bool _resultSuccess = false;

  bool get _isMultiScreenFlow => widget.cardData != null;

  @override
  void dispose() {
    _panController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    _accessTokenController.dispose();
    _providerBaseUrlController.dispose();
    super.dispose();
  }

  Future<void> _getPaymentKey(String publicKey) async {
    if (!_formKey.currentState!.validate()) return;

    CardData cardData;
    if (_isMultiScreenFlow) {
      cardData = widget.cardData!;
    } else {
      cardData = CardData(
        pan: sanitizePan(_panController.text),
        expiryMonth: _expiryMonthController.text.trim(),
        expiryYear: _expiryYearController.text.trim(),
        cvv: _cvvController.text.trim(),
      );
    }

    setState(() {
      _loading = true;
      _resultMessage = null;
    });

    try {
      PaymentKeyClient client = PaymentKeyClient();
      PaymentKeyResponse response = await client.encryptAndCreatePaymentKey(
        cardData: cardData,
        publicKey: publicKey,
        accessToken: _accessTokenController.text.trim(),
        providerBaseUrl: _providerBaseUrlController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _loading = false;
          _resultSuccess = true;
          _resultMessage = 'Payment key: ${response.paymentKey}';
        });
      }
    } on ArgumentError catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _resultSuccess = false;
          _resultMessage = 'Validation error: ${e.message}';
        });
      }
    } on PaymentKeyException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _resultSuccess = false;
          _resultMessage = 'Error ${e.statusCode}: ${e.message ?? e.toString()}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _resultSuccess = false;
          _resultMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? publicKey = widget.rsaPublicKeyBase64;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isMultiScreenFlow ? 'Session & payment key' : 'Payment Key Sample',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: _isMultiScreenFlow
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spaceLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isMultiScreenFlow && widget.cardData != null) ...[
                const SectionLabel(text: 'Card (from previous steps)'),
                const SizedBox(height: AppTokens.spaceSm),
                _ReadOnlyCardSummary(cardData: widget.cardData!),
                const SizedBox(height: AppTokens.spaceXl),
              ] else ...[
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
                const SizedBox(height: AppTokens.spaceMd),
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
              ],
              const SectionLabel(text: 'Session (from Payments API init)'),
              const SizedBox(height: AppTokens.spaceSm),
              TextFormField(
                controller: _accessTokenController,
                decoration: const InputDecoration(
                  labelText: 'Access token',
                  hintText:
                      'Bearer token from POST /cards/init or /payments/init',
                ),
                maxLines: 2,
                validator: (String? v) => v == null || v.trim().isEmpty
                    ? 'Enter access token from init'
                    : null,
              ),
              const SizedBox(height: AppTokens.spaceMd),
              TextFormField(
                controller: _providerBaseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Provider base URL',
                ),
                validator: (String? v) => v == null || v.trim().isEmpty
                    ? 'Enter provider base URL'
                    : null,
              ),
              const SizedBox(height: AppTokens.spaceXl),
              if (_isMultiScreenFlow)
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: AppTokens.spaceMd),
                    Expanded(child: _submitButton(publicKey)),
                  ],
                )
              else
                _submitButton(publicKey),
              if (_resultMessage != null) ...[
                const SizedBox(height: AppTokens.spaceXl),
                ResultMessageCard(
                  message: _resultMessage!,
                  isSuccess: _resultSuccess,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _submitButton(String? publicKey) {
    return FilledButton.icon(
      onPressed: _loading || publicKey == null || publicKey.isEmpty
          ? null
          : () => _getPaymentKey(publicKey),
      icon: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.key),
      label: Text(_loading ? 'Requesting…' : 'Get payment key'),
    );
  }
}

/// Shows a read-only summary of card data collected in previous steps.
class _ReadOnlyCardSummary extends StatelessWidget {
  const _ReadOnlyCardSummary({required this.cardData});

  final CardData cardData;

  @override
  Widget build(BuildContext context) {
    String maskedPan = maskPan(cardData.pan);
    String expiry = '${cardData.expiryMonth}/${cardData.expiryYear}';
    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PAN: $maskedPan', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppTokens.spaceXs),
          Text(
            'Expiry: $expiry • CVV: ***',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
