import 'package:flutter_test/flutter_test.dart';
import 'package:soundify/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('fromJson parses valid JSON and nullable fields correctly', () {
      // Arrange
      final json = {
        'id': 1,
        'username': 'student01',
        'email': 'student@example.com',
        'display_name': null,
        'avatar_url': 'https://example.com/avatar.png',
      };

      // Act
      final user = UserModel.fromJson(json);

      // Assert
      expect(user.id, equals(1));
      expect(user.username, equals('student01'));
      expect(user.email, equals('student@example.com'));
      expect(user.displayName, isNull);
      expect(user.avatarUrl, equals('https://example.com/avatar.png'));
      expect(user.isVerified, isTrue);
    });

    test('copyWith updates only provided fields and preserves others', () {
      // Arrange
      final user = UserModel(
        id: 1,
        username: 'student01',
        email: 'student@example.com',
        displayName: 'Old Name',
      );

      // Act
      final updated = user.copyWith(displayName: 'New Name');

      // Assert
      expect(updated.displayName, equals('New Name'));
      expect(updated.username, equals('student01'));
      expect(updated.email, equals('student@example.com'));
    });
  });
}
