import 'package:payment_key_client/payment_key_client.dart';
import 'package:test/test.dart';

void main() {
  group('CardData', () {
    test('constructs with all required fields', () {
      const CardData card = CardData(
        pan: '5424180279791765',
        expiryMonth: '06',
        expiryYear: '34',
        cvv: '123',
      );
      expect(card.pan, '5424180279791765');
      expect(card.expiryMonth, '06');
      expect(card.expiryYear, '34');
      expect(card.cvv, '123');
    });

    test('supports const construction', () {
      // Both should be compile-time identical const instances
      const CardData a = CardData(
        pan: '4111',
        expiryMonth: '01',
        expiryYear: '27',
        cvv: '123',
      );
      const CardData b = CardData(
        pan: '4111',
        expiryMonth: '01',
        expiryYear: '27',
        cvv: '123',
      );
      expect(identical(a, b), isTrue);
    });

    group('copyWith', () {
      const CardData original = CardData(
        pan: '5424180279791765',
        expiryMonth: '06',
        expiryYear: '34',
        cvv: '123',
      );

      test('returns identical object when no fields are changed', () {
        CardData copy = original.copyWith();
        expect(copy, equals(original));
      });

      test('returns a new instance (not the same reference)', () {
        CardData copy = original.copyWith();
        expect(identical(copy, original), isFalse);
      });

      test('replaces pan only', () {
        CardData copy = original.copyWith(pan: '4111111111111111');
        expect(copy.pan, '4111111111111111');
        expect(copy.expiryMonth, original.expiryMonth);
        expect(copy.expiryYear, original.expiryYear);
        expect(copy.cvv, original.cvv);
      });

      test('replaces expiryMonth only', () {
        CardData copy = original.copyWith(expiryMonth: '12');
        expect(copy.expiryMonth, '12');
        expect(copy.pan, original.pan);
        expect(copy.expiryYear, original.expiryYear);
        expect(copy.cvv, original.cvv);
      });

      test('replaces expiryYear only', () {
        CardData copy = original.copyWith(expiryYear: '29');
        expect(copy.expiryYear, '29');
        expect(copy.pan, original.pan);
        expect(copy.expiryMonth, original.expiryMonth);
        expect(copy.cvv, original.cvv);
      });

      test('replaces cvv only', () {
        CardData copy = original.copyWith(cvv: '999');
        expect(copy.cvv, '999');
        expect(copy.pan, original.pan);
        expect(copy.expiryMonth, original.expiryMonth);
        expect(copy.expiryYear, original.expiryYear);
      });

      test('replaces all fields at once', () {
        CardData copy = original.copyWith(
          pan: '4111111111111111',
          expiryMonth: '01',
          expiryYear: '27',
          cvv: '456',
        );
        expect(copy.pan, '4111111111111111');
        expect(copy.expiryMonth, '01');
        expect(copy.expiryYear, '27');
        expect(copy.cvv, '456');
      });

      test('chained copyWith builds up correctly', () {
        CardData result = original
            .copyWith(pan: '4111111111111111')
            .copyWith(cvv: '456');
        expect(result.pan, '4111111111111111');
        expect(result.cvv, '456');
        expect(result.expiryMonth, original.expiryMonth);
        expect(result.expiryYear, original.expiryYear);
      });
    });

    group('equality', () {
      test('two CardData with same fields are equal', () {
        const CardData a = CardData(
          pan: '4111111111111111',
          expiryMonth: '01',
          expiryYear: '27',
          cvv: '123',
        );
        const CardData b = CardData(
          pan: '4111111111111111',
          expiryMonth: '01',
          expiryYear: '27',
          cvv: '123',
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('two CardData with different pan are not equal', () {
        const CardData a = CardData(
          pan: '4111111111111111',
          expiryMonth: '01',
          expiryYear: '27',
          cvv: '123',
        );
        const CardData b = CardData(
          pan: '5424180279791765',
          expiryMonth: '01',
          expiryYear: '27',
          cvv: '123',
        );
        expect(a, isNot(equals(b)));
      });

      test('two CardData with different expiryMonth are not equal', () {
        const CardData a = CardData(
          pan: '4111111111111111',
          expiryMonth: '01',
          expiryYear: '27',
          cvv: '123',
        );
        const CardData b = CardData(
          pan: '4111111111111111',
          expiryMonth: '12',
          expiryYear: '27',
          cvv: '123',
        );
        expect(a, isNot(equals(b)));
      });

      test('two CardData with different expiryYear are not equal', () {
        const CardData a = CardData(
          pan: '4111111111111111',
          expiryMonth: '01',
          expiryYear: '27',
          cvv: '123',
        );
        const CardData b = CardData(
          pan: '4111111111111111',
          expiryMonth: '01',
          expiryYear: '30',
          cvv: '123',
        );
        expect(a, isNot(equals(b)));
      });

      test('two CardData with different cvv are not equal', () {
        const CardData a = CardData(
          pan: '4111111111111111',
          expiryMonth: '01',
          expiryYear: '27',
          cvv: '123',
        );
        const CardData b = CardData(
          pan: '4111111111111111',
          expiryMonth: '01',
          expiryYear: '27',
          cvv: '999',
        );
        expect(a, isNot(equals(b)));
      });

      test('is not equal to a non-CardData object', () {
        const CardData a = CardData(
          pan: '4111111111111111',
          expiryMonth: '01',
          expiryYear: '27',
          cvv: '123',
        );
        expect(a, isNot(equals('not a CardData')));
      });

      test('is equal to itself (identity)', () {
        const CardData a = CardData(
          pan: '4111111111111111',
          expiryMonth: '01',
          expiryYear: '27',
          cvv: '123',
        );
        expect(a == a, isTrue);
      });
    });

    group('hashCode', () {
      test('equal objects have same hashCode', () {
        const CardData a = CardData(
          pan: '4111111111111111',
          expiryMonth: '01',
          expiryYear: '27',
          cvv: '123',
        );
        const CardData b = CardData(
          pan: '4111111111111111',
          expiryMonth: '01',
          expiryYear: '27',
          cvv: '123',
        );
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different objects likely have different hashCode', () {
        const CardData a = CardData(
          pan: '4111111111111111',
          expiryMonth: '01',
          expiryYear: '27',
          cvv: '123',
        );
        const CardData b = CardData(
          pan: '5424180279791765',
          expiryMonth: '06',
          expiryYear: '34',
          cvv: '999',
        );
        expect(a.hashCode, isNot(equals(b.hashCode)));
      });
    });

    group('toString', () {
      test('masks all but last 4 digits of pan', () {
        const CardData card = CardData(
          pan: '5424180279791765',
          expiryMonth: '06',
          expiryYear: '34',
          cvv: '123',
        );
        String s = card.toString();
        expect(s.contains('1765'), isTrue);
        expect(s.contains('5424'), isFalse);
        expect(s.contains('cvv: ***'), isTrue);
      });

      test('shows **** for short PAN (4 digits or fewer)', () {
        const CardData card = CardData(
          pan: '1234',
          expiryMonth: '01',
          expiryYear: '27',
          cvv: '123',
        );
        String s = card.toString();
        expect(s.contains('****'), isTrue);
        // short PAN should not leak digits
        expect(s.contains('1234'), isFalse);
      });

      test('includes expiryMonth and expiryYear', () {
        const CardData card = CardData(
          pan: '4111111111111111',
          expiryMonth: '03',
          expiryYear: '28',
          cvv: '456',
        );
        String s = card.toString();
        expect(s.contains('expiryMonth: 03'), isTrue);
        expect(s.contains('expiryYear: 28'), isTrue);
      });

      test('never exposes cvv value', () {
        const CardData card = CardData(
          pan: '4111111111111111',
          expiryMonth: '03',
          expiryYear: '28',
          cvv: '456',
        );
        String s = card.toString();
        expect(s.contains('456'), isFalse);
        expect(s.contains('cvv: ***'), isTrue);
      });

      test('starts with CardData(', () {
        const CardData card = CardData(
          pan: '4111111111111111',
          expiryMonth: '03',
          expiryYear: '28',
          cvv: '456',
        );
        expect(card.toString().startsWith('CardData('), isTrue);
      });

      test('handles empty pan', () {
        const CardData card = CardData(
          pan: '',
          expiryMonth: '01',
          expiryYear: '27',
          cvv: '123',
        );
        // Empty PAN length is 0, which is ≤ 4, so it should show "****"
        String s = card.toString();
        expect(s.contains('****'), isTrue);
      });
    });
  });
}
