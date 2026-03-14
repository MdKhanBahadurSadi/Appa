import 'package:flutter_test/flutter_test.dart';
import 'package:appa_pdf/services/recent_files_service.dart';

void main() {
  group('RecentFile Model Tests', () {
    test('RecentFile should be created with correct values', () {
      final file = RecentFile(
        path: '/test/path.pdf',
        name: 'test.pdf',
        date: 'Oct 25, 2023',
        size: '1.2 MB',
      );

      expect(file.path, '/test/path.pdf');
      expect(file.name, 'test.pdf');
      expect(file.date, 'Oct 25, 2023');
      expect(file.size, '1.2 MB');
    });

    test('RecentFile toJson should return a correct map', () {
      final file = RecentFile(
        path: '/test/path.pdf',
        name: 'test.pdf',
        date: 'Oct 25, 2023',
        size: '1.2 MB',
      );

      final json = file.toJson();

      expect(json['path'], '/test/path.pdf');
      expect(json['name'], 'test.pdf');
      expect(json['date'], 'Oct 25, 2023');
      expect(json['size'], '1.2 MB');
    });

    test('RecentFile.fromJson should create a correct object', () {
      final json = {
        'path': '/test/path.pdf',
        'name': 'test.pdf',
        'date': 'Oct 25, 2023',
        'size': '1.2 MB',
      };

      final file = RecentFile.fromJson(json);

      expect(file.path, '/test/path.pdf');
      expect(file.name, 'test.pdf');
      expect(file.date, 'Oct 25, 2023');
      expect(file.size, '1.2 MB');
    });
  });
}
