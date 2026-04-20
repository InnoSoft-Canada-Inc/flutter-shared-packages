import 'dart:convert';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/export.dart';

/// Builds the card string in the format expected by the payment provider.
///
/// Format: `M<PAN>=<YY><MM>:<CVV>` (e.g. `M5424180279791765=3406:123`).
/// Matches the format used in [card_encrypt.js](https://github.com/innosoft/payments/blob/master/card_encrypt.js).
///
/// [pan]: Primary account number (card number), digits only, no spaces.
/// [expiryYear]: Two-digit expiry year (e.g. `34` for 2034).
/// [expiryMonth]: Two-digit expiry month (e.g. `06`).
/// [cvv]: Card verification value (e.g. `123` or `1234` for Amex).
String buildCardString({
  required String pan,
  required String expiryYear,
  required String expiryMonth,
  required String cvv,
}) {
  return 'M$pan=$expiryYear$expiryMonth:$cvv';
}

/// Encrypts [cardString] with the provider's RSA public key using RSA-OAEP with SHA-1.
///
/// Matches Node.js `crypto.publicEncrypt({ padding: RSA_PKCS1_OAEP_PADDING, oaepHash: 'sha1' }, buffer)`.
///
/// [cardString]: Output of [buildCardString] (must not contain raw card data from untrusted input without validation).
/// [publicKeyPemOrBase64Der]: Public key from init response — either PEM (`-----BEGIN PUBLIC KEY-----...`)
///   or base64-encoded DER (SPKI). If DER, it is wrapped in PEM headers for parsing.
///
/// Returns base64-encoded ciphertext suitable for [PaymentKeyRequest.encryptedCardData].
///
/// Throws [FormatException] if the key cannot be parsed or encryption fails.
String encryptCardData({
  required String cardString,
  required String publicKeyPemOrBase64Der,
}) {
  String pem = publicKeyPemOrBase64Der.trim();
  if (!pem.contains('-----BEGIN')) {
    pem = _derToPem(publicKeyPemOrBase64Der);
  }
  RSAPublicKey publicKey = _parsePublicKey(pem);
  Uint8List plaintext = Uint8List.fromList(utf8.encode(cardString));
  Uint8List ciphertext = _encryptRsaOaepSha1(publicKey, plaintext);
  return base64Encode(ciphertext);
}

/// Wraps base64-encoded DER (SPKI) in PEM headers (64-char line wrap).
String _derToPem(String base64Der) {
  String content = base64Der.replaceAll(RegExp(r'\s'), '');
  StringBuffer lines = StringBuffer();
  for (int i = 0; i < content.length; i += 64) {
    int end = (i + 64 < content.length) ? i + 64 : content.length;
    lines.writeln(content.substring(i, end));
  }
  return '-----BEGIN PUBLIC KEY-----\n${lines.toString()}-----END PUBLIC KEY-----';
}

/// Extracts base64 key bytes from PEM (content between BEGIN and END).
Uint8List _pemToDer(String pem) {
  RegExp base64 = RegExp(
    r'-----BEGIN PUBLIC KEY-----\s*([\s\S]*?)\s*-----END PUBLIC KEY-----',
  );
  Match? m = base64.firstMatch(pem);
  if (m == null) {
    // Assume whole string is base64 DER
    return Uint8List.fromList(base64Decode(pem.replaceAll(RegExp(r'\s'), '')));
  }
  return Uint8List.fromList(
    base64Decode(m.group(1)!.replaceAll(RegExp(r'\s'), '')),
  );
}

/// Parses PEM or raw base64 DER (SPKI) into [RSAPublicKey].
RSAPublicKey _parsePublicKey(String pem) {
  Uint8List der = pem.contains('-----BEGIN')
      ? _pemToDer(pem)
      : Uint8List.fromList(base64Decode(pem.replaceAll(RegExp(r'\s'), '')));
  return _parseSpkiDer(der);
}

/// Parses SPKI DER (SEQUENCE { AlgorithmIdentifier, BIT STRING }) to get RSA n, e.
RSAPublicKey _parseSpkiDer(Uint8List der) {
  ASN1Parser parser = ASN1Parser(der);
  ASN1Sequence top = parser.nextObject() as ASN1Sequence;
  if (top.elements.length < 2) {
    throw FormatException('Invalid SPKI: expected SEQUENCE with 2 elements');
  }
  // elements[1] is subjectPublicKey (BIT STRING)
  ASN1BitString bitString = top.elements[1] as ASN1BitString;
  Uint8List keyBytes = bitString.contentBytes();
  // BIT STRING value: first byte is unused bits, rest is RSA public key SEQUENCE
  int offset = (keyBytes.isNotEmpty && keyBytes[0] == 0) ? 1 : 0;
  ASN1Parser keyParser = ASN1Parser(keyBytes.sublist(offset));
  ASN1Sequence keySeq = keyParser.nextObject() as ASN1Sequence;
  if (keySeq.elements.length < 2) {
    throw FormatException('Invalid RSA public key SEQUENCE');
  }
  BigInt modulus = (keySeq.elements[0] as ASN1Integer).valueAsBigInteger;
  BigInt exponent = (keySeq.elements[1] as ASN1Integer).valueAsBigInteger;
  return RSAPublicKey(modulus, exponent);
}

/// RSA-OAEP with SHA-1 (same as Node.js oaepHash: 'sha1').
Uint8List _encryptRsaOaepSha1(RSAPublicKey publicKey, Uint8List input) {
  AsymmetricBlockCipher cipher = OAEPEncoding.withSHA1(RSAEngine());
  cipher.init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

  int blockSize = cipher.inputBlockSize;
  int numBlocks = (input.length / blockSize).ceil();
  Uint8List output = Uint8List(numBlocks * cipher.outputBlockSize);
  int inputOffset = 0;
  int outputOffset = 0;

  while (inputOffset < input.length) {
    int chunkSize = (inputOffset + blockSize <= input.length)
        ? blockSize
        : input.length - inputOffset;
    outputOffset += cipher.processBlock(
      input,
      inputOffset,
      chunkSize,
      output,
      outputOffset,
    );
    inputOffset += chunkSize;
  }

  return outputOffset == output.length
      ? output
      : output.sublist(0, outputOffset);
}
