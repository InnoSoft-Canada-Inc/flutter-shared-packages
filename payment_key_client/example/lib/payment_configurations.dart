/// Payment configurations for the pay package.
///
/// Apple Pay: Merchant identifier must match Runner.entitlements and Apple Developer Portal.
/// Google Pay: Use TEST environment for development; configure gateway for production.
library;

import 'package:pay/pay.dart';

/// Apple Pay configuration for Payment Key Sample app.
final PaymentConfiguration defaultApplePayConfig =
    PaymentConfiguration.fromJsonString(defaultApplePay);

/// JSON configuration for Apple Pay.
/// Required: currencyCode, countryCode, supportedNetworks, merchantIdentifier.
const String defaultApplePay = '''{
  "provider": "apple_pay",
  "data": {
    "merchantIdentifier": "merchant.com.fusionfamily.play",
    "displayName": "FreedomPay Test Store",
    "merchantCapabilities": ["3DS", "debit", "credit"],
    "supportedNetworks": ["visa", "masterCard", "amex", "discover"],
    "countryCode": "US",
    "currencyCode": "USD",
    "requiredBillingContactFields": ["postalAddress"],
    "requiredShippingContactFields": []
  }
}''';

/// Google Pay configuration for Payment Key Sample app.
final PaymentConfiguration defaultGooglePayConfig =
    PaymentConfiguration.fromJsonString(defaultGooglePay);

/// JSON configuration for Google Pay (FreedomPay).
///
/// FreedomPay requirements:
/// - type: "CARD"
/// - allowedAuthMethods: "PAN_ONLY" and "CRYPTOGRAM_3DS" (both recommended)
/// - allowedCardNetworks: AMEX, DISCOVER, JCB, MASTERCARD, VISA (specify brands to accept)
/// - tokenizationSpecification.type: "PAYMENT_GATEWAY"
/// - tokenizationSpecification.parameters.gateway: "freedompay"
/// - tokenizationSpecification.parameters.gatewayMerchantId: value from FreedomPay
///
/// The Google Pay response "token" is passed to FreedomPay in pos.trackData or cardData
/// depending on integration type. Billing info goes to BillTo fields.
const String defaultGooglePay = '''{
  "provider": "google_pay",
  "data": {
    "environment": "TEST",
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "freedompay",
            "gatewayMerchantId": "vZUUhEklJq4LnTQoA2tzJz1xVrs="
          }
        },
        "parameters": {
          "allowedCardNetworks": ["AMEX", "DISCOVER", "JCB", "MASTERCARD", "VISA"],
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "billingAddressRequired": true,
          "billingAddressParameters": {
            "format": "FULL",
            "phoneNumberRequired": true
          }
        }
      }
    ],
    "merchantInfo": {
      "merchantName": "FreedomPay Test Store"
    },
    "transactionInfo": {
      "countryCode": "US",
      "currencyCode": "USD"
    }
  }
}''';
