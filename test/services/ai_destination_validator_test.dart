import 'package:flutter_test/flutter_test.dart';
import 'package:smart_travel_app/models/ai/ai_activity_suggestion.dart';
import 'package:smart_travel_app/services/ai/ai_destination_validator.dart';

void main() {
  group('AIDestinationValidator', () {
    group('validateCoordinates', () {
      test('should pass for valid Vietnam coordinates', () {
        final result = AIDestinationValidator.validateCoordinates(21.028511, 105.852029); // Hồ Hoàn Kiếm
        expect(result.isValid, true);
        expect(result.errors, isEmpty);
      });

      test('should fail for coordinates outside Vietnam', () {
        final result = AIDestinationValidator.validateCoordinates(40.7128, -74.0060); // New York
        expect(result.isValid, false);
        expect(result.errors, isNotEmpty);
        expect(result.errors.first, contains('nằm ngoài phạm vi Việt Nam'));
      });

      test('should fail for null coordinates', () {
        final result = AIDestinationValidator.validateCoordinates(null, null);
        expect(result.isValid, false);
        expect(result.errors.first, contains('Thiếu tọa độ'));
      });
    });

    group('validateName', () {
      test('should pass for valid restaurant name', () {
        final result = AIDestinationValidator.validateName('Bánh mì Phượng Hội An');
        expect(result.isValid, true);
        expect(result.errors, isEmpty);
      });

      test('should fail for too short name', () {
        final result = AIDestinationValidator.validateName('Abc');
        expect(result.isValid, false);
        expect(result.errors.first, contains('quá ngắn'));
      });

      test('should fail for banned words', () {
        final result = AIDestinationValidator.validateName('Unknown Restaurant');
        expect(result.isValid, false);
        expect(result.errors.first, contains('từ không được phép'));
      });

      test('should fail for generic names', () {
        final result = AIDestinationValidator.validateName('Restaurant 123');
        expect(result.isValid, false);
        expect(result.errors.first, contains('không được phép')); // Banned word "restaurant"
      });
    });

    group('validateDescription', () {
      test('should pass for valid Vietnamese description', () {
        final result = AIDestinationValidator.validateDescription(
          'Bánh mì Phượng là tiệm bánh mì trứ danh được đầu bếp Anthony Bourdain khen ngợi, nổi tiếng với pate béo ngậy và các loại nhân đa dạng.'
        );
        expect(result.isValid, true);
        expect(result.errors, isEmpty);
      });

      test('should fail for too short description', () {
        final result = AIDestinationValidator.validateDescription('Short desc');
        expect(result.isValid, false);
        expect(result.errors.first, contains('quá ngắn'));
      });

      test('should fail for placeholder text', () {
        final result = AIDestinationValidator.validateDescription(
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
        );
        expect(result.isValid, false);
        expect(result.errors.first, contains('placeholder text'));
      });
    });

    group('validateCategory', () {
      test('should pass for valid categories', () {
        final validCategories = ['restaurant', 'cafe', 'attraction', 'shopping'];
        for (final category in validCategories) {
          final result = AIDestinationValidator.validateCategory(category);
          expect(result.isValid, true, reason: 'Category $category should be valid');
        }
      });

      test('should fail for invalid category', () {
        final result = AIDestinationValidator.validateCategory('invalid_category');
        expect(result.isValid, false);
        expect(result.errors.first, contains('không được hỗ trợ'));
      });

      test('should fail for null category', () {
        final result = AIDestinationValidator.validateCategory(null);
        expect(result.isValid, false);
        expect(result.errors.first, contains('không được để trống'));
      });
    });

    group('validateAddress', () {
      test('should pass for valid Vietnam address', () {
        final result = AIDestinationValidator.validateAddress('123 Trần Phú, Hội An, Quảng Nam');
        expect(result.isValid, true);
        expect(result.errors, isEmpty);
      });

      test('should fail for too short address', () {
        final result = AIDestinationValidator.validateAddress('Short');
        expect(result.isValid, false);
        expect(result.errors.first, contains('quá ngắn'));
      });

      test('should warn for address without Vietnamese city', () {
        final result = AIDestinationValidator.validateAddress('123 Main Street, Some City');
        expect(result.isValid, true);
        expect(result.warnings, isNotEmpty);
        expect(result.warnings.first, contains('không chứa tên thành phố Việt Nam'));
      });
    });

    group('validateSuggestion', () {
      test('should pass for valid suggestion', () {
        final suggestion = AIActivitySuggestion(
          id: 'test-1',
          tripId: 'trip-1',
          activityName: 'Bánh mì Phượng Hội An',
          description: 'Tiệm bánh mì trứ danh được đầu bếp Anthony Bourdain khen ngợi, nổi tiếng với pate béo ngậy, các loại nhân đa dạng và nước sốt đặc trưng.',
          reason: 'Địa điểm huyền thoại, giá cả phải chăng, phù hợp cho bữa sáng nhanh gọn',
          category: 'restaurant',
          latitude: 15.8801,
          longitude: 108.3380,
          address: '2B Phan Châu Trinh, Minh An, Hội An',
          suggestedAt: DateTime.now(),
        );

        final result = AIDestinationValidator.validateSuggestion(suggestion);
        expect(result.isValid, true);
        expect(result.errors, isEmpty);
      });

      test('should fail for invalid suggestion', () {
        final suggestion = AIActivitySuggestion(
          id: 'test-1',
          tripId: 'trip-1',
          activityName: 'Test', // Too short
          description: 'Short', // Too short
          reason: 'Test reason',
          category: 'invalid', // Invalid category
          latitude: 40.7128, // Outside Vietnam
          longitude: -74.0060, // Outside Vietnam
          suggestedAt: DateTime.now(),
        );

        final result = AIDestinationValidator.validateSuggestion(suggestion);
        expect(result.isValid, false);
        expect(result.errors.length, greaterThan(3)); // Multiple errors
      });
    });
  });
}
