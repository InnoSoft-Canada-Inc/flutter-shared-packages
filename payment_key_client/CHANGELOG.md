## 0.1.0

### New features

- **`CardData`** — immutable model for card fields (`pan`, `expiryMonth`, `expiryYear`, `cvv`) with `copyWith`, `==`, `hashCode`, and a redacting `toString`.
- **`CardValidationResult`** and validators — `luhnCheck`, `validatePan` (13–19 digits + Luhn), `validateExpiryMonth` (01–12), `validateExpiryYear` (2-digit), `validateCvv` (3–4 digits), and `validateCardData` for full-card validation with per-field error messages.
- **`CardBrand`** enum and `detectCardBrand` — BIN-prefix detection for Visa, Mastercard (including 2-series), Amex, Discover, and JCB.
- **`sanitizePan`** — strips spaces and dashes from user-entered PAN strings.
- **`maskPan`** — returns a display-safe masked PAN (`"5424 **** **** 1765"`).
- **`PaymentKeyClient.encryptAndCreatePaymentKey`** — high-level method that validates `CardData`, builds the provider card string, RSA-OAEP encrypts it, and posts to the key endpoint in a single call.

### Breaking changes

None (initial public release).
