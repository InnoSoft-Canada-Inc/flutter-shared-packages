/// Card network brand derived from the BIN (Bank Identification Number) prefix.
enum CardBrand {
  /// Visa — starts with 4.
  visa,

  /// Mastercard — starts with 51–55 or 2221–2720.
  mastercard,

  /// American Express — starts with 34 or 37.
  amex,

  /// Discover — starts with 6011, 622126–622925, 644–649, or 65.
  discover,

  /// JCB — starts with 3528–3589.
  jcb,

  /// Unknown or unrecognized BIN prefix.
  unknown,
}

/// Removes all whitespace and dash characters from [raw].
///
/// Use before storing or passing a PAN to [buildCardString] or validators.
String sanitizePan(String raw) => raw.replaceAll(RegExp(r'[\s\-]'), '');

/// Returns a masked PAN string safe for display.
///
/// For PANs longer than 8 digits the middle digits are replaced with `****`
/// and the result is grouped into 4-character blocks, e.g.:
/// - 16 digits: `"4242 **** **** 4242"`
/// - 15 digits (Amex): `"3714 ****** 4242"`
/// - 13 digits: `"4111 ***** 111"`
///
/// For PANs of 8 digits or fewer the full number is returned unchanged.
String maskPan(String pan) {
  if (pan.length <= 8) return pan;
  String first4 = pan.substring(0, 4);
  String last4 = pan.substring(pan.length - 4);
  int maskedCount = pan.length - 8;
  String masked = '*' * maskedCount;
  String combined = first4 + masked + last4;
  // Group into 4-character blocks separated by spaces.
  StringBuffer result = StringBuffer();
  for (int i = 0; i < combined.length; i++) {
    if (i > 0 && i % 4 == 0) result.write(' ');
    result.write(combined[i]);
  }
  return result.toString();
}

/// Detects the card brand from the first few digits of [pan].
///
/// [pan] should contain digits only (use [sanitizePan] first). Returns
/// [CardBrand.unknown] when the BIN prefix does not match any known brand.
CardBrand detectCardBrand(String pan) {
  if (pan.isEmpty) return CardBrand.unknown;

  // Amex: 34, 37
  if (pan.length >= 2) {
    int twoDigit = int.tryParse(pan.substring(0, 2)) ?? -1;
    if (twoDigit == 34 || twoDigit == 37) return CardBrand.amex;
  }

  // Visa: starts with 4
  if (pan[0] == '4') return CardBrand.visa;

  // Mastercard: 51–55 or 2221–2720
  if (pan.length >= 2) {
    int twoDigit = int.tryParse(pan.substring(0, 2)) ?? -1;
    if (twoDigit >= 51 && twoDigit <= 55) return CardBrand.mastercard;
  }
  if (pan.length >= 4) {
    int fourDigit = int.tryParse(pan.substring(0, 4)) ?? -1;
    if (fourDigit >= 2221 && fourDigit <= 2720) return CardBrand.mastercard;
  }

  // Discover: 6011, 622126–622925, 644–649, 65
  if (pan.length >= 4 && pan.substring(0, 4) == '6011') return CardBrand.discover;
  if (pan.length >= 6) {
    int sixDigit = int.tryParse(pan.substring(0, 6)) ?? -1;
    if (sixDigit >= 622126 && sixDigit <= 622925) return CardBrand.discover;
  }
  if (pan.length >= 3) {
    int threeDigit = int.tryParse(pan.substring(0, 3)) ?? -1;
    if (threeDigit >= 644 && threeDigit <= 649) return CardBrand.discover;
  }
  if (pan.length >= 2 && pan.substring(0, 2) == '65') return CardBrand.discover;

  // JCB: 3528–3589
  if (pan.length >= 4) {
    int fourDigit = int.tryParse(pan.substring(0, 4)) ?? -1;
    if (fourDigit >= 3528 && fourDigit <= 3589) return CardBrand.jcb;
  }

  return CardBrand.unknown;
}
