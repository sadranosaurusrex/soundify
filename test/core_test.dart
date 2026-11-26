import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundify/core/constants/api_endpoints.dart';
import 'package:soundify/core/constants/app_colors.dart';
import 'package:soundify/core/theme/app_theme.dart';

void main() {
  group('ApiEndpoints Tests', () {
    test('trackStream builds the full stream URL with track ID', () {
      // Arrange
      const trackId = 'T-123';

      // Act
      final url = ApiEndpoints.trackStream(trackId);

      // Assert
      expect(
        url,
        equals('https://soundify.easyfound.ir/api/v1/tracks/T-123/stream'),
      );
    });
  });

  group('AppTheme Tests', () {
    test('darkTheme has dark brightness and dark background', () {
      // Act
      final theme = AppTheme.darkTheme;

      // Assert
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.darkBackground));
      expect(theme.colorScheme.primary, equals(AppColors.primary));
    });

    test('lightTheme has light brightness and light background', () {
      // Act
      final theme = AppTheme.lightTheme;

      // Assert
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.lightBackground));
      expect(theme.colorScheme.primary, equals(AppColors.primary));
    });
  });
}
