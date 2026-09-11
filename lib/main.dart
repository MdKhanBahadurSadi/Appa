import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pdf_viewer_screen.dart';
import 'screens/documents_library_screen.dart';
import 'screens/merge_pdf_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/pdf_signature_screen.dart';
import 'screens/ai_study_screen.dart';
import 'screens/pdf_tools_screen.dart';
import 'screens/secure_vault_screen.dart';
import 'providers/file_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  // Open boxes in parallel to speed up startup
  await Future.wait([
    Hive.openBox('chat_history'),
    Hive.openBox('document_settings'),
    Hive.openBox('secure_vault'),
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FileProvider()),
      ],
      child: const AppaPDFApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/pdf-viewer',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) return const DashboardScreen();
        return PDFViewerScreen(
          path: extra['path'] as String? ?? '',
          fileName: extra['fileName'] as String? ?? 'Document',
        );
      },
    ),
    GoRoute(
      path: '/library',
      builder: (context, state) => const DocumentsLibraryScreen(),
    ),
    GoRoute(
      path: '/merge',
      builder: (context, state) => const MergePdfScreen(),
    ),
    GoRoute(
      path: '/ai-chat',
      builder: (context, state) => const AiChatScreen(),
    ),
    GoRoute(
      path: '/signature',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) return const DashboardScreen();
        return PdfSignatureScreen(
          path: extra['path'] as String? ?? '',
          fileName: extra['fileName'] as String? ?? 'Document',
        );
      },
    ),
    GoRoute(
      path: '/ai-study',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) return const DashboardScreen();
        return AiStudyScreen(
          filePath: extra['path'] as String? ?? '',
          fileName: extra['fileName'] as String? ?? 'Document',
          apiKey: extra['apiKey'] as String? ?? '',
          mode: extra['mode'] as String? ?? 'quiz',
        );
      },
    ),
    GoRoute(
      path: '/tools',
      builder: (context, state) => const PdfToolsScreen(),
    ),
    GoRoute(
      path: '/vault',
      builder: (context, state) => const SecureVaultScreen(),
    ),
  ],
);

class AppaPDFApp extends StatelessWidget {
  const AppaPDFApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AppaPDF',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(Brightness.light),
      darkTheme: AppTheme.buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
