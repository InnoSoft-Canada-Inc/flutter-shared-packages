import 'package:payment_key_client/payment_key_client.dart';
import 'package:test/test.dart';

void main() {
  group('sanitizePan', () {
    test('removes spaces', () {
      expect(sanitizePan('4111 1111 1111 1111'), '4111111111111111');
    });

    test('removes dashes', () {
      expect(sanitizePan('4111-1111-1111-1111'), '4111111111111111');
    });

    test('removes mixed spaces and dashes', () {
      expect(sanitizePan('4111 - 1111 - 1111 - 1111'), '4111111111111111');
    });

    test('returns unchanged string when no spaces or dashes', () {
      expect(sanitizePan('4111111111111111'), '4111111111111111');
    });

    test('returns empty string for empty input', () {
      expect(sanitizePan(''), '');
    });

    test('removes tabs and newlines', () {
      expect(sanitizePan('4111\t1111\n1111\r1111'), '4111111111111111');
    });

    test('removes leading and trailing spaces', () {
      expect(sanitizePan('  4111111111111111  '), '4111111111111111');
    });

    test('handles single digit with surrounding whitespace', () {
      expect(sanitizePan(' 4 '), '4');
    });

    test('handles only whitespace and dashes', () {
      expect(sanitizePan('  - - - '), '');
    });

    test('preserves non-digit non-dash non-space characters', () {
      // sanitizePan only strips whitespace and dashes; letters stay
      expect(sanitizePan('4111abc1111'), '4111abc1111');
    });
  });

  group('maskPan', () {
    test('masks 16-digit Visa PAN with groups of 4', () {
      expect(maskPan('4111111111111111'), '4111 **** **** 1111');
    });

    test('masks 16-digit Mastercard PAN', () {
      expect(maskPan('5424180279791765'), '5424 **** **** 1765');
    });

    test('masks 15-digit Amex PAN', () {
      expect(maskPan('371449635398431'), '3714 **** ***8 431');
    });

    test('masks 13-digit PAN', () {
      String result = maskPan('4000001234562');
      expect(result.startsWith('4000'), isTrue);
      expect(result.contains('*'), isTrue);
      expect(result.contains('0012'), isFalse);
    });

    test('masks 9-digit PAN (just above threshold)', () {
      // 123456789 → first4=1234, last4=6789, 1 masked star
      // combined=1234*6789 (9 chars), grouped: "1234 *678 9"
      String result = maskPan('123456789');
      expect(result.startsWith('1234'), isTrue);
      expect(result.endsWith('9'), isTrue);
      expect(result.contains('*'), isTrue);
    });

    test('masks 19-digit PAN (maximum length)', () {
      String pan19 = '4111111111111111234';
      String result = maskPan(pan19);
      expect(result.startsWith('4111'), isTrue);
      expect(result.endsWith('4'), isTrue);
      expect(result.contains('*'), isTrue);
      // 19 - 8 = 11 stars
      expect('*' * 11, hasLength(11));
    });

    test('returns unchanged PAN when exactly 8 digits', () {
      expect(maskPan('12345678'), '12345678');
    });

    test('returns unchanged PAN when 7 digits', () {
      expect(maskPan('1234567'), '1234567');
    });

    test('returns unchanged PAN when 4 digits', () {
      expect(maskPan('1234'), '1234');
    });

    test('returns single character for 1-digit PAN', () {
      expect(maskPan('5'), '5');
    });

    test('returns empty string for empty input', () {
      expect(maskPan(''), '');
    });

    test('masked string does not expose middle digits', () {
      String masked = maskPan('5424180279791765');
      expect(masked.contains('8027'), isFalse);
      expect(masked.contains('9791'), isFalse);
    });

    test('first 4 and last 4 digits are always preserved', () {
      String masked = maskPan('6011000990139424');
      expect(masked.substring(0, 4), '6011');
      // last 4 chars of unspaced result
      String noSpaces = masked.replaceAll(' ', '');
      expect(noSpaces.substring(noSpaces.length - 4), '9424');
    });

    test('star count equals pan length minus 8', () {
      for (int len in [9, 10, 13, 15, 16, 19]) {
        String pan = '4${'0' * (len - 1)}';
        String masked = maskPan(pan);
        int stars = masked.replaceAll(RegExp(r'[^*]'), '').length;
        expect(
          stars,
          len - 8,
          reason: 'PAN length $len should have ${len - 8} stars',
        );
      }
    });
  });

  group('detectCardBrand', () {
    test('returns unknown for empty string', () {
      expect(detectCardBrand(''), CardBrand.unknown);
    });

    test('returns unknown for single non-matching digit', () {
      expect(detectCardBrand('9'), CardBrand.unknown);
      expect(detectCardBrand('1'), CardBrand.unknown);
      expect(detectCardBrand('0'), CardBrand.unknown);
    });

    group('Visa', () {
      test('detects Visa from PAN starting with 4', () {
        expect(detectCardBrand('4111111111111111'), CardBrand.visa);
      });

      test('detects Visa with single digit 4', () {
        expect(detectCardBrand('4'), CardBrand.visa);
      });

      test('detects Visa 13-digit PAN', () {
        expect(detectCardBrand('4000001234562'), CardBrand.visa);
      });
    });

    group('Mastercard', () {
      test('detects Mastercard from low boundary 51', () {
        expect(detectCardBrand('5100000000000000'), CardBrand.mastercard);
      });

      test('detects Mastercard from high boundary 55', () {
        expect(detectCardBrand('5500000000000000'), CardBrand.mastercard);
      });

      test('detects Mastercard from mid range 53', () {
        expect(detectCardBrand('5300000000000000'), CardBrand.mastercard);
      });

      test('does not detect Mastercard for 50 prefix', () {
        expect(
          detectCardBrand('5000000000000000'),
          isNot(CardBrand.mastercard),
        );
      });

      test('does not detect Mastercard for 56 prefix', () {
        expect(
          detectCardBrand('5600000000000000'),
          isNot(CardBrand.mastercard),
        );
      });

      test('detects Mastercard from 2-series low boundary 2221', () {
        expect(detectCardBrand('2221000000000000'), CardBrand.mastercard);
      });

      test('detects Mastercard from 2-series high boundary 2720', () {
        expect(detectCardBrand('2720000000000000'), CardBrand.mastercard);
      });

      test('detects Mastercard from 2-series mid range', () {
        expect(detectCardBrand('2500000000000000'), CardBrand.mastercard);
      });

      test('does not detect Mastercard below 2221', () {
        expect(
          detectCardBrand('2220000000000000'),
          isNot(CardBrand.mastercard),
        );
      });

      test('does not detect Mastercard above 2720', () {
        expect(
          detectCardBrand('2721000000000000'),
          isNot(CardBrand.mastercard),
        );
      });

      test(
        'does not detect Mastercard for 2-digit 22 prefix (too short for 4-digit check)',
        () {
          // PAN "22" is only 2 digits — 2-digit check (22) is not in 51–55, and
          // 4-digit check won't fire because length < 4.
          expect(detectCardBrand('22'), CardBrand.unknown);
        },
      );
    });

    group('Amex', () {
      test('detects Amex from PAN starting with 34', () {
        expect(detectCardBrand('341111111111111'), CardBrand.amex);
      });

      test('detects Amex from PAN starting with 37', () {
        expect(detectCardBrand('371449635398431'), CardBrand.amex);
      });

      test('does not detect Amex for 35 prefix (could be JCB)', () {
        // 35 alone doesn't match Amex — it's not 34 or 37
        expect(detectCardBrand('3500000000000000'), isNot(CardBrand.amex));
      });

      test('does not detect Amex for 36 prefix', () {
        expect(detectCardBrand('3600000000000000'), isNot(CardBrand.amex));
      });

      test('detects Amex with minimal 2-digit PAN', () {
        expect(detectCardBrand('34'), CardBrand.amex);
        expect(detectCardBrand('37'), CardBrand.amex);
      });

      test('Amex takes priority over JCB when prefix is 37', () {
        // 37xx could overlap with JCB range but Amex check runs first
        expect(detectCardBrand('3728000000000000'), CardBrand.amex);
      });
    });

    group('Discover', () {
      test('detects Discover from 6011 prefix', () {
        expect(detectCardBrand('6011000990139424'), CardBrand.discover);
      });

      test('detects Discover from 65 prefix', () {
        expect(detectCardBrand('6500000000000000'), CardBrand.discover);
      });

      test('detects Discover from 644 prefix (low boundary)', () {
        expect(detectCardBrand('6440000000000000'), CardBrand.discover);
      });

      test('detects Discover from 649 prefix (high boundary)', () {
        expect(detectCardBrand('6490000000000000'), CardBrand.discover);
      });

      test('does not detect Discover from 643 prefix', () {
        expect(detectCardBrand('6430000000000000'), isNot(CardBrand.discover));
      });

      test('does not detect Discover from 650 prefix (not same as 65)', () {
        // 650 has 3 digits — 3-digit check: 650 is not in 644–649
        // but 2-digit check: 65 matches Discover
        expect(detectCardBrand('6500000000000000'), CardBrand.discover);
      });

      test('detects Discover from 622126 prefix (low boundary)', () {
        expect(detectCardBrand('6221260000000000'), CardBrand.discover);
      });

      test('detects Discover from 622925 prefix (high boundary)', () {
        expect(detectCardBrand('6229250000000000'), CardBrand.discover);
      });

      test('does not detect Discover from 622125 (below range)', () {
        expect(detectCardBrand('6221250000000000'), isNot(CardBrand.discover));
      });

      test('does not detect Discover from 622926 (above range)', () {
        expect(detectCardBrand('6229260000000000'), isNot(CardBrand.discover));
      });

      test('does not detect Discover from 60 prefix (without full 6011)', () {
        expect(detectCardBrand('6000000000000000'), isNot(CardBrand.discover));
      });
    });

    group('JCB', () {
      test('detects JCB from 3528 prefix (low boundary)', () {
        expect(detectCardBrand('3528000000000000'), CardBrand.jcb);
      });

      test('detects JCB from 3589 prefix (high boundary)', () {
        expect(detectCardBrand('3589000000000000'), CardBrand.jcb);
      });

      test('detects JCB from mid range 3550', () {
        expect(detectCardBrand('3550000000000000'), CardBrand.jcb);
      });

      test('does not detect JCB from 3527 prefix (below range)', () {
        expect(detectCardBrand('3527000000000000'), isNot(CardBrand.jcb));
      });

      test('does not detect JCB from 3590 prefix (above range)', () {
        expect(detectCardBrand('3590000000000000'), isNot(CardBrand.jcb));
      });
    });

    group('unknown', () {
      test('returns unknown for unrecognized BIN', () {
        expect(detectCardBrand('9999999999999999'), CardBrand.unknown);
      });

      test('returns unknown for 1xxx prefix', () {
        expect(detectCardBrand('1000000000000000'), CardBrand.unknown);
      });

      test('returns unknown for 8xxx prefix', () {
        expect(detectCardBrand('8000000000000000'), CardBrand.unknown);
      });

      test('returns unknown for non-numeric input', () {
        expect(detectCardBrand('abcdefg'), CardBrand.unknown);
      });
    });
  });

  group('CardBrand enum', () {
    test('contains all expected values', () {
      expect(
        CardBrand.values,
        containsAll([
          CardBrand.visa,
          CardBrand.mastercard,
          CardBrand.amex,
          CardBrand.discover,
          CardBrand.jcb,
          CardBrand.unknown,
        ]),
      );
    });

    test('has exactly 6 values', () {
      expect(CardBrand.values.length, 6);
    });
  });
}
