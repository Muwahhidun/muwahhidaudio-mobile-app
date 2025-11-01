import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/email_verified_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/admin/admin_panel_screen.dart';
import 'presentation/screens/admin/themes_management_screen.dart';
import 'presentation/screens/admin/books_management_screen.dart';
import 'presentation/screens/admin/book_authors_management_screen.dart';
import 'presentation/screens/admin/teachers_management_screen.dart';
import 'presentation/screens/admin/series_management_screen.dart';
import 'presentation/screens/admin/lessons_management_screen.dart';
import 'presentation/screens/admin/tests_management_screen.dart';
import 'presentation/screens/admin/statistics_screen.dart';
import 'presentation/screens/admin/admin_help_screen.dart';
import 'presentation/screens/admin/system_settings_screen.dart';
import 'presentation/screens/admin/smtp_settings_screen.dart';
import 'presentation/screens/admin/sender_settings_screen.dart';
import 'presentation/screens/admin/users_management_screen.dart';
import 'presentation/screens/admin/feedbacks_management_screen.dart';
import 'presentation/screens/themes/themes_screen.dart';

// Global route observer for tracking navigation
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Note: AudioService initialization moved to lazy initialization
  // in PlayerScreen to avoid FlutterEngine initialization timing issues

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Islamic Audio Lessons',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      home: authState.isAuthenticated ? const HomeScreen() : const LoginScreen(),
      onGenerateRoute: (settings) {
        // Handle /email-verified?token=xxx route
        if (settings.name?.startsWith('/email-verified') == true) {
          final uri = Uri.parse(settings.name!);
          final token = uri.queryParameters['token'];
          return MaterialPageRoute(
            builder: (context) => EmailVerifiedScreen(token: token),
          );
        }
        return null;
      },
      routes: {
        '/admin': (context) => const AdminPanelScreen(),
        '/admin/themes': (context) => const ThemesManagementScreen(),
        '/admin/books': (context) => const BooksManagementScreen(),
        '/admin/authors': (context) => const BookAuthorsManagementScreen(),
        '/admin/teachers': (context) => const TeachersManagementScreen(),
        '/admin/series': (context) => const SeriesManagementScreen(),
        '/admin/lessons': (context) => const LessonsManagementScreen(),
        '/admin/tests': (context) => const TestsManagementScreen(),
        '/admin/users': (context) => const UsersManagementScreen(),
        '/admin/feedbacks': (context) => const FeedbacksManagementScreen(),
        '/admin/statistics': (context) => const StatisticsScreen(),
        '/admin/help': (context) => const AdminHelpScreen(),
        '/admin/system-settings': (context) => const SystemSettingsScreen(),
        '/admin/smtp-settings': (context) => const SmtpSettingsScreen(),
        '/admin/sender-settings': (context) => const SenderSettingsScreen(),
        '/themes': (context) => const ThemesScreen(),
      },
    );
  }
}
