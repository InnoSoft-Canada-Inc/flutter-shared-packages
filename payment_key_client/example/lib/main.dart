import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

/// RSA public key (base64 DER SPKI) for encrypting card data.
/// In production, use the [publicKey] from your Payments API init response.
const String kRsaPublicKeyBase64 =
    'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxFy4/3Qnt50uQzxOWwaY'
    'Hbeue2O+Zr+Z4M7433IhnH6hHPgCGSlRc9ll3oqSI4GD35fTA7LUFUMkLICMb'
    'PYqtmagLkFwawIZGp3p/ac0okkxOTl1KGvd9WeQh+w/rtS7Lpd/m2K1dPmPsTf'
    'uHmfchi9d8/hhiJCaspQOLCQe/yMlbpFJ6m+po+/aARNih24TB7Ru+NDpb9ymZ'
    '9L9rtG/Jq4+e9vNDkDaOsEgntM1x0RMQuf9axn3U61DgwEhogELhOWRBqTDpE'
    'KBVjBi28H26u0pw6WonyvQC7T6SCJqrNZaq1qFD93x7ll8kxvWcZWG7Wz15w+'
    'i5FLM3RydGk3NHQIDAQAB';

void main() {
  runApp(const PaymentKeySampleApp());
}

class PaymentKeySampleApp extends StatelessWidget {
  const PaymentKeySampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Payment Key Sample',
      theme: AppTheme.light,
      localizationsDelegates: const [
        ...GlobalMaterialLocalizations.delegates,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
      ],
      home: const HomeScreen(
        rsaPublicKeyBase64: kRsaPublicKeyBase64,
      ),
    );
  }
}
