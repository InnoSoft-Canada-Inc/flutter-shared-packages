import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pay/pay.dart';

import '../payment_configurations.dart';
import '../theme/app_tokens.dart';
import '../widgets/result_message_card.dart';
import '../widgets/section_label.dart';

/// Google Pay payment screen using the pay package.
/// Android only; shows payment results via EventChannel.
class GooglePayScreen extends StatefulWidget {
  const GooglePayScreen({super.key});

  @override
  State<GooglePayScreen> createState() => _GooglePayScreenState();
}

class _GooglePayScreenState extends State<GooglePayScreen> {
  static const EventChannel _paymentResultChannel =
      EventChannel('plugins.flutter.io/pay/payment_result');

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
  late final Future<bool> _canPayFuture;
  StreamSubscription<Map<String, dynamic>>? _paymentResultSubscription;
  String? _resultMessage;
  bool _resultSuccess = false;

  @override
  void initState() {
    super.initState();
    _payClient = Pay({
      PayProvider.google_pay: defaultGooglePayConfig,
    });
    _canPayFuture = _payClient.userCanPay(PayProvider.google_pay);
    if (Platform.isAndroid) {
      _paymentResultSubscription = _paymentResultChannel
          .receiveBroadcastStream()
          .cast<String>()
          .map((String result) =>
              jsonDecode(result) as Map<String, dynamic>)
          .listen(_onPaymentResult, onError: _onError);
    }
  }

  @override
  void dispose() {
    _paymentResultSubscription?.cancel();
    _paymentResultSubscription = null;
    super.dispose();
  }

  Future<void> _onGooglePayPressed() async {
    try {
      await _payClient.showPaymentSelector(
        PayProvider.google_pay,
        _paymentItems,
      );
      // On Android, result comes via EventChannel
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

  void _onError(Object error) {
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
        title: const Text('Google Pay'),
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
            const SectionLabel(text: 'Pay with Google Pay'),
            const SizedBox(height: AppTokens.spaceSm),
            Text(
              'Complete your purchase using Google Pay. '
              'The payment token will be sent to your server for processing.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTokens.spaceXl),
            if (!Platform.isAndroid)
              _buildUnavailableMessage(context, notSetUp: false)
            else
              FutureBuilder<bool>(
                future: _canPayFuture,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<bool> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTokens.spaceXl),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.data == true) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppTokens.spaceMd),
                      child: RawGooglePayButton(
                        paymentConfiguration: defaultGooglePayConfig,
                        type: GooglePayButtonType.buy,
                        theme: GooglePayButtonTheme.dark,
                        onPressed: _onGooglePayPressed,
                      ),
                    );
                  }
                  return _buildUnavailableMessage(
                    context,
                    notSetUp: true,
                  );
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

  Widget _buildUnavailableMessage(
    BuildContext context, {
    required bool notSetUp,
  }) {
    String message;
    if (notSetUp) {
      message = 'Google Pay is not set up on this device. '
          'Please add a payment method in the Google Pay app.';
    } else {
      message = 'Google Pay is available on Android devices. '
          'Please run this app on an Android device to use Google Pay.';
    }
    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
