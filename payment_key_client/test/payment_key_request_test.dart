import 'package:payment_key_client/payment_key_client.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentKeyRequest', () {
    test('constructs with all required fields', () {
      final request = PaymentKeyRequest(
        accessToken: 'token123',
        providerBaseUrl: 'https://hpc.uat.freedompay.com',
        encryptedCardData: 'encPayload==',
        paymentType: 1,
      );
      expect(request.accessToken, 'token123');
      expect(request.providerBaseUrl, 'https://hpc.uat.freedompay.com');
      expect(request.encryptedCardData, 'encPayload==');
      expect(request.paymentType, 1);
      expect(request.attributes, isNull);
      expect(request.keyPath, PaymentKeyRequest.defaultKeyPath);
    });

    test('uses default keyPath when not provided', () {
      final request = PaymentKeyRequest(
        accessToken: 't',
        providerBaseUrl: 'https://example.com',
        encryptedCardData: 'enc',
        paymentType: 1,
      );
      expect(request.keyPath, '/api/v2.1/payments/key');
    });

    test('defaultKeyPath constant has expected value', () {
      expect(PaymentKeyRequest.defaultKeyPath, '/api/v2.1/payments/key');
    });

    test('accepts custom keyPath', () {
      final request = PaymentKeyRequest(
        accessToken: 't',
        providerBaseUrl: 'https://example.com',
        encryptedCardData: 'enc',
        paymentType: 1,
        keyPath: '/api/v3/keys',
      );
      expect(request.keyPath, '/api/v3/keys');
    });

    test('accepts attributes map', () {
      final request = PaymentKeyRequest(
        accessToken: 't',
        providerBaseUrl: 'https://example.com',
        encryptedCardData: 'enc',
        paymentType: 1,
        attributes: <String, String>{
          'CardIssuer': 'Visa',
          'MaskedCardNumber': '4111XXXXXXXX1111',
        },
      );
      expect(request.attributes, isNotNull);
      expect(request.attributes!['CardIssuer'], 'Visa');
      expect(request.attributes!['MaskedCardNumber'], '4111XXXXXXXX1111');
    });

    test('accepts empty attributes map', () {
      final request = PaymentKeyRequest(
        accessToken: 't',
        providerBaseUrl: 'https://example.com',
        encryptedCardData: 'enc',
        paymentType: 1,
        attributes: <String, String>{},
      );
      expect(request.attributes, isNotNull);
      expect(request.attributes, isEmpty);
    });

    test('accepts different paymentType values', () {
      for (final type in [1, 2, 5, 6]) {
        final request = PaymentKeyRequest(
          accessToken: 't',
          providerBaseUrl: 'https://example.com',
          encryptedCardData: 'enc',
          paymentType: type,
        );
        expect(request.paymentType, type);
      }
    });

    test('preserves base URL without trailing slash', () {
      final request = PaymentKeyRequest(
        accessToken: 't',
        providerBaseUrl: 'https://hpc.uat.freedompay.com',
        encryptedCardData: 'enc',
        paymentType: 1,
      );
      expect(request.providerBaseUrl, 'https://hpc.uat.freedompay.com');
    });

    test('preserves base URL with trailing slash', () {
      final request = PaymentKeyRequest(
        accessToken: 't',
        providerBaseUrl: 'https://hpc.uat.freedompay.com/',
        encryptedCardData: 'enc',
        paymentType: 1,
      );
      expect(request.providerBaseUrl, 'https://hpc.uat.freedompay.com/');
    });
  });
}
