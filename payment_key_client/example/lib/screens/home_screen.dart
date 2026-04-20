import 'package:flutter/material.dart';
import 'package:payment_key_client/payment_key_client.dart';

import '../theme/app_tokens.dart';
import 'apple_pay_screen.dart';
import 'card_number_screen.dart';
import 'google_pay_screen.dart';

/// Landing screen offering choice between card entry and Apple Pay / Google Pay flows.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.rsaPublicKeyBase64,
  });

  final String rsaPublicKeyBase64;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Key Sample'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppTokens.spaceXl),
            Text(
              'Choose a payment method',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTokens.spaceMd),
            Text(
              'Enter card details manually or pay with Apple Pay or Google Pay.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTokens.spaceXl),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => CardNumberScreen(
                      cardData: const CardData(
                        pan: '',
                        expiryMonth: '',
                        expiryYear: '',
                        cvv: '',
                      ),
                      rsaPublicKeyBase64: rsaPublicKeyBase64,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.credit_card),
              label: const Text('Enter card details'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.spaceLg,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spaceMd),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const ApplePayScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.apple),
              label: const Text('Apple Pay'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.spaceLg,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spaceMd),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const GooglePayScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.payment),
              label: const Text('Google Pay'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.spaceLg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
