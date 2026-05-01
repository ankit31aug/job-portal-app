import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/models/models.dart';

void main() {
  group('User model', () {
    test('fromJson parses required fields correctly', () {
      final json = {
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'role': 'jobseeker',
        'created_at': '2024-01-01',
      };

      final user = User.fromJson(json);

      expect(user.id, 1);
      expect(user.name, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.role, 'jobseeker');
    });

    test('fromJson uses defaults for missing optional fields', () {
      final json = {
        'id': 2,
        'created_at': '2024-01-01',
      };

      final user = User.fromJson(json);

      expect(user.name, '');
      expect(user.email, '');
      expect(user.role, 'jobseeker');
      expect(user.phone, isNull);
      expect(user.bio, isNull);
    });
  });
}
