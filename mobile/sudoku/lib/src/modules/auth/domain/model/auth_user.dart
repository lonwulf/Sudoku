import 'dart:convert';

import 'package:equatable/equatable.dart';

/// The signed-in player, as named by their ID token.
class AuthUser extends Equatable {
  final String id;
  final String name;

  const AuthUser({required this.id, required this.name});

  /// Reads the claims without verifying the signature: the token came
  /// straight from the issuer, and the backend verifies what it is sent.
  factory AuthUser.fromIdToken(String idToken) {
    final payload = idToken.split('.')[1];
    final claims =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(payload))))
            as Map<String, dynamic>;
    return AuthUser(
      id: claims['sub'] as String? ?? '',
      name:
          (claims['name'] ?? claims['preferred_username'] ?? claims['email'])
              as String? ??
          'Player',
    );
  }

  @override
  List<Object?> get props => [id, name];
}
