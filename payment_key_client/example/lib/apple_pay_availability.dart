import 'dart:io';

/// Result of checking Apple Pay availability per Apple HIG.
/// See: https://developer.apple.com/design/human-interface-guidelines/apple-pay/overview/introduction/
enum ApplePayButtonState {
  /// User has compatible cards in wallet: show "Buy with Apple Pay".
  buy,

  /// Device supports Apple Pay but user has no compatible cards: show "Set up Apple Pay".
  setUp,

  /// Apple Pay not available (e.g. Android).
  unavailable,
}

/// Determines which Apple Pay button to show per Apple HIG:
/// - [userHasCompatibleCards]: true when user's wallet has cards for merchant's supported networks
/// - Returns [ApplePayButtonState.buy] when user can pay
/// - Returns [ApplePayButtonState.setUp] when device supports Apple Pay but user has no cards
/// - Returns [ApplePayButtonState.unavailable] otherwise
///
/// On iOS, when user has no compatible cards, we default to [ApplePayButtonState.setUp] if the
/// method channel is unavailable (e.g. timing), since physical iPhones typically support Apple Pay.
Future<ApplePayButtonState> getApplePayButtonState({
  required bool userHasCompatibleCards,
}) async {
  if (userHasCompatibleCards) return ApplePayButtonState.buy;
  if (!Platform.isIOS) return ApplePayButtonState.unavailable;

  // Always show "Set up Apple Pay" on iOS when user has no compatible cards.
  // Physical iPhones typically support Apple Pay; user may need to add a card.
  return ApplePayButtonState.setUp;
}
