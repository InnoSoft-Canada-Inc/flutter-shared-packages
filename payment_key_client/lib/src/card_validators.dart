import 'card_data.dart';

/// Result of validating a [CardData] object.
///
/// [isValid] is true only when all field errors are null.
class CardValidationResult {
  /// Creates a [CardValidationResult].
  const CardValidationResult({
    this.panError,
    this.expiryMonthError,
    this.expiryYearError,
    this.cvvError,
  });

  /// Error message for the PAN field, or null if valid.
  final String? panError;

  /// Error message for the expiry month field, or null if valid.
  final String? expiryMonthError;

  /// Error message for the expiry year field, or null if valid.
  final String? expiryYearError;

  /// Error message for the CVV field, or null if valid.
  final String? cvvError;

  /// True when all fields are valid (all errors are null).
  bool get isValid =>
      panError == null &&
      expiryMonthError == null &&
      expiryYearError == null &&
      cvvError == null;
}

/// Validates a PAN using the Luhn algorithm.
///
/// Returns true when [pan] passes the Luhn check. Assumes [pan] contains
/// digits only (no spaces or dashes). Returns false for empty or single-digit input.
bool luhnCheck(String pan) {
  if (pan.length < 2) return false;
  int sum = 0;
  bool alternate = false;
  for (int i = pan.length - 1; i >= 0; i--) {
    int digit = int.tryParse(pan[i]) ?? -1;
    if (digit < 0) return false;
    if (alternate) {
      digit *= 2;
      if (digit > 9) digit -= 9;
    }
    sum += digit;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}

/// Validates a PAN: 13–19 digits and passes the Luhn check.
///
/// Returns null when valid, or an error message string when invalid.
/// [pan] must be digits only (strip spaces/dashes before calling).
String? validatePan(String pan) {
  if (pan.isEmpty) return 'Card number is required';
  if (!RegExp(r'^\d+$').hasMatch(pan)) {
    return 'Card number must contain digits only';
  }
  if (pan.length < 13 || pan.length > 19) {
    return 'Card number must be 13–19 digits';
  }
  if (!luhnCheck(pan)) return 'Invalid card number';
  return null;
}

/// Validates a two-digit expiry month (01–12).
///
/// Returns null when valid, or an error message string when invalid.
String? validateExpiryMonth(String month) {
  if (month.isEmpty) return 'Expiry month is required';
  if (!RegExp(r'^\d{2}$').hasMatch(month)) {
    return 'Month must be 2 digits (01–12)';
  }
  int m = int.parse(month);
  if (m < 1 || m > 12) return 'Month must be between 01 and 12';
  return null;
}

/// Validates a two-digit expiry year.
///
/// Returns null when valid, or an error message string when invalid.
/// Does not check whether the card is expired — use [validateExpiryNotPast]
/// when you also need to check the current date.
String? validateExpiryYear(String year) {
  if (year.isEmpty) return 'Expiry year is required';
  if (!RegExp(r'^\d{2}$').hasMatch(year)) {
    return 'Year must be 2 digits (e.g. 34)';
  }
  return null;
}

/// Validates a CVV: 3–4 digits.
///
/// Returns null when valid, or an error message string when invalid.
String? validateCvv(String cvv) {
  if (cvv.isEmpty) return 'CVV is required';
  if (!RegExp(r'^\d{3,4}$').hasMatch(cvv)) return 'CVV must be 3–4 digits';
  return null;
}

/// Returns an error message if [raw] could contain a PAN (primary account
/// number) in the cardholder name field.
///
/// Strips non-digits and rejects when 13 or more digits remain (PANs are
/// 13–19 digits; this also catches spaced or punctuated numbers). Returns null
/// otherwise. Empty [raw] returns null; use a separate required-field check
/// where needed.
String? validateNameOnCard(String raw) {
  final allDigits = raw.replaceAll(RegExp(r'\D'), '');
  if (allDigits.length >= 13) {
    return 'Enter the name on your card,\nnot the card number.';
  }
  return null;
}

/// Validates all fields of [cardData] and returns a [CardValidationResult].
///
/// Use [CardValidationResult.isValid] to check overall validity, or inspect
/// individual error fields to show per-field messages in the UI.
CardValidationResult validateCardData(CardData cardData) {
  return CardValidationResult(
    panError: validatePan(cardData.pan),
    expiryMonthError: validateExpiryMonth(cardData.expiryMonth),
    expiryYearError: validateExpiryYear(cardData.expiryYear),
    cvvError: validateCvv(cardData.cvv),
  );
}
