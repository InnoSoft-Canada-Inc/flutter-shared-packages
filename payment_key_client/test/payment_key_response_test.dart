import 'package:payment_key_client/payment_key_client.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentKeyAttribute', () {
    test('constructs with key and value', () {
      const attr = PaymentKeyAttribute(key: 'CardIssuer', value: 'Visa');
      expect(attr.key, 'CardIssuer');
      expect(attr.value, 'Visa');
    });

    test('fromJson parses PascalCase keys from API', () {
      final attr = PaymentKeyAttribute.fromJson(<String, dynamic>{
        'Key': 'MaskedCardNumber',
        'Value': '4111XXXXXXXX1111',
      });
      expect(attr.key, 'MaskedCardNumber');
      expect(attr.value, '4111XXXXXXXX1111');
    });

    test('fromJson defaults to empty strings when Key/Value are null', () {
      final attr = PaymentKeyAttribute.fromJson(<String, dynamic>{});
      expect(attr.key, '');
      expect(attr.value, '');
    });

    test('fromJson defaults Key to empty when only Value is present', () {
      final attr = PaymentKeyAttribute.fromJson(<String, dynamic>{
        'Value': 'Mastercard',
      });
      expect(attr.key, '');
      expect(attr.value, 'Mastercard');
    });

    test('fromJson defaults Value to empty when only Key is present', () {
      final attr = PaymentKeyAttribute.fromJson(<String, dynamic>{
        'Key': 'ExpirationDate',
      });
      expect(attr.key, 'ExpirationDate');
      expect(attr.value, '');
    });

    test('supports const construction', () {
      const a = PaymentKeyAttribute(key: 'k', value: 'v');
      const b = PaymentKeyAttribute(key: 'k', value: 'v');
      expect(identical(a, b), isTrue);
    });
  });

  group('PaymentKeyResponse', () {
    test('constructs with required fields', () {
      final response = PaymentKeyResponse(
        paymentType: 'Card',
        paymentKeys: ['abc-123'],
      );
      expect(response.paymentType, 'Card');
      expect(response.paymentKeys, ['abc-123']);
      expect(response.attributes, isEmpty);
    });

    test('defaults attributes to empty list when null', () {
      final response = PaymentKeyResponse(
        paymentType: 'Card',
        paymentKeys: ['pk-1'],
        attributes: null,
      );
      expect(response.attributes, isEmpty);
    });

    test('preserves provided attributes', () {
      final response = PaymentKeyResponse(
        paymentType: 'Card',
        paymentKeys: ['pk-1'],
        attributes: [
          const PaymentKeyAttribute(key: 'CardIssuer', value: 'Visa'),
        ],
      );
      expect(response.attributes.length, 1);
      expect(response.attributes.first.key, 'CardIssuer');
    });

    group('paymentKey getter', () {
      test('returns first key when paymentKeys is non-empty', () {
        final response = PaymentKeyResponse(
          paymentType: 'Card',
          paymentKeys: ['first-key', 'second-key'],
        );
        expect(response.paymentKey, 'first-key');
      });

      test('returns empty string when paymentKeys is empty', () {
        // Constructing directly (not via fromJson which rejects empty)
        final response = PaymentKeyResponse(
          paymentType: 'Card',
          paymentKeys: [],
        );
        expect(response.paymentKey, '');
      });
    });

    group('fromJson', () {
      test('parses complete JSON response', () {
        final json = <String, dynamic>{
          'PaymentType': 'Card',
          'PaymentKeys': ['7237d7ff-d22b-4600-84f6-208cf5aef659'],
          'Attributes': [
            {'Key': 'CardIssuer', 'Value': 'Mastercard'},
            {'Key': 'MaskedCardNumber', 'Value': '542418XXXXXX1765'},
            {'Key': 'ExpirationDate', 'Value': '06/34'},
          ],
        };
        final response = PaymentKeyResponse.fromJson(json);
        expect(response.paymentType, 'Card');
        expect(response.paymentKeys, ['7237d7ff-d22b-4600-84f6-208cf5aef659']);
        expect(response.paymentKey, '7237d7ff-d22b-4600-84f6-208cf5aef659');
        expect(response.attributes.length, 3);
        expect(response.attributes[0].key, 'CardIssuer');
        expect(response.attributes[0].value, 'Mastercard');
        expect(response.attributes[1].key, 'MaskedCardNumber');
        expect(response.attributes[2].key, 'ExpirationDate');
      });

      test('parses multiple payment keys', () {
        final json = <String, dynamic>{
          'PaymentType': 'Card',
          'PaymentKeys': ['key-1', 'key-2', 'key-3'],
          'Attributes': [],
        };
        final response = PaymentKeyResponse.fromJson(json);
        expect(response.paymentKeys, ['key-1', 'key-2', 'key-3']);
        expect(response.paymentKey, 'key-1');
      });

      test('throws FormatException when PaymentKeys is empty', () {
        final json = <String, dynamic>{
          'PaymentType': 'Card',
          'PaymentKeys': [],
          'Attributes': [],
        };
        expect(() => PaymentKeyResponse.fromJson(json), throwsFormatException);
      });

      test('throws FormatException when PaymentKeys is null', () {
        final json = <String, dynamic>{'PaymentType': 'Card', 'Attributes': []};
        expect(() => PaymentKeyResponse.fromJson(json), throwsFormatException);
      });

      test('defaults PaymentType to empty string when missing', () {
        final json = <String, dynamic>{
          'PaymentKeys': ['pk-1'],
        };
        final response = PaymentKeyResponse.fromJson(json);
        expect(response.paymentType, '');
      });

      test('handles missing Attributes gracefully', () {
        final json = <String, dynamic>{
          'PaymentType': 'Wallet',
          'PaymentKeys': ['pk-wallet'],
        };
        final response = PaymentKeyResponse.fromJson(json);
        expect(response.attributes, isEmpty);
      });

      test('skips non-Map items in Attributes array', () {
        final json = <String, dynamic>{
          'PaymentType': 'Card',
          'PaymentKeys': ['pk-1'],
          'Attributes': [
            {'Key': 'CardIssuer', 'Value': 'Visa'},
            'not a map',
            42,
            {'Key': 'Expiry', 'Value': '12/30'},
          ],
        };
        final response = PaymentKeyResponse.fromJson(json);
        expect(response.attributes.length, 2);
        expect(response.attributes[0].key, 'CardIssuer');
        expect(response.attributes[1].key, 'Expiry');
      });

      test('handles empty Attributes array', () {
        final json = <String, dynamic>{
          'PaymentType': 'Card',
          'PaymentKeys': ['pk-1'],
          'Attributes': [],
        };
        final response = PaymentKeyResponse.fromJson(json);
        expect(response.attributes, isEmpty);
      });

      test('converts non-string PaymentKeys items to strings', () {
        final json = <String, dynamic>{
          'PaymentType': 'Card',
          'PaymentKeys': [123, true, 'abc'],
          'Attributes': [],
        };
        final response = PaymentKeyResponse.fromJson(json);
        expect(response.paymentKeys, ['123', 'true', 'abc']);
      });
    });
  });
}
