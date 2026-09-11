import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appa_pdf/services/recent_files_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecentFilesService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Should add a recent file and retrieve it', () async {
      final file = RecentFile(
        path: '/path/to/doc.pdf',
        name: 'doc.pdf',
        date: 'Oct 10, 2023',
        size: '1.2 MB',
      );

      await RecentFilesService.addRecentFile(file);
      final files = await RecentFilesService.getRecentFiles();

      expect(files.length, 1);
      expect(files[0].path, '/path/to/doc.pdf');
    });

    test('Should limit recent files to 20', () async {
      for (int i = 0; i < 25; i++) {
        await RecentFilesService.addRecentFile(RecentFile(
          path: '/path/to/doc$i.pdf',
          name: 'doc$i.pdf',
          date: 'Oct 10, 2023',
          size: '1.2 MB',
        ));
      }

      final files = await RecentFilesService.getRecentFiles();
      expect(files.length, 20);
      // The most recent should be doc24
      expect(files[0].name, 'doc24.pdf');
    });

    test('Should remove a recent file', () async {
      const path = '/path/to/doc.pdf';
      await RecentFilesService.addRecentFile(RecentFile(
        path: path,
        name: 'doc.pdf',
        date: 'Oct 10, 2023',
        size: '1.2 MB',
      ));

      await RecentFilesService.removeRecentFile(path);
      final files = await RecentFilesService.getRecentFiles();
      expect(files.isEmpty, true);
    });

    test('Should pin a file to top', () async {
      await RecentFilesService.addRecentFile(RecentFile(path: '1', name: '1', date: '', size: ''));
      await RecentFilesService.addRecentFile(RecentFile(path: '2', name: '2', date: '', size: ''));
      
      await RecentFilesService.pinToTop('1');
      final files = await RecentFilesService.getRecentFiles();
      
      expect(files[0].path, '1');
      expect(files[1].path, '2');
    });
  });
}
