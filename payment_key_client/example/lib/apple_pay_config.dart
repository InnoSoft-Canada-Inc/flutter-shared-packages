// ============================================================
// APPLE PAY — TEST CONFIGURATION
// ============================================================
// Use during development with FreedomPay UAT environment.
// Requires sandbox tester account + test cards in Apple Wallet.
// Must be tested on a physical iOS device (not simulator).
// ============================================================

const String applePayConfigTest = '''{
  "provider": "apple_pay",
  "data": {
    "merchantIdentifier": "merchant.com.fusionfamily.play",
    "displayName": "FusionPlay",
    "merchantCapabilities": ["3DS", "debit", "credit"],
    "supportedNetworks": ["visa", "masterCard", "amex", "discover"],
    "countryCode": "US",
    "currencyCode": "USD",
    "requiredBillingContactFields": ["postalAddress"],
    "requiredShippingContactFields": []
  }
}''';

// ============================================================
// APPLE PAY — PRODUCTION CONFIGURATION
// ============================================================
// Use after:
//   1. Production Payment Processing Certificate is created
//      (CSR from FreedomPay → uploaded to Apple → .cer back to FP)
//   2. Store boarded for Apple Pay in Freeway™
//   3. ISV certification completed with FreedomPay SI
//
// merchantIdentifier must exactly match:
//   - Apple Developer Portal → Identifiers → Merchant IDs
//   - Xcode entitlement: com.apple.developer.in-app-payments
//   - The Merchant ID tied to FreedomPay's Payment Processing Cert
// ============================================================

const String applePayConfigProduction = '''{
  "provider": "apple_pay",
  "data": {
    "merchantIdentifier": "merchant.com.fusionfamily.play",
    "displayName": "FusionPlay",
    "merchantCapabilities": ["3DS", "debit", "credit"],
    "supportedNetworks": ["visa", "masterCard", "amex", "discover"],
    "countryCode": "US",
    "currencyCode": "USD",
    "requiredBillingContactFields": ["postalAddress"],
    "requiredShippingContactFields": []
  }
}''';

// ============================================================
// MULTI-TENANT: DYNAMIC CONFIG BUILDER
// ============================================================
// If using Approach B (single shared Merchant ID), the
// merchantIdentifier is the same for all orgs and this builder
// is mainly useful for switching display name or country/currency.
//
// If using Approach A (per-org Merchant IDs), each org's
// merchantIdentifier comes from payment_config and must also
// exist in the app's entitlement array (requires app update).
// ============================================================

String buildApplePayConfig({
  required String merchantIdentifier, // from payment_config or shared
  required String displayName, // brand name on payment sheet
  String countryCode = "US",
  String currencyCode = "USD",
}) {
  return '''{
  "provider": "apple_pay",
  "data": {
    "merchantIdentifier": "$merchantIdentifier",
    "displayName": "$displayName",
    "merchantCapabilities": ["3DS", "debit", "credit"],
    "supportedNetworks": ["visa", "masterCard", "amex", "discover"],
    "countryCode": "$countryCode",
    "currencyCode": "$currencyCode",
    "requiredBillingContactFields": ["postalAddress"],
    "requiredShippingContactFields": []
  }
}''';
}
