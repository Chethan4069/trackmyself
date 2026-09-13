import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  const PasswordHasher._();

  static const _salt = 'trackmyself_salt_secure_2026';

  /// Hash password with SHA-256 and salt
  static String hash(String password) {
    final bytes = utf8.encode('$password$_salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify entered password matches stored hash
  static bool verify(String password, String storedHash) {
    return hash(password) == storedHash;
  }
}
