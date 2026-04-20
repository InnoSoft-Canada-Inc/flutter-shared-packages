/// Flutter package for payment key generation.
///
/// Provides card data modelling, validation, PAN utilities, RSA-OAEP encryption,
/// and a client for the FreedomPay HPC v2.1 (and compatible) payment key endpoint.
///
/// ## Typical usage (manual card entry)
///
/// ```dart
/// final client = PaymentKeyClient();
/// final cardData = CardData(
///   pan: sanitizePan('5424 1802 7979 1765'),
///   expiryMonth: '06',
///   expiryYear: '34',
///   cvv: '123',
/// );
/// final response = await client.encryptAndCreatePaymentKey(
///   cardData: cardData,
///   publicKey: publicKeyFromInitResponse,
///   accessToken: accessTokenFromInitResponse,
///   providerBaseUrl: 'https://hpc.uat.freedompay.com',
/// );
/// print(response.paymentKey); // UUID to pass to capture/save endpoint
/// ```
library;

export 'src/card_data.dart' show CardData;
export 'src/card_encryption.dart' show buildCardString, encryptCardData;
export 'src/card_utils.dart'
    show CardBrand, detectCardBrand, maskPan, sanitizePan;
export 'src/card_validators.dart'
    show
        CardValidationResult,
        luhnCheck,
        validateCardData,
        validateCvv,
        validateExpiryMonth,
        validateExpiryYear,
        validateNameOnCard,
        validatePan;
export 'src/payment_key_client.dart' show PaymentKeyClient;
export 'src/payment_key_exception.dart' show PaymentKeyException;
export 'src/payment_key_request.dart' show PaymentKeyRequest;
export 'src/payment_key_response.dart'
    show PaymentKeyAttribute, PaymentKeyResponse;
