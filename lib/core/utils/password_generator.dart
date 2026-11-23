import 'dart:math';

/// Generates a random temporary password for new staff accounts.
///
/// Replaces the old predictable `<name>@mnj123` pattern, which let anyone
/// guess a colleague's password from their name. Ambiguous characters
/// (0/O, 1/l/I) are excluded so it can be read out or typed easily.
String generateTemporaryPassword({int length = 10}) {
  const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rng = Random.secure();
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}
