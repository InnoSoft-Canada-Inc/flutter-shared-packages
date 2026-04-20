# payment_key_client

Dart client that calls a payment provider key endpoint with an **encrypted card payload** and returns the payment key. Use it after your app has obtained an access token (e.g. from the Payments API init) and encrypted the card data (e.g. with the RSA public key from init).

**This package does not call the InnoSoft Payments API and does not handle raw card data** — only encrypted payloads in, payment key out.

## Flow

1. Your app calls the Payments API (`POST /cards/init` or `POST /payments/init`) and gets `accessToken`, `publicKey`, and `providerInfo.baseUrl`.
2. Your app encrypts card data (e.g. using the RSA `publicKey`) per the provider’s requirements. **Card data must never be sent in the clear.** This package can do that for you — see [Card encryption](#card-encryption) below.
3. Your app calls this package with the access token, provider base URL, and encrypted payload.
4. This package POSTs to the provider’s key endpoint (e.g. `POST {baseUrl}/api/v2.1/payments/key`) and returns the payment key.
5. Your app sends that key to the Payments API (`POST /cards/save` or `POST /payments/capture`).

For the full flow and API details, see the [InnoSoft Payments API Integration Guide](../../handoff/API_INTEGRATION_GUIDE.md) in this repo.

## Usage

```dart
import 'package:payment_key_client/payment_key_client.dart';

// You have: accessToken, providerBaseUrl, and encryptedCardData from your init + encryption step.
final client = PaymentKeyClient();

final request = PaymentKeyRequest(
  accessToken: accessToken,
  providerBaseUrl: initResponse.providerInfo.baseUrl,
  encryptedCardData: encryptedCardData,
  paymentType: 1,
);

try {
  final response = await client.createPaymentKey(request);
  // Use response.paymentKey in POST /cards/save or POST /payments/capture
  await submitCapture(sessionId, response.paymentKey);
} on PaymentKeyException catch (e) {
  // Handle non-2xx or parse errors (e.statusCode, e.message, e.cause)
} catch (e) {
  // Handle network errors (e.g. SocketException, TimeoutException)
}
```

## Card encryption

The package can build the provider’s card string and encrypt it with RSA-OAEP (SHA-1), matching the behaviour of [card_encrypt.js](../card_encrypt.js) in this repo. Use this when you have PAN, expiry, and CVV and the init response’s `publicKey` (PEM or base64 DER).

```dart
import 'package:payment_key_client/payment_key_client.dart';

// After init: you have publicKey (and accessToken, providerBaseUrl).
String cardString = buildCardString(
  pan: '5424180279791765',       // digits only, no spaces
  expiryYear: '34',              // two-digit year
  expiryMonth: '06',             // two-digit month
  cvv: '123',
);
// Format: M<PAN>=<YY><MM>:<CVV> (e.g. M5424180279791765=3406:123)

String encryptedCardData = encryptCardData(
  cardString: cardString,
  publicKeyPemOrBase64Der: initResponse.publicKey!, // PEM or base64 DER (SPKI)
);

// Use encryptedCardData in PaymentKeyRequest.encryptedCardData
```

- **buildCardString**: Produces `M<PAN>=<YY><MM>:<CVV>` (same as the Node script).
- **encryptCardData**: RSA-OAEP with SHA-1; accepts either PEM (`-----BEGIN PUBLIC KEY-----...`) or base64-encoded DER (SPKI). Returns base64 ciphertext.

## Error handling

- **PaymentKeyException**: Thrown when the key endpoint returns a non-2xx status or when the response body cannot be parsed. It includes `statusCode`, optional `message` (response body), and optional `cause` (e.g. `FormatException`).
- Network and timeouts: Not wrapped; handle `SocketException`, `TimeoutException`, etc. as usual.

## Adding to your project

```yaml
dependencies:
  payment_key_client:
    path: ../path/to/packages/payment_key_client
```

Or publish the package and depend on it by name and version.

## License

Same as the parent InnoSoft Payments repository.
