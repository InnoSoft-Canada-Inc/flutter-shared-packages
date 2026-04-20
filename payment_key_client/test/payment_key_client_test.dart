import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:payment_key_client/payment_key_client.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentKeyClient', () {
    late FakeHttpClient fakeClient;
    late PaymentKeyClient client;

    setUp(() {
      fakeClient = FakeHttpClient();
      client = PaymentKeyClient(httpClient: fakeClient);
    });

    test(
      'createPaymentKey sends POST to correct URL with Bearer and body',
      () async {
        fakeClient.nextResponse = http.Response(
          '{"PaymentType":"Card","PaymentKeys":["7237d7ff-d22b-4600-84f6-208cf5aef659"],"Attributes":[{"Key":"CardIssuer","Value":"Mastercard"}]}',
          200,
        );

        PaymentKeyResponse response = await client.createPaymentKey(
          PaymentKeyRequest(
            accessToken: 'token123',
            providerBaseUrl: 'https://hpc.uat.freedompay.com',
            encryptedCardData: 'encryptedPayload',
            paymentType: 1,
          ),
        );

        expect(response.paymentType, 'Card');
        expect(response.paymentKeys, ['7237d7ff-d22b-4600-84f6-208cf5aef659']);
        expect(response.paymentKey, '7237d7ff-d22b-4600-84f6-208cf5aef659');
        expect(response.attributes.length, 1);
        expect(response.attributes.first.key, 'CardIssuer');
        expect(response.attributes.first.value, 'Mastercard');
        expect(
          fakeClient.lastUri.toString(),
          'https://hpc.uat.freedompay.com/api/v2.1/payments/key',
        );
        expect(fakeClient.lastHeaders!['Authorization'], 'Bearer token123');
        expect(fakeClient.lastHeaders!['Content-Type'], 'application/json');
        Map<String, dynamic> body =
            jsonDecode(fakeClient.lastBody!) as Map<String, dynamic>;
        expect(body['cardData'], 'encryptedPayload');
        expect(body['paymentType'], 1);
      },
    );

    test(
      'createPaymentKey includes attributes in body when provided',
      () async {
        fakeClient.nextResponse = http.Response(
          '{"PaymentType":"Card","PaymentKeys":["pk-1"],"Attributes":[]}',
          200,
        );

        await client.createPaymentKey(
          PaymentKeyRequest(
            accessToken: 't',
            providerBaseUrl: 'https://example.com',
            encryptedCardData: 'enc',
            paymentType: 1,
            attributes: <String, String>{
              'CardIssuer': 'Mastercard',
              'MaskedCardNumber': '542418XXXXXX1765',
              'ExpirationDate': '06/34',
            },
          ),
        );

        Map<String, dynamic> body =
            jsonDecode(fakeClient.lastBody!) as Map<String, dynamic>;
        expect(body['attributes'], isA<Map>());
        expect((body['attributes'] as Map)['CardIssuer'], 'Mastercard');
        expect(
          (body['attributes'] as Map)['MaskedCardNumber'],
          '542418XXXXXX1765',
        );
        expect((body['attributes'] as Map)['ExpirationDate'], '06/34');
      },
    );

    test(
      'createPaymentKey builds URL without double slashes when baseUrl has trailing slash',
      () async {
        fakeClient.nextResponse = http.Response(
          '{"PaymentType":"Card","PaymentKeys":["pk"],"Attributes":[]}',
          200,
        );

        await client.createPaymentKey(
          PaymentKeyRequest(
            accessToken: 't',
            providerBaseUrl: 'https://example.com/',
            encryptedCardData: 'e',
            paymentType: 1,
          ),
        );

        expect(
          fakeClient.lastUri.toString(),
          'https://example.com/api/v2.1/payments/key',
        );
      },
    );

    test('createPaymentKey uses custom keyPath when provided', () async {
      fakeClient.nextResponse = http.Response(
        '{"PaymentType":"Card","PaymentKeys":["x"],"Attributes":[]}',
        200,
      );

      await client.createPaymentKey(
        PaymentKeyRequest(
          accessToken: 't',
          providerBaseUrl: 'https://fp.com',
          encryptedCardData: 'e',
          paymentType: 1,
          keyPath: '/api/v3/keys',
        ),
      );

      expect(fakeClient.lastUri.toString(), 'https://fp.com/api/v3/keys');
    });

    test('createPaymentKey throws PaymentKeyException on 400', () async {
      fakeClient.nextResponse = http.Response('Invalid request', 400);

      expect(
        () => client.createPaymentKey(
          PaymentKeyRequest(
            accessToken: 't',
            providerBaseUrl: 'https://example.com',
            encryptedCardData: 'e',
            paymentType: 1,
          ),
        ),
        throwsA(
          isA<PaymentKeyException>().having(
            (e) => e.statusCode,
            'statusCode',
            400,
          ),
        ),
      );
    });

    test('createPaymentKey throws PaymentKeyException on 502', () async {
      fakeClient.nextResponse = http.Response('Bad Gateway', 502);

      expect(
        () => client.createPaymentKey(
          PaymentKeyRequest(
            accessToken: 't',
            providerBaseUrl: 'https://example.com',
            encryptedCardData: 'e',
            paymentType: 1,
          ),
        ),
        throwsA(
          isA<PaymentKeyException>().having(
            (e) => e.statusCode,
            'statusCode',
            502,
          ),
        ),
      );
    });

    test(
      'createPaymentKey throws PaymentKeyException when response has no PaymentKeys',
      () async {
        fakeClient.nextResponse = http.Response(
          '{"PaymentType":"Card","PaymentKeys":[],"Attributes":[]}',
          200,
        );

        expect(
          () => client.createPaymentKey(
            PaymentKeyRequest(
              accessToken: 't',
              providerBaseUrl: 'https://example.com',
              encryptedCardData: 'e',
              paymentType: 1,
            ),
          ),
          throwsA(isA<PaymentKeyException>()),
        );
      },
    );

    test(
      'createPaymentKey throws PaymentKeyException when HTTP client throws',
      () async {
        fakeClient.shouldThrow = true;

        expect(
          () => client.createPaymentKey(
            PaymentKeyRequest(
              accessToken: 't',
              providerBaseUrl: 'https://example.com',
              encryptedCardData: 'e',
              paymentType: 1,
            ),
          ),
          throwsA(
            isA<PaymentKeyException>()
                .having((e) => e.statusCode, 'statusCode', -1)
                .having((e) => e.message, 'message', 'Request failed')
                .having((e) => e.cause, 'cause', isNotNull),
          ),
        );
      },
    );

    test(
      'createPaymentKey throws PaymentKeyException when response body is invalid JSON',
      () async {
        fakeClient.nextResponse = http.Response('not valid json {{{', 200);

        expect(
          () => client.createPaymentKey(
            PaymentKeyRequest(
              accessToken: 't',
              providerBaseUrl: 'https://example.com',
              encryptedCardData: 'e',
              paymentType: 1,
            ),
          ),
          throwsA(
            isA<PaymentKeyException>()
                .having((e) => e.statusCode, 'statusCode', 200)
                .having((e) => e.cause, 'cause', isNotNull),
          ),
        );
      },
    );

    test(
      'createPaymentKey throws PaymentKeyException with empty body on error',
      () async {
        fakeClient.nextResponse = http.Response('', 500);

        expect(
          () => client.createPaymentKey(
            PaymentKeyRequest(
              accessToken: 't',
              providerBaseUrl: 'https://example.com',
              encryptedCardData: 'e',
              paymentType: 1,
            ),
          ),
          throwsA(
            isA<PaymentKeyException>()
                .having((e) => e.statusCode, 'statusCode', 500)
                .having((e) => e.message, 'message', isNull),
          ),
        );
      },
    );

    test(
      'createPaymentKey omits attributes from body when not provided',
      () async {
        fakeClient.nextResponse = http.Response(
          '{"PaymentType":"Card","PaymentKeys":["pk"],"Attributes":[]}',
          200,
        );

        await client.createPaymentKey(
          PaymentKeyRequest(
            accessToken: 't',
            providerBaseUrl: 'https://example.com',
            encryptedCardData: 'e',
            paymentType: 1,
          ),
        );

        Map<String, dynamic> body =
            jsonDecode(fakeClient.lastBody!) as Map<String, dynamic>;
        expect(body.containsKey('attributes'), isFalse);
      },
    );

    test(
      'createPaymentKey omits attributes from body when empty map',
      () async {
        fakeClient.nextResponse = http.Response(
          '{"PaymentType":"Card","PaymentKeys":["pk"],"Attributes":[]}',
          200,
        );

        await client.createPaymentKey(
          PaymentKeyRequest(
            accessToken: 't',
            providerBaseUrl: 'https://example.com',
            encryptedCardData: 'e',
            paymentType: 1,
            attributes: <String, String>{},
          ),
        );

        Map<String, dynamic> body =
            jsonDecode(fakeClient.lastBody!) as Map<String, dynamic>;
        expect(body.containsKey('attributes'), isFalse);
      },
    );

    test(
      'createPaymentKey throws PaymentKeyException on status 199 (below 200)',
      () async {
        fakeClient.nextResponse = http.Response('Continue', 199);

        expect(
          () => client.createPaymentKey(
            PaymentKeyRequest(
              accessToken: 't',
              providerBaseUrl: 'https://example.com',
              encryptedCardData: 'e',
              paymentType: 1,
            ),
          ),
          throwsA(
            isA<PaymentKeyException>().having(
              (e) => e.statusCode,
              'statusCode',
              199,
            ),
          ),
        );
      },
    );

    test(
      'createPaymentKey throws PaymentKeyException on status 300 (redirect)',
      () async {
        fakeClient.nextResponse = http.Response('Redirect', 300);

        expect(
          () => client.createPaymentKey(
            PaymentKeyRequest(
              accessToken: 't',
              providerBaseUrl: 'https://example.com',
              encryptedCardData: 'e',
              paymentType: 1,
            ),
          ),
          throwsA(
            isA<PaymentKeyException>().having(
              (e) => e.statusCode,
              'statusCode',
              300,
            ),
          ),
        );
      },
    );

    test('createPaymentKey handles keyPath without leading slash', () async {
      fakeClient.nextResponse = http.Response(
        '{"PaymentType":"Card","PaymentKeys":["pk"],"Attributes":[]}',
        200,
      );

      await client.createPaymentKey(
        PaymentKeyRequest(
          accessToken: 't',
          providerBaseUrl: 'https://fp.com',
          encryptedCardData: 'e',
          paymentType: 1,
          keyPath: 'api/v3/keys',
        ),
      );

      expect(fakeClient.lastUri.toString(), 'https://fp.com/api/v3/keys');
    });
  });

  group('encryptAndCreatePaymentKey', () {
    /// RSA public key (base64 DER SPKI) shared with card_encryption_test.
    const String testPublicKeyBase64 =
        'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxFy4/3Qnt50uQzxOWwaY'
        'Hbeue2O+Zr+Z4M7433IhnH6hHPgCGSlRc9ll3oqSI4GD35fTA7LUFUMkLICMb'
        'PYqtmagLkFwawIZGp3p/ac0okkxOTl1KGvd9WeQh+w/rtS7Lpd/m2K1dPmPsTf'
        'uHmfchi9d8/hhiJCaspQOLCQe/yMlbpFJ6m+po+/aARNih24TB7Ru+NDpb9ymZ'
        '9L9rtG/Jq4+e9vNDkDaOsEgntM1x0RMQuf9axn3U61DgwEhogELhOWRBqTDpE'
        'KBVjBi28H26u0pw6WonyvQC7T6SCJqrNZaq1qFD93x7ll8kxvWcZWG7Wz15w+'
        'i5FLM3RydGk3NHQIDAQAB';

    const CardData validCard = CardData(
      pan: '5424180279791765',
      expiryMonth: '06',
      expiryYear: '34',
      cvv: '123',
    );

    late FakeHttpClient fakeClient;
    late PaymentKeyClient client;

    setUp(() {
      fakeClient = FakeHttpClient();
      client = PaymentKeyClient(httpClient: fakeClient);
    });

    test('encrypts card and calls key endpoint, returns response', () async {
      fakeClient.nextResponse = http.Response(
        '{"PaymentType":"Card","PaymentKeys":["abc-123"],"Attributes":[]}',
        200,
      );

      PaymentKeyResponse response = await client.encryptAndCreatePaymentKey(
        cardData: validCard,
        publicKey: testPublicKeyBase64,
        accessToken: 'token-xyz',
        providerBaseUrl: 'https://hpc.uat.freedompay.com',
      );

      expect(response.paymentKey, 'abc-123');
      expect(fakeClient.lastHeaders!['Authorization'], 'Bearer token-xyz');

      Map<String, dynamic> body =
          jsonDecode(fakeClient.lastBody!) as Map<String, dynamic>;
      // The encrypted card data is a non-empty base64 string.
      expect(body['cardData'], isA<String>());
      expect((body['cardData'] as String).isNotEmpty, isTrue);
      expect(body['paymentType'], 1);
    });

    test('uses custom paymentType when provided', () async {
      fakeClient.nextResponse = http.Response(
        '{"PaymentType":"Wallet","PaymentKeys":["pk-wallet"],"Attributes":[]}',
        200,
      );

      await client.encryptAndCreatePaymentKey(
        cardData: validCard,
        publicKey: testPublicKeyBase64,
        accessToken: 't',
        providerBaseUrl: 'https://hpc.uat.freedompay.com',
        paymentType: 5,
      );

      Map<String, dynamic> body =
          jsonDecode(fakeClient.lastBody!) as Map<String, dynamic>;
      expect(body['paymentType'], 5);
    });

    test('uses custom keyPath when provided', () async {
      fakeClient.nextResponse = http.Response(
        '{"PaymentType":"Card","PaymentKeys":["pk-2"],"Attributes":[]}',
        200,
      );

      await client.encryptAndCreatePaymentKey(
        cardData: validCard,
        publicKey: testPublicKeyBase64,
        accessToken: 't',
        providerBaseUrl: 'https://fp.example.com',
        keyPath: '/api/v3/keys',
      );

      expect(
        fakeClient.lastUri.toString(),
        'https://fp.example.com/api/v3/keys',
      );
    });

    test('includes attributes when provided', () async {
      fakeClient.nextResponse = http.Response(
        '{"PaymentType":"Card","PaymentKeys":["pk-attr"],"Attributes":[]}',
        200,
      );

      await client.encryptAndCreatePaymentKey(
        cardData: validCard,
        publicKey: testPublicKeyBase64,
        accessToken: 't',
        providerBaseUrl: 'https://hpc.uat.freedompay.com',
        attributes: <String, String>{'CardIssuer': 'Mastercard'},
      );

      Map<String, dynamic> body =
          jsonDecode(fakeClient.lastBody!) as Map<String, dynamic>;
      expect((body['attributes'] as Map)['CardIssuer'], 'Mastercard');
    });

    test('throws ArgumentError for invalid card PAN', () async {
      expect(
        () => client.encryptAndCreatePaymentKey(
          cardData: const CardData(
            pan: '1234',
            expiryMonth: '06',
            expiryYear: '34',
            cvv: '123',
          ),
          publicKey: testPublicKeyBase64,
          accessToken: 't',
          providerBaseUrl: 'https://hpc.uat.freedompay.com',
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for invalid expiry month', () async {
      expect(
        () => client.encryptAndCreatePaymentKey(
          cardData: const CardData(
            pan: '5424180279791765',
            expiryMonth: '13',
            expiryYear: '34',
            cvv: '123',
          ),
          publicKey: testPublicKeyBase64,
          accessToken: 't',
          providerBaseUrl: 'https://hpc.uat.freedompay.com',
        ),
        throwsArgumentError,
      );
    });

    test('throws PaymentKeyException when provider returns 401', () async {
      fakeClient.nextResponse = http.Response('Unauthorized', 401);

      expect(
        () => client.encryptAndCreatePaymentKey(
          cardData: validCard,
          publicKey: testPublicKeyBase64,
          accessToken: 'bad-token',
          providerBaseUrl: 'https://hpc.uat.freedompay.com',
        ),
        throwsA(
          isA<PaymentKeyException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });

    test('throws ArgumentError for invalid expiry year', () async {
      expect(
        () => client.encryptAndCreatePaymentKey(
          cardData: const CardData(
            pan: '5424180279791765',
            expiryMonth: '06',
            expiryYear: '3',
            cvv: '123',
          ),
          publicKey: testPublicKeyBase64,
          accessToken: 't',
          providerBaseUrl: 'https://hpc.uat.freedompay.com',
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for invalid CVV', () async {
      expect(
        () => client.encryptAndCreatePaymentKey(
          cardData: const CardData(
            pan: '5424180279791765',
            expiryMonth: '06',
            expiryYear: '34',
            cvv: '12',
          ),
          publicKey: testPublicKeyBase64,
          accessToken: 't',
          providerBaseUrl: 'https://hpc.uat.freedompay.com',
        ),
        throwsArgumentError,
      );
    });

    test(
      'throws ArgumentError with message containing all invalid fields',
      () async {
        expect(
          () => client.encryptAndCreatePaymentKey(
            cardData: const CardData(
              pan: '',
              expiryMonth: '13',
              expiryYear: '',
              cvv: '',
            ),
            publicKey: testPublicKeyBase64,
            accessToken: 't',
            providerBaseUrl: 'https://hpc.uat.freedompay.com',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message as String,
              'message',
              allOf(
                contains('PAN:'),
                contains('Month:'),
                contains('Year:'),
                contains('CVV:'),
              ),
            ),
          ),
        );
      },
    );

    test('does not call HTTP client when validation fails', () async {
      try {
        await client.encryptAndCreatePaymentKey(
          cardData: const CardData(
            pan: '1234',
            expiryMonth: '06',
            expiryYear: '34',
            cvv: '123',
          ),
          publicKey: testPublicKeyBase64,
          accessToken: 't',
          providerBaseUrl: 'https://hpc.uat.freedompay.com',
        );
      } catch (_) {}
      // HTTP client should never have been called
      expect(fakeClient.lastUri, isNull);
    });

    test(
      'validateCvvOnly runs only CVV check; invalid PAN still encrypts and POSTs',
      () async {
        fakeClient.nextResponse = http.Response(
          '{"PaymentType":"Card","PaymentKeys":["pk-cvv-only"],"Attributes":[]}',
          200,
        );

        PaymentKeyResponse response = await client.encryptAndCreatePaymentKey(
          cardData: const CardData(
            pan: '1234',
            expiryMonth: '99',
            expiryYear: 'x',
            cvv: '123',
          ),
          publicKey: testPublicKeyBase64,
          accessToken: 't',
          providerBaseUrl: 'https://hpc.uat.freedompay.com',
          validateCvvOnly: true,
        );

        expect(response.paymentKey, 'pk-cvv-only');
        expect(fakeClient.lastUri, isNotNull);
        Map<String, dynamic> body =
            jsonDecode(fakeClient.lastBody!) as Map<String, dynamic>;
        expect((body['cardData'] as String).isNotEmpty, isTrue);
      },
    );

    test('validateCvvOnly throws ArgumentError for invalid CVV', () async {
      expect(
        () => client.encryptAndCreatePaymentKey(
          cardData: const CardData(
            pan: '1234',
            expiryMonth: '06',
            expiryYear: '34',
            cvv: '12',
          ),
          publicKey: testPublicKeyBase64,
          accessToken: 't',
          providerBaseUrl: 'https://hpc.uat.freedompay.com',
          validateCvvOnly: true,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message as String,
            'message',
            contains('CVV:'),
          ),
        ),
      );
    });

    test(
      'encryptedCardData skips validation and posts ciphertext unchanged',
      () async {
        fakeClient.nextResponse = http.Response(
          '{"PaymentType":"Card","PaymentKeys":["pk-pre-enc"],"Attributes":[]}',
          200,
        );

        PaymentKeyResponse response = await client.encryptAndCreatePaymentKey(
          publicKey: testPublicKeyBase64,
          accessToken: 't',
          providerBaseUrl: 'https://hpc.uat.freedompay.com',
          encryptedCardData: '  prebuiltCipher==  ',
        );

        expect(response.paymentKey, 'pk-pre-enc');
        Map<String, dynamic> body =
            jsonDecode(fakeClient.lastBody!) as Map<String, dynamic>;
        expect(body['cardData'], 'prebuiltCipher==');
      },
    );

    test(
      'throws when neither cardData nor encryptedCardData is provided',
      () async {
        expect(
          () => client.encryptAndCreatePaymentKey(
            publicKey: testPublicKeyBase64,
            accessToken: 't',
            providerBaseUrl: 'https://hpc.uat.freedompay.com',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => (e.message as String).toString(),
              'message',
              contains('cardData is required'),
            ),
          ),
        );
      },
    );
  });
}

/// Fake [http.Client] that records the last request and returns [nextResponse].
class FakeHttpClient extends http.BaseClient {
  http.Response? nextResponse;
  bool shouldThrow = false;
  Uri? lastUri;
  Map<String, String>? lastHeaders;
  String? lastBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    lastHeaders = request.headers;
    if (request is http.Request) {
      lastBody = request.body;
    }
    if (shouldThrow) {
      throw Exception('Simulated network error');
    }
    if (nextResponse == null) {
      return http.StreamedResponse(const Stream.empty(), 500);
    }
    return http.StreamedResponse(
      Stream.value(nextResponse!.bodyBytes),
      nextResponse!.statusCode,
    );
  }
}
