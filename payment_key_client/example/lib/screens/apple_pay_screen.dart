import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pay/pay.dart';

import '../apple_pay_availability.dart';
import '../payment_configurations.dart';
import '../theme/app_tokens.dart';
import '../widgets/result_message_card.dart';
import '../widgets/section_label.dart';

/// Apple Pay payment screen using the pay package.
/// Uses [RawApplePayButton] to always show the button on iOS (ApplePayButton
/// hides when userCanPay is false). Per Apple HIG: "Buy" when user has cards,
/// "Set up" when user has no compatible cards.
class ApplePayScreen extends StatefulWidget {
  const ApplePayScreen({super.key});

  @override
  State<ApplePayScreen> createState() => _ApplePayScreenState();
}

class _ApplePayScreenState extends State<ApplePayScreen> {
  /// Payment summary items per FreedomPay instructions:
  /// subtotal, discount, grand total (merchant display name).
  static const List<PaymentItem> _paymentItems = [
    PaymentItem(
      label: 'Subtotal',
      amount: '72.99',
      type: PaymentItemType.item,
      status: PaymentItemStatus.final_price,
    ),
    PaymentItem(
      label: 'Discount',
      amount: '-6.50',
      type: PaymentItemType.item,
      status: PaymentItemStatus.final_price,
    ),
    PaymentItem(
      label: 'FreedomPay Test Store',
      amount: '66.49',
      type: PaymentItemType.total,
      status: PaymentItemStatus.final_price,
    ),
  ];

  late final Pay _payClient;
  late final Future<ApplePayButtonState> _applePayButtonStateFuture;
  String? _resultMessage;
  bool _resultSuccess = false;

  @override
  void initState() {
    super.initState();
    _payClient = Pay({PayProvider.apple_pay: defaultApplePayConfig});
    _applePayButtonStateFuture = _payClient
        .userCanPay(PayProvider.apple_pay)
        .then(
          (bool userHasCompatibleCards) => getApplePayButtonState(
            userHasCompatibleCards: userHasCompatibleCards,
          ),
        );
  }

  Future<void> _onApplePayPressed() async {
    try {
      final Map<String, dynamic> result = await _payClient.showPaymentSelector(
        PayProvider.apple_pay,
        _paymentItems,
      );
      // In Flutter after Apple Pay authorization

      // The pay package returns result['token'] as a JSON-encoded String on iOS.
      final dynamic rawToken = result['token'];
      final Map<String, dynamic> paymentToken = rawToken is String
          ? jsonDecode(rawToken) as Map<String, dynamic>
          : rawToken as Map<String, dynamic>;

      // Extract the encrypted payment data from the Apple Pay token.
      // See: https://developer.apple.com/documentation/passkit/apple_pay/payment_token
      final String? dataBase64 = paymentToken['data'] as String?;
      if (dataBase64 == null) {
        throw Exception("Apple Pay paymentToken['data'] is null");
      }

      if (mounted) _onPaymentResult(result);
    } catch (error) {
      if (mounted) _onError(error);
    }
  }

  void _onPaymentResult(Map<String, dynamic> paymentResult) {
    if (!mounted) return;
    setState(() {
      _resultSuccess = true;
      _resultMessage =
          'Payment successful. Token data: ${jsonEncode(paymentResult)}';
    });
  }

  void _onError(Object? error) {
    if (!mounted) return;
    setState(() {
      _resultSuccess = false;
      _resultMessage = 'Payment error: $error';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apple Pay'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionLabel(text: 'Pay with Apple Pay'),
            const SizedBox(height: AppTokens.spaceSm),
            Text(
              'Complete your purchase using Apple Pay. '
              'The payment token will be sent to your server for processing.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTokens.spaceXl),
            if (!Platform.isIOS)
              _buildUnavailableMessage(context)
            else
              FutureBuilder<ApplePayButtonState>(
                future: _applePayButtonStateFuture,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<ApplePayButtonState> snapshot,
                    ) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppTokens.spaceXl),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      // On error (e.g. config), default to setUp so button shows.
                      ApplePayButtonState state =
                          snapshot.data ?? ApplePayButtonState.setUp;
                      if (state == ApplePayButtonState.buy ||
                          state == ApplePayButtonState.setUp) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            top: AppTokens.spaceMd,
                          ),
                          child: RawApplePayButton(
                            style: ApplePayButtonStyle.black,
                            type: state == ApplePayButtonState.buy
                                ? ApplePayButtonType.buy
                                : ApplePayButtonType.setUp,
                            onPressed: _onApplePayPressed,
                          ),
                        );
                      }
                      return _buildUnavailableMessage(context);
                    },
              ),
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
    );
  }

  Widget _buildUnavailableMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Text(
        'Apple Pay is available on iOS devices with a '
        'configured wallet. Please run this app on an iOS device '
        'to use Apple Pay.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
