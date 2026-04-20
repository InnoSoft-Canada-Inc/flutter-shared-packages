/// Immutable representation of the card data collected from the user.
///
/// All fields are pre-sanitized strings (no spaces, no dashes). Use
/// [copyWith] to build up the object across multi-step UI flows.
class CardData {
  /// Creates a [CardData].
  ///
  /// [pan]: Primary account number — digits only, no spaces or dashes.
  /// [expiryMonth]: Two-digit month, e.g. `"06"`.
  /// [expiryYear]: Two-digit year, e.g. `"34"` for 2034.
  /// [cvv]: Card verification value, 3–4 digits.
  const CardData({
    required this.pan,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
  });

  /// Primary account number (digits only, no spaces or dashes).
  final String pan;

  /// Two-digit expiry month (`"01"`–`"12"`).
  final String expiryMonth;

  /// Two-digit expiry year (e.g. `"34"` for 2034).
  final String expiryYear;

  /// Card verification value (3 digits for most cards, 4 for Amex).
  final String cvv;

  /// Returns a copy of this [CardData] with the given fields replaced.
  CardData copyWith({
    String? pan,
    String? expiryMonth,
    String? expiryYear,
    String? cvv,
  }) {
    return CardData(
      pan: pan ?? this.pan,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cvv: cvv ?? this.cvv,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardData &&
          runtimeType == other.runtimeType &&
          pan == other.pan &&
          expiryMonth == other.expiryMonth &&
          expiryYear == other.expiryYear &&
          cvv == other.cvv;

  @override
  int get hashCode =>
      pan.hashCode ^ expiryMonth.hashCode ^ expiryYear.hashCode ^ cvv.hashCode;

  @override
  String toString() =>
      'CardData(pan: ${pan.length > 4 ? "*" * (pan.length - 4) + pan.substring(pan.length - 4) : "****"}, '
      'expiryMonth: $expiryMonth, expiryYear: $expiryYear, cvv: ***)';
}
