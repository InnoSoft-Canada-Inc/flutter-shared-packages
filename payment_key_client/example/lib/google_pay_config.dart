// ============================================================
// GOOGLE PAY — TEST CONFIGURATION
// ============================================================
// Use during development and FreedomPay UAT certification.
// Returns non-chargeable dummy tokens — no real money moves.
// No Google Pay Merchant ID required in TEST.
// ============================================================

const String googlePayConfigTest = '''{
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
            "gatewayMerchantId": "lDrtiA4YnD/QvktYDOlnOggN8eY="
          }
        },
        "parameters": {
          "allowedCardNetworks": ["AMEX", "DISCOVER", "MASTERCARD", "VISA"],
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "billingAddressRequired": true,
          "billingAddressParameters": {
            "format": "FULL",
            "phoneNumberRequired": false
          }
        }
      }
    ],
    "merchantInfo": {
      "merchantName": "FusionPlay"
    },
    "transactionInfo": {
      "countryCode": "US",
      "currencyCode": "USD"
    }
  }
}''';

// ============================================================
// GOOGLE PAY — PRODUCTION CONFIGURATION
// ============================================================
// Use after completing Google's integration checklist and
// receiving production approval from the Wallet Console.
// Returns real chargeable tokens — real money moves.
// ============================================================

const String googlePayConfigProduction = '''{
  "provider": "google_pay",
  "data": {
    "environment": "PRODUCTION",
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "freedompay",
            "gatewayMerchantId": "lDrtiA4YnD/QvktYDOlnOggN8eY="
          }
        },
        "parameters": {
          "allowedCardNetworks": ["AMEX", "DISCOVER", "MASTERCARD", "VISA"],
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "billingAddressRequired": true,
          "billingAddressParameters": {
            "format": "FULL",
            "phoneNumberRequired": false
          }
        }
      }
    ],
    "merchantInfo": {
      "merchantId": "BCR2DN4Txxxxxxx",
      "merchantName": "FusionPlay"
    },
    "transactionInfo": {
      "countryCode": "US",
      "currencyCode": "USD"
    }
  }
}''';

// ============================================================
// MULTI-TENANT: DYNAMIC CONFIG BUILDER
// ============================================================
// For your multi-tenant setup, build the config at runtime
// using the organization's FreedomPay credentials from
// payment_config. This is what the Flutter app would use
// after receiving org-specific data from POST /payments/init.
// ============================================================

String buildGooglePayConfig({
  required String environment, // "TEST" or "PRODUCTION"
  required String gatewayMerchantId, // org-specific FreedomPay StoreId
  required String merchantName, // display name on payment sheet
  String? googleMerchantId, // required for PRODUCTION only
  String countryCode = "US",
  String currencyCode = "USD",
}) {
  final merchantIdField = googleMerchantId != null
      ? '"merchantId": "$googleMerchantId",'
      : '';

  return '''{
  "provider": "google_pay",
  "data": {
    "environment": "$environment",
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "freedompay",
            "gatewayMerchantId": "$gatewayMerchantId"
          }
        },
        "parameters": {
          "allowedCardNetworks": ["AMEX", "DISCOVER", "MASTERCARD", "VISA"],
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "billingAddressRequired": true,
          "billingAddressParameters": {
            "format": "FULL",
            "phoneNumberRequired": false
          }
        }
      }
    ],
    "merchantInfo": {
      $merchantIdField
      "merchantName": "$merchantName"
    },
    "transactionInfo": {
      "countryCode": "$countryCode",
      "currencyCode": "$currencyCode"
    }
  }
}''';
}
