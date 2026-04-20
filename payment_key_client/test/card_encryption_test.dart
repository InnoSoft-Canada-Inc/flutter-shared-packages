import 'dart:convert';

import 'package:payment_key_client/payment_key_client.dart';
import 'package:test/test.dart';

/// Test key (base64 DER SPKI) from card_encrypt.js — used only for unit tests.
const String _testPublicKeyBase64 =
    'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxFy4/3Qnt50uQzxOWwaYHbeue2O+Zr+Z4M7433IhnH6hHPgCGSlRc9ll3oqSI4GD35fTA7LUFUMkLICMbPYqtmagLkFwawIZGp3p/ac0okkxOTl1KGvd9WeQh+w/rtS7Lpd/m2K1dPmPsTfuHmfchi9d8/hhiJCaspQOLCQe/yMlbpFJ6m+po+/aARNih24TB7Ru+NDpb9ymZ9L9rtG/Jq4+e9vNDkDaOsEgntM1x0RMQuf9axn3U61DgwEhogELhOWRBqTDpEKBVjBi28H26u0pw6WonyvQC7T6SCJqrNZaq1qFD93x7ll8kxvWcZWG7Wz15w+i5FLM3RydGk3NHQIDAQAB';

void main() {
  group('buildCardString', () {
    test('produces M<PAN>=<YY><MM>:<CVV> format matching card_encrypt.js', () {
      String s = buildCardString(
        pan: '5424180279791765',
        expiryYear: '34',
        expiryMonth: '06',
        cvv: '123',
      );
      expect(s, 'M5424180279791765=3406:123');
    });

    test('handles Amex with 4-digit CVV', () {
      String s = buildCardString(
        pan: '371449635398431',
        expiryYear: '34',
        expiryMonth: '05',
        cvv: '1234',
      );
      expect(s, 'M371449635398431=3405:1234');
    });
  });

  group('encryptCardData', () {
    test(
      'returns non-empty base64 when given card string and base64 DER key',
      () {
        String cardString = buildCardString(
          pan: '5424180279791765',
          expiryYear: '34',
          expiryMonth: '06',
          cvv: '123',
        );
        String encrypted = encryptCardData(
          cardString: cardString,
          publicKeyPemOrBase64Der: _testPublicKeyBase64,
        );
        expect(encrypted, isNotEmpty);
        expect(() => base64Decode(encrypted), returnsNormally);
        expect(base64Decode(encrypted).length, greaterThan(0));
      },
    );

    test('accepts PEM-formatted public key', () {
      String pem =
          '-----BEGIN PUBLIC KEY-----\n'
          'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxFy4/3Qnt50uQzxOWwaY\n'
          'Hbeue2O+Zr+Z4M7433IhnH6hHPgCGSlRc9ll3oqSI4GD35fTA7LUFUMkLICMb\n'
          'PYqtmagLkFwawIZGp3p/ac0okkxOTl1KGvd9WeQh+w/rtS7Lpd/m2K1dPmPsTf\n'
          'uHmfchi9d8/hhiJCaspQOLCQe/yMlbpFJ6m+po+/aARNih24TB7Ru+NDpb9ymZ\n'
          '9L9rtG/Jq4+e9vNDkDaOsEgntM1x0RMQuf9axn3U61DgwEhogELhOWRBqTDpE\n'
          'KBVjBi28H26u0pw6WonyvQC7T6SCJqrNZaq1qFD93x7ll8kxvWcZWG7Wz15w+\n'
          'i5FLM3RydGk3NHQIDAQAB\n'
          '-----END PUBLIC KEY-----';
      String cardString = buildCardString(
        pan: '4012000033330026',
        expiryYear: '34',
        expiryMonth: '04',
        cvv: '123',
      );
      String encrypted = encryptCardData(
        cardString: cardString,
        publicKeyPemOrBase64Der: pem,
      );
      expect(encrypted, isNotEmpty);
      expect(() => base64Decode(encrypted), returnsNormally);
    });

    test('throws FormatException for invalid key', () {
      expect(
        () => encryptCardData(
          cardString: 'M123=3412:123',
          publicKeyPemOrBase64Der: 'not-a-valid-key',
        ),
        throwsFormatException,
      );
    });

    test(
      'produces different ciphertext on each call (OAEP randomized padding)',
      () {
        String cardString = buildCardString(
          pan: '5424180279791765',
          expiryYear: '34',
          expiryMonth: '06',
          cvv: '123',
        );
        String enc1 = encryptCardData(
          cardString: cardString,
          publicKeyPemOrBase64Der: _testPublicKeyBase64,
        );
        String enc2 = encryptCardData(
          cardString: cardString,
          publicKeyPemOrBase64Der: _testPublicKeyBase64,
        );
        // OAEP uses random padding, so two encryptions of the same
        // plaintext with the same key should (almost certainly) differ.
        expect(enc1, isNot(equals(enc2)));
      },
    );

    test('handles base64 DER key with embedded whitespace', () {
      // Insert whitespace/newlines into the key — encryptCardData should strip them.
      String keyWithWhitespace =
          '${_testPublicKeyBase64.substring(0, 40)}\n${_testPublicKeyBase64.substring(40, 80)} ${_testPublicKeyBase64.substring(80)}';
      String cardString = buildCardString(
        pan: '4111111111111111',
        expiryYear: '28',
        expiryMonth: '12',
        cvv: '456',
      );
      String encrypted = encryptCardData(
        cardString: cardString,
        publicKeyPemOrBase64Der: keyWithWhitespace,
      );
      expect(encrypted, isNotEmpty);
      expect(() => base64Decode(encrypted), returnsNormally);
    });

    test('encrypts short card string (minimal input)', () {
      // Short PAN, minimal card string
      String cardString = buildCardString(
        pan: '4000001234562',
        expiryYear: '30',
        expiryMonth: '01',
        cvv: '999',
      );
      String encrypted = encryptCardData(
        cardString: cardString,
        publicKeyPemOrBase64Der: _testPublicKeyBase64,
      );
      expect(encrypted, isNotEmpty);
      expect(base64Decode(encrypted).length, greaterThan(0));
    });

    test('encrypts Amex card string with 4-digit CVV', () {
      String cardString = buildCardString(
        pan: '371449635398431',
        expiryYear: '34',
        expiryMonth: '05',
        cvv: '1234',
      );
      String encrypted = encryptCardData(
        cardString: cardString,
        publicKeyPemOrBase64Der: _testPublicKeyBase64,
      );
      expect(encrypted, isNotEmpty);
      expect(() => base64Decode(encrypted), returnsNormally);
    });

    test('throws when given completely empty key', () {
      expect(
        () => encryptCardData(
          cardString: 'M4111111111111111=3412:123',
          publicKeyPemOrBase64Der: '',
        ),
        throwsA(anything),
      );
    });
  });

  group('buildCardString edge cases', () {
    test('handles empty fields without crashing', () {
      String s = buildCardString(
        pan: '',
        expiryYear: '',
        expiryMonth: '',
        cvv: '',
      );
      expect(s, 'M=:');
    });

    test('handles 19-digit PAN', () {
      String s = buildCardString(
        pan: '4111111111111111234',
        expiryYear: '29',
        expiryMonth: '11',
        cvv: '789',
      );
      expect(s, 'M4111111111111111234=2911:789');
    });
  });
}
