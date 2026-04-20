import 'dart:convert';

import 'package:http/http.dart' as http;

import 'card_data.dart';
import 'card_encryption.dart';
import 'card_validators.dart';
import 'payment_key_exception.dart';
import 'payment_key_request.dart';
import 'payment_key_response.dart';

/// Client for the payment provider key endpoint.
///
/// Obtains a payment key by POSTing encrypted card data to the provider.
/// The app must supply [PaymentKeyRequest.accessToken] and
/// [PaymentKeyRequest.encryptedCardData] (encrypted elsewhere; never raw card data).
class PaymentKeyClient {
  /// Creates a [PaymentKeyClient].
  ///
  /// [httpClient]: Optional HTTP client for tests; defaults to [http.Client].
  PaymentKeyClient({http.Client? httpClient})
    : _client = httpClient ?? http.Client();

  final http.Client _client;

  /// Calls the provider key endpoint and returns the payment key response.
  ///
  /// Throws [PaymentKeyException] on non-2xx or parse errors. Callers should
  /// also handle network errors (e.g. [SocketException], [TimeoutException]).
  Future<PaymentKeyResponse> createPaymentKey(PaymentKeyRequest request) async {
    String url = _buildUrl(request.providerBaseUrl, request.keyPath);
    Uri uri = Uri.parse(url);
    Map<String, String> headers = {
      'Authorization': 'Bearer ${request.accessToken}',
      'Content-Type': 'application/json',
    };
    Map<String, dynamic> bodyMap = <String, dynamic>{
      'cardData': request.encryptedCardData,
      'paymentType': request.paymentType,
    };
    if (request.attributes != null && request.attributes!.isNotEmpty) {
      bodyMap['attributes'] = request.attributes;
    }
    String body = jsonEncode(bodyMap);

    http.Response response;
    try {
      response = await _client.post(uri, headers: headers, body: body);
    } catch (e) {
      throw PaymentKeyException(
        statusCode: -1,
        message: 'Request failed',
        cause: e,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentKeyException(
        statusCode: response.statusCode,
        message: response.body.isNotEmpty ? response.body : null,
      );
    }

    try {
      Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      return PaymentKeyResponse.fromJson(json);
    } catch (e) {
      throw PaymentKeyException(
        statusCode: response.statusCode,
        message: response.body,
        cause: e,
      );
    }
  }

  /// Validates, encrypts, and submits card data to the provider key endpoint.
  ///
  /// This is the high-level method for manual card entry flows. It combines:
  /// 1. Validation of [cardData] (throws [ArgumentError] if invalid), unless
  ///    [encryptedCardData] or [validateCvvOnly] applies — see below.
  /// 2. Building the provider card string via [buildCardString].
  /// 3. RSA-OAEP encryption via [encryptCardData] using [publicKey].
  /// 4. Calling [createPaymentKey] with the encrypted payload.
  ///
  /// **Pre-encrypted payload** — If [encryptedCardData] is non-null and non-empty after
  /// trim, it is sent as `cardData` with no validation and no RSA step. Use when the
  /// ciphertext was produced outside this package. [cardData] may be omitted in that case.
  ///
  /// **CVV-only validation** — When [validateCvvOnly] is true (saved-card CVV key flows),
  /// only [validateCvv] runs; PAN and expiry are not checked so placeholders or session
  /// values can be used with [buildCardString]. Ignored when [encryptedCardData] is used.
  ///
  /// [cardData]: Required when [encryptedCardData] is null or empty.
  /// [publicKey]: RSA public key from the init response — PEM or base64 DER SPKI.
  /// [accessToken]: Bearer token from the init response.
  /// [providerBaseUrl]: Provider base URL (e.g. `https://hpc.uat.freedompay.com`).
  /// [paymentType]: Payment type integer; defaults to `1` (card).
  /// [attributes]: Optional card attributes to include in the request body.
  /// [keyPath]: Endpoint path; defaults to [PaymentKeyRequest.defaultKeyPath].
  ///
  /// Throws [ArgumentError] when [cardData] fails validation (or is missing when required).
  /// Throws [PaymentKeyException] on HTTP or parse errors.
  /// Callers should also handle network errors (e.g. [SocketException]).
  Future<PaymentKeyResponse> encryptAndCreatePaymentKey({
    CardData? cardData,
    required String publicKey,
    required String accessToken,
    required String providerBaseUrl,
    int paymentType = 1,
    Map<String, String>? attributes,
    String keyPath = PaymentKeyRequest.defaultKeyPath,
    String? encryptedCardData,
    bool validateCvvOnly = false,
  }) async {
    final String? trimmedCipher = encryptedCardData?.trim();
    if (trimmedCipher != null && trimmedCipher.isNotEmpty) {
      return createPaymentKey(
        PaymentKeyRequest(
          accessToken: accessToken,
          providerBaseUrl: providerBaseUrl,
          encryptedCardData: trimmedCipher,
          paymentType: paymentType,
          attributes: attributes,
          keyPath: keyPath,
        ),
      );
    }

    final CardData? data = cardData;
    if (data == null) {
      throw ArgumentError(
        'cardData is required when encryptedCardData is null or empty.',
      );
    }

    if (validateCvvOnly) {
      String? cvvError = validateCvv(data.cvv);
      if (cvvError != null) {
        throw ArgumentError('CVV: $cvvError');
      }
    } else {
      CardValidationResult validation = validateCardData(data);
      if (!validation.isValid) {
        StringBuffer errors = StringBuffer();
        if (validation.panError != null) {
          errors.writeln('PAN: ${validation.panError}');
        }
        if (validation.expiryMonthError != null) {
          errors.writeln('Month: ${validation.expiryMonthError}');
        }
        if (validation.expiryYearError != null) {
          errors.writeln('Year: ${validation.expiryYearError}');
        }
        if (validation.cvvError != null) {
          errors.writeln('CVV: ${validation.cvvError}');
        }
        throw ArgumentError(errors.toString().trim());
      }
    }

    String cardString = buildCardString(
      pan: data.pan,
      expiryYear: data.expiryYear,
      expiryMonth: data.expiryMonth,
      cvv: data.cvv,
    );

    String encryptedPayload = encryptCardData(
      cardString: cardString,
      publicKeyPemOrBase64Der: publicKey,
    );

    return createPaymentKey(
      PaymentKeyRequest(
        accessToken: accessToken,
        providerBaseUrl: providerBaseUrl,
        encryptedCardData: encryptedPayload,
        paymentType: paymentType,
        attributes: attributes,
        keyPath: keyPath,
      ),
    );
  }

  /// Builds the full key endpoint URL (no double slashes).
  static String _buildUrl(String baseUrl, String keyPath) {
    String base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    String path = keyPath.startsWith('/') ? keyPath : '/$keyPath';
    return base + path;
  }
}
