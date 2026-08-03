import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

String _generateSalt() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

String hashPassword(String password, {String? salt}) {
  final s = salt ?? _generateSalt();
  final digest = sha256.convert(utf8.encode('$s::$password'));
  return '$s\$$digest';
}

bool verifyPassword(String password, String stored) {
  final parts = stored.split('\$');
  if (parts.length != 2) return false;
  return hashPassword(password, salt: parts[0]) == stored;
}
