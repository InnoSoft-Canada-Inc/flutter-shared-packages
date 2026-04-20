/// Request to obtain a payment key from the provider key endpoint.
///
/// [encryptedCardData] must be produced by the app (e.g. RSA with [publicKey]
/// from init). It must never be raw card data.
class PaymentKeyRequest {
  /// Creates a [PaymentKeyRequest].
  ///
  /// [accessToken]: Bearer token from init (e.g. from Payments API).
  /// [providerBaseUrl]: Provider base URL without trailing slash (e.g. `https://hpc.uat.freedompay.com`).
  /// [encryptedCardData]: Base64 or opaque encrypted payload; this package does not interpret it.
  /// [paymentType]: e.g. `1` for card (align with provider docs).
  /// [attributes]: Optional card attributes (e.g. CardIssuer, MaskedCardNumber, ExpirationDate).
  /// [keyPath]: Path to the key endpoint; default is FreedomPay HPC v2.1 style.
  PaymentKeyRequest({
    required this.accessToken,
    required this.providerBaseUrl,
    required this.encryptedCardData,
    required this.paymentType,
    this.attributes,
    this.keyPath = defaultKeyPath,
  });

  /// Default path for FreedomPay HPC v2.1 payments key endpoint.
  static const String defaultKeyPath = '/api/v2.1/payments/key';

  /// Bearer token for the provider (from init response).
  final String accessToken;

  /// Provider base URL (no trailing slash).
  final String providerBaseUrl;

  /// Encrypted card payload. Must be produced by the app (e.g. RSA with publicKey from init); never raw card data.
  final String encryptedCardData;

  /// Payment type (e.g. 1 = card, 2, 5, 6).
  final int paymentType;

  /// Optional card attributes (e.g. CardIssuer, MaskedCardNumber, ExpirationDate). Sent as request body "attributes" object.
  final Map<String, String>? attributes;

  /// Endpoint path (default [defaultKeyPath]).
  final String keyPath;
}
