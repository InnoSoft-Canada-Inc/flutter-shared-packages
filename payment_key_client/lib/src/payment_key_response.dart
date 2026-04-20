/// A single attribute from the key endpoint response (Key/Value pair).
class PaymentKeyAttribute {
  /// Creates a [PaymentKeyAttribute].
  const PaymentKeyAttribute({required this.key, required this.value});

  /// Parses from JSON object with "Key" and "Value" (PascalCase from API).
  factory PaymentKeyAttribute.fromJson(Map<String, dynamic> json) {
    String? k = json['Key'] as String?;
    String? v = json['Value'] as String?;
    return PaymentKeyAttribute(key: k ?? '', value: v ?? '');
  }

  /// Attribute name (e.g. CardIssuer, MaskedCardNumber, ExpirationDate).
  final String key;

  /// Attribute value.
  final String value;
}

/// Response from the payment provider key endpoint.
///
/// Matches FreedomPay HPC v2.1 shape: PaymentType, PaymentKeys (list), Attributes (list of Key/Value).
class PaymentKeyResponse {
  /// Creates a [PaymentKeyResponse].
  PaymentKeyResponse({
    required this.paymentType,
    required this.paymentKeys,
    List<PaymentKeyAttribute>? attributes,
  }) : attributes = attributes ?? const [];

  /// Parses [PaymentKeyResponse] from JSON.
  ///
  /// Expects PascalCase from API: PaymentType, PaymentKeys, Attributes (list of { Key, Value }).
  factory PaymentKeyResponse.fromJson(Map<String, dynamic> json) {
    String paymentType = json['PaymentType'] as String? ?? '';
    List<dynamic>? keysRaw = json['PaymentKeys'] as List<dynamic>?;
    List<String> paymentKeys = keysRaw != null
        ? keysRaw.map((e) => e.toString()).toList()
        : <String>[];

    if (paymentKeys.isEmpty) {
      throw FormatException(
        'Key endpoint response missing or empty PaymentKeys',
        json.toString(),
      );
    }

    List<PaymentKeyAttribute> attributes = <PaymentKeyAttribute>[];
    List<dynamic>? attrsRaw = json['Attributes'] as List<dynamic>?;
    if (attrsRaw != null) {
      for (dynamic item in attrsRaw) {
        if (item is Map<String, dynamic>) {
          attributes.add(PaymentKeyAttribute.fromJson(item));
        }
      }
    }

    return PaymentKeyResponse(
      paymentType: paymentType,
      paymentKeys: paymentKeys,
      attributes: attributes,
    );
  }

  /// Payment type label (e.g. "Card").
  final String paymentType;

  /// List of payment key IDs (e.g. UUIDs) to use for capture/save. Use the first for single-key flows.
  final List<String> paymentKeys;

  /// Card attributes returned by the provider (e.g. CardIssuer, MaskedCardNumber, ExpirationDate).
  final List<PaymentKeyAttribute> attributes;

  /// Convenience getter for the first payment key. Use [paymentKeys] when multiple keys are returned.
  String get paymentKey => paymentKeys.isNotEmpty ? paymentKeys.first : '';
}
