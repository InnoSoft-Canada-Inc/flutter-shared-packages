# payment_key_client — Package Guide

A Flutter/Dart package for generating payment keys from encrypted card data. Handles card data modelling, validation, PAN utilities, RSA-OAEP encryption, and the HTTP call to the payment provider's key endpoint — all as a single, reusable dependency.

---

## Table of contents

1. [Overview](#overview)
2. [How it fits into the payment flow](#how-it-fits-into-the-payment-flow)
3. [Adding the package](#adding-the-package)
4. [Quick start](#quick-start)
5. [Features](#features)
   - [CardData model](#1-carddata-model)
   - [Card validators](#2-card-validators)
   - [PAN utilities](#3-pan-utilities)
   - [Card string building and RSA-OAEP encryption](#4-card-string-building-and-rsa-oaep-encryption)
   - [High-level orchestration — encryptAndCreatePaymentKey](#5-high-level-orchestration--encryptandcreatepaymentkey)
   - [Low-level HTTP client — createPaymentKey](#6-low-level-http-client--createpaymentkey)
   - [Error handling](#7-error-handling)
6. [Multi-product usage patterns](#multi-product-usage-patterns)
7. [What stays in your app](#what-stays-in-your-app)
8. [Public API reference](#public-api-reference)

---

## Overview

When a user enters card details in your app, three things have to happen before you can capture or save a payment:

1. **Encrypt** the card data on-device using the provider's RSA public key (from your Payments API init response).
2. **POST** the encrypted payload to the provider's key endpoint to exchange it for a short-lived payment key.
3. **Submit** that payment key to the InnoSoft Payments API (`POST /payments/capture` or `POST /cards/save`).

This package handles steps 1 and 2 completely, and gives you the data model and validation tools to safely collect the card details for step 0.

**What this package never does:**

- Transmit raw card numbers to any server.
- Call the InnoSoft Payments API directly.
- Depend on the `pay` Flutter package (Apple Pay / Google Pay stay in your app).

---

## How it fits into the payment flow

```
App                          InnoSoft Payments API        FreedomPay HPC
 |                                    |                         |
 |── POST /payments/init ────────────>|                         |
 |<─ { accessToken, publicKey,        |                         |
 |     providerInfo.baseUrl } ────────|                         |
 |                                    |                         |
 |  [user enters card details]        |                         |
 |                                    |                         |
 |  CardData + sanitizePan()          |                         |
 |  validateCardData()                |                         |
 |  encryptAndCreatePaymentKey() ─────────────────────────────>|
 |                                    |    POST /api/v2.1/payments/key
 |<─ PaymentKeyResponse ──────────────────────────────────────|
 |   { paymentKey }                   |                         |
 |                                    |                         |
 |── POST /payments/capture ─────────>|                         |
 |   { sessionId, paymentKey }        |                         |
```

---

## Adding the package

### Path dependency (monorepo)

```yaml
# your_app/pubspec.yaml
dependencies:
  payment_key_client:
    path: ../payment_key_client
```

### Published package (when released to pub.dev or a private registry)

```yaml
dependencies:
  payment_key_client: ^0.1.0
```

Then run:

```bash
flutter pub get
```

---

## Quick start

The simplest integration — one method call after collecting card details from the user:

```dart
import 'package:payment_key_client/payment_key_client.dart';

// 1. Build a CardData from what the user typed.
final cardData = CardData(
  pan: sanitizePan('5424 1802 7979 1765'), // strips spaces → '5424180279791765'
  expiryMonth: '06',
  expiryYear: '34',
  cvv: '123',
);

// 2. Validate before submitting (optional but recommended).
final validation = validateCardData(cardData);
if (!validation.isValid) {
  // Show validation.panError, validation.expiryMonthError, etc.
  return;
}

// 3. Encrypt, call the provider key endpoint, and get the payment key.
final client = PaymentKeyClient();
try {
  final response = await client.encryptAndCreatePaymentKey(
    cardData: cardData,
    publicKey: initResponse.publicKey,       // from POST /payments/init
    accessToken: initResponse.accessToken,   // from POST /payments/init
    providerBaseUrl: initResponse.providerInfo.baseUrl,
  );

  // 4. Use the payment key with the InnoSoft Payments API.
  await submitCapture(sessionId: session.id, paymentKey: response.paymentKey);

} on PaymentKeyException catch (e) {
  // e.statusCode — HTTP status from the provider (400, 401, 502, etc.)
  // e.message   — response body excerpt
  print('Provider error ${e.statusCode}: ${e.message}');
} catch (e) {
  // Handle SocketException, TimeoutException, etc.
  print('Network error: $e');
}
```

---

## Features

### 1. CardData model

`CardData` is an immutable value object that represents the card fields collected from the user. It is the central data carrier across multi-step UI flows.

```dart
const card = CardData(
  pan: '5424180279791765',  // digits only, no spaces
  expiryMonth: '06',        // "01"–"12"
  expiryYear: '34',         // two-digit year, e.g. "34" for 2034
  cvv: '123',               // 3 digits (4 for Amex)
);
```

**`copyWith`** — build up the object across multiple screens without mutation:

```dart
// Screen 1: collect PAN
CardData data = CardData(pan: sanitizePan(input), expiryMonth: '', expiryYear: '', cvv: '');

// Screen 2: add expiry and CVV
data = data.copyWith(expiryMonth: '06', expiryYear: '34', cvv: '123');
```

**Safe `toString`** — the last 4 digits of the PAN are visible; all other PAN digits and CVV are redacted. Safe to log.

```
CardData(pan: ************1765, expiryMonth: 06, expiryYear: 34, cvv: ***)
```

**Value equality** — two `CardData` instances with the same fields are `==` and share the same `hashCode`.

---

### 2. Card validators

Pure Dart validation functions with no Flutter dependency. All functions return `null` on success or a human-readable error string on failure, making them directly usable as Flutter `FormField` validators.

#### Individual field validators

| Function | What it checks | Example error |
|---|---|---|
| `validatePan(pan)` | 13–19 digits, Luhn check | `"Invalid card number"` |
| `validateExpiryMonth(month)` | Exactly 2 digits, 01–12 | `"Month must be between 01 and 12"` |
| `validateExpiryYear(year)` | Exactly 2 digits | `"Year must be 2 digits (e.g. 34)"` |
| `validateCvv(cvv)` | 3–4 digits | `"CVV must be 3–4 digits"` |

```dart
TextFormField(
  controller: _panController,
  validator: (v) => validatePan(sanitizePan(v ?? '')),
)
```

#### Full-card validator

`validateCardData(CardData)` validates all fields at once and returns a `CardValidationResult`:

```dart
final result = validateCardData(cardData);

if (!result.isValid) {
  print(result.panError);          // null or error string
  print(result.expiryMonthError);  // null or error string
  print(result.expiryYearError);   // null or error string
  print(result.cvvError);          // null or error string
}
```

#### Luhn check

`luhnCheck(String pan)` is also exported directly if you need the raw algorithm:

```dart
bool valid = luhnCheck('5424180279791765'); // true
bool invalid = luhnCheck('4111111111111112'); // false
```

---

### 3. PAN utilities

#### `sanitizePan`

Strips all whitespace and dashes from a raw user-entered PAN string. Always call this before validation or encryption.

```dart
sanitizePan('5424 1802 7979 1765')  // → '5424180279791765'
sanitizePan('5424-1802-7979-1765')  // → '5424180279791765'
```

#### `maskPan`

Returns a display-safe masked PAN, grouping digits into 4-character blocks with the middle digits replaced by asterisks. Use this in confirmation screens and read-only card summaries.

```dart
maskPan('5424180279791765')  // → '5424 **** **** 1765'
maskPan('371449635398431')   // → '3714 **** ***8 431'  (15-digit Amex)
```

#### `detectCardBrand`

Returns a `CardBrand` enum value based on the BIN (first digits) of the PAN. Useful for showing the correct card logo or applying card-specific rules (e.g. 4-digit CVV for Amex).

```dart
detectCardBrand('5424180279791765')  // → CardBrand.mastercard
detectCardBrand('4111111111111111')  // → CardBrand.visa
detectCardBrand('371449635398431')   // → CardBrand.amex
detectCardBrand('6011000990139424')  // → CardBrand.discover
detectCardBrand('3530111333300000')  // → CardBrand.jcb
detectCardBrand('9999999999999999')  // → CardBrand.unknown
```

**`CardBrand` values:** `visa`, `mastercard`, `amex`, `discover`, `jcb`, `unknown`

---

### 4. Card string building and RSA-OAEP encryption

These lower-level functions are available if you need to control the encryption step separately from the HTTP call.

#### `buildCardString`

Formats card fields into the provider's expected wire format: `M<PAN>=<YY><MM>:<CVV>`.

```dart
final cardString = buildCardString(
  pan: '5424180279791765',
  expiryYear: '34',
  expiryMonth: '06',
  cvv: '123',
);
// → 'M5424180279791765=3406:123'
```

This matches the format expected by FreedomPay HPC and mirrors the `card_encrypt.js` reference implementation.

#### `encryptCardData`

Encrypts a card string using RSA-OAEP with SHA-1, matching Node.js `crypto.publicEncrypt({ padding: RSA_PKCS1_OAEP_PADDING, oaepHash: 'sha1' })`. Accepts the public key in either PEM or base64-encoded DER (SPKI) format — both formats are returned by the InnoSoft Payments API init endpoint.

```dart
final encrypted = encryptCardData(
  cardString: cardString,
  publicKeyPemOrBase64Der: initResponse.publicKey,
);
// Returns a base64-encoded ciphertext string.
```

---

### 5. High-level orchestration — `encryptAndCreatePaymentKey`

The recommended entry point for manual card entry flows. Combines all steps — validation, card string formatting, encryption, and the HTTP call — into a single `async` method.

```dart
final response = await PaymentKeyClient().encryptAndCreatePaymentKey(
  cardData: cardData,
  publicKey: initResponse.publicKey,
  accessToken: initResponse.accessToken,
  providerBaseUrl: initResponse.providerInfo.baseUrl,
  paymentType: 1,                                    // optional, default 1
  attributes: {'CardIssuer': 'Mastercard'},          // optional
  keyPath: '/api/v2.1/payments/key',                 // optional, default shown
);

print(response.paymentKey);   // UUID to pass to /payments/capture or /cards/save
```

**What it does internally:**

1. Calls `validateCardData(cardData)` — throws `ArgumentError` if any field is invalid.
2. Calls `buildCardString(...)` to format the card data.
3. Calls `encryptCardData(...)` to RSA-OAEP encrypt it.
4. POSTs to `{providerBaseUrl}{keyPath}` and parses the response.

**Throws:**

- `ArgumentError` — card data is invalid (check `CardValidationResult` before calling if you want per-field errors in the UI).
- `PaymentKeyException` — provider returned a non-2xx status or unparseable body.
- `SocketException` / `TimeoutException` — network failure (not wrapped; handle separately).

---

### 6. Low-level HTTP client — `createPaymentKey`

Use this when you are managing encryption yourself (e.g. using a hardware security module or a pre-encrypted payload from another system).

```dart
final request = PaymentKeyRequest(
  accessToken: accessToken,
  providerBaseUrl: 'https://hpc.uat.freedompay.com',
  encryptedCardData: myAlreadyEncryptedPayload,
  paymentType: 1,
  attributes: {'MaskedCardNumber': 'XXXXXXXXXXXX1765', 'ExpirationDate': '06/34'},
  keyPath: '/api/v2.1/payments/key',  // optional override
);

final response = await PaymentKeyClient().createPaymentKey(request);
```

**`PaymentKeyRequest` fields:**

| Field | Required | Description |
|---|---|---|
| `accessToken` | Yes | Bearer token from init response |
| `providerBaseUrl` | Yes | Provider base URL, e.g. `https://hpc.uat.freedompay.com` |
| `encryptedCardData` | Yes | Base64-encoded RSA-OAEP ciphertext |
| `paymentType` | Yes | Integer, e.g. `1` for card, `5` for Apple Pay wallet |
| `attributes` | No | `Map<String, String>` of card attributes (CardIssuer, MaskedCardNumber, etc.) |
| `keyPath` | No | Defaults to `/api/v2.1/payments/key` |

**`PaymentKeyResponse` fields:**

| Field | Type | Description |
|---|---|---|
| `paymentKey` | `String` | Convenience getter for the first key in `paymentKeys` |
| `paymentKeys` | `List<String>` | All payment key UUIDs returned by the provider |
| `paymentType` | `String` | Payment type label from the provider (e.g. `"Card"`) |
| `attributes` | `List<PaymentKeyAttribute>` | Key/Value pairs returned by the provider |

---

### 7. Error handling

#### `PaymentKeyException`

Thrown by both `createPaymentKey` and `encryptAndCreatePaymentKey` for HTTP-level failures.

```dart
try {
  final response = await client.encryptAndCreatePaymentKey(...);
} on PaymentKeyException catch (e) {
  switch (e.statusCode) {
    case 400:
      // Invalid request — check your card data or session state
    case 401:
      // Access token expired or invalid — re-run init
    case 502:
      // Provider upstream failure — retry with backoff
    case -1:
      // Network failure wrapped as PaymentKeyException
    default:
      // Unexpected status
  }
}
```

| Property | Type | Description |
|---|---|---|
| `statusCode` | `int` | HTTP status code; `-1` for network-level failures |
| `message` | `String?` | Response body excerpt (avoid logging in production) |
| `cause` | `Object?` | Original exception when wrapping a parse or network error |

#### `ArgumentError` (from `encryptAndCreatePaymentKey` only)

Thrown before any network call when `CardData` fails validation. Prefer calling `validateCardData` beforehand to surface per-field errors in the UI, and use this as a final safety net.

```dart
} on ArgumentError catch (e) {
  // e.message contains the combined validation errors
}
```

#### Network errors

`SocketException`, `TimeoutException`, etc. are not wrapped and propagate as-is. Handle them alongside `PaymentKeyException`:

```dart
} catch (e) {
  // Covers SocketException, TimeoutException, and anything unexpected
  showErrorMessage('Network error. Please try again.');
}
```

---

## Multi-product usage patterns

### Pattern A — Single-screen card form

The simplest approach: one screen collects all card fields and submits.

```dart
Future<void> onSubmit() async {
  if (!_formKey.currentState!.validate()) return;

  final cardData = CardData(
    pan: sanitizePan(_panController.text),
    expiryMonth: _monthController.text.trim(),
    expiryYear: _yearController.text.trim(),
    cvv: _cvvController.text.trim(),
  );

  final response = await PaymentKeyClient().encryptAndCreatePaymentKey(
    cardData: cardData,
    publicKey: widget.publicKey,
    accessToken: widget.accessToken,
    providerBaseUrl: widget.providerBaseUrl,
  );

  onPaymentKey(response.paymentKey);
}
```

### Pattern B — Multi-step card flow

Use `CardData.copyWith` to carry state between screens without passing mutable controllers.

```dart
// Screen 1 — PAN entry
Navigator.push(context, MaterialPageRoute(
  builder: (_) => ExpiryScreen(
    cardData: CardData(
      pan: sanitizePan(_panController.text),
      expiryMonth: '', expiryYear: '', cvv: '',
    ),
    ...
  ),
));

// Screen 2 — Expiry + CVV entry
Navigator.push(context, MaterialPageRoute(
  builder: (_) => SessionScreen(
    cardData: widget.cardData.copyWith(
      expiryMonth: _monthController.text.trim(),
      expiryYear: _yearController.text.trim(),
      cvv: _cvvController.text.trim(),
    ),
    ...
  ),
));

// Screen 3 — Confirm and submit
final response = await PaymentKeyClient().encryptAndCreatePaymentKey(
  cardData: widget.cardData,
  publicKey: widget.publicKey,
  accessToken: widget.accessToken,
  providerBaseUrl: widget.providerBaseUrl,
);
```

### Pattern C — Card brand-aware UI

Show the correct card logo and adjust CVV length dynamically as the user types.

```dart
String _rawPan = '';

// In your onChanged callback:
setState(() => _rawPan = sanitizePan(value));

// In your build:
CardBrand brand = detectCardBrand(_rawPan);
int cvvLength = brand == CardBrand.amex ? 4 : 3;

Icon cardIcon = switch (brand) {
  CardBrand.visa       => Icon(Icons.credit_card),   // replace with Visa asset
  CardBrand.mastercard => Icon(Icons.credit_card),   // replace with MC asset
  CardBrand.amex       => Icon(Icons.credit_card),   // replace with Amex asset
  _                    => Icon(Icons.credit_card),
};
```

### Pattern D — Form validation wired to Flutter's Form widget

All validators return `null` (valid) or an error string (invalid), matching Flutter's `FormField.validator` signature exactly.

```dart
TextFormField(
  decoration: InputDecoration(labelText: 'Card number'),
  validator: (v) => validatePan(sanitizePan(v ?? '')),
),
TextFormField(
  decoration: InputDecoration(labelText: 'MM'),
  maxLength: 2,
  validator: (v) => validateExpiryMonth(v?.trim() ?? ''),
),
TextFormField(
  decoration: InputDecoration(labelText: 'YY'),
  maxLength: 2,
  validator: (v) => validateExpiryYear(v?.trim() ?? ''),
),
TextFormField(
  decoration: InputDecoration(labelText: 'CVV'),
  obscureText: true,
  validator: (v) => validateCvv(v?.trim() ?? ''),
),
```

### Pattern E — Injecting a test HTTP client

`PaymentKeyClient` accepts an optional `httpClient` parameter, which lets you inject a fake HTTP client in tests without any mocking framework.

```dart
// In tests:
class FakeHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode('{"PaymentType":"Card","PaymentKeys":["pk-123"],"Attributes":[]}')),
      200,
    );
  }
}

final client = PaymentKeyClient(httpClient: FakeHttpClient());
final response = await client.encryptAndCreatePaymentKey(...);
expect(response.paymentKey, 'pk-123');
```

---

## What stays in your app

This package is intentionally scoped to card encryption and payment key generation. The following concerns remain in your consuming app:

| Concern | Reason it stays in your app |
|---|---|
| **Calling `POST /payments/init`** | Requires your app's auth credentials and product-specific parameters |
| **Apple Pay (`RawApplePayButton`, `Pay` client)** | Depends on the `pay` Flutter package; not a library dependency |
| **Google Pay (`RawGooglePayButton`)** | Same as above |
| **Apple/Google Pay config JSON** | Merchant IDs, gateway merchant IDs, and network lists are product-specific |
| **UI / theming** | Colors, typography, and layout belong in your design system |
| **Session management** | `POST /payments/capture`, `POST /cards/save`, session expiry |
| **Error UX** | Retry logic, user-facing error messages, analytics |

---

## Public API reference

### Types

| Symbol | Kind | Description |
|---|---|---|
| `CardData` | `class` | Immutable card data model |
| `CardValidationResult` | `class` | Per-field validation outcome |
| `CardBrand` | `enum` | Card network (visa, mastercard, amex, discover, jcb, unknown) |
| `PaymentKeyClient` | `class` | HTTP client for the provider key endpoint |
| `PaymentKeyRequest` | `class` | Request DTO for `createPaymentKey` |
| `PaymentKeyResponse` | `class` | Response DTO with `paymentKey`, `paymentKeys`, `attributes` |
| `PaymentKeyAttribute` | `class` | Key/Value pair from the provider response |
| `PaymentKeyException` | `class` | Exception for HTTP and parse failures |

### Functions

| Symbol | Signature | Description |
|---|---|---|
| `sanitizePan` | `String sanitizePan(String raw)` | Strip spaces and dashes from a PAN |
| `maskPan` | `String maskPan(String pan)` | Display-safe masked PAN |
| `detectCardBrand` | `CardBrand detectCardBrand(String pan)` | BIN-prefix brand detection |
| `luhnCheck` | `bool luhnCheck(String pan)` | Raw Luhn algorithm |
| `validatePan` | `String? validatePan(String pan)` | PAN length + Luhn; null = valid |
| `validateExpiryMonth` | `String? validateExpiryMonth(String month)` | 01–12 check; null = valid |
| `validateExpiryYear` | `String? validateExpiryYear(String year)` | 2-digit check; null = valid |
| `validateCvv` | `String? validateCvv(String cvv)` | 3–4 digit check; null = valid |
| `validateCardData` | `CardValidationResult validateCardData(CardData data)` | Full-card validation |
| `buildCardString` | `String buildCardString({pan, expiryYear, expiryMonth, cvv})` | Format card string for provider |
| `encryptCardData` | `String encryptCardData({cardString, publicKeyPemOrBase64Der})` | RSA-OAEP SHA-1 encryption |

### `PaymentKeyClient` methods

| Method | Description |
|---|---|
| `encryptAndCreatePaymentKey({cardData, publicKey, accessToken, providerBaseUrl, ...})` | High-level: validate + encrypt + POST, returns `PaymentKeyResponse` |
| `createPaymentKey(PaymentKeyRequest)` | Low-level: POST pre-encrypted payload, returns `PaymentKeyResponse` |
