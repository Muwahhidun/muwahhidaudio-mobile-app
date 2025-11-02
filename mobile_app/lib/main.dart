import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/audio/audio_handler_mobile.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/email_verified_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
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

// Global audio handler instance (mobile only)
AudioHandler? audioHandler;

// Global route observer for tracking navigation
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request notification permission BEFORE initializing AudioService (Android 13+)
  if (!kIsWeb) {
    try {
      debugPrint('Checking notification permission...');
      final permission = await Permission.notification.status;
      debugPrint('Notification permission status: $permission');

      if (!permission.isGranted) {
        debugPrint('Requesting notification permission...');
        final result = await Permission.notification.request();
        debugPrint('Notification permission request result: $result');

        if (!result.isGranted) {
          debugPrint('WARNING: Notification permission denied. Audio notifications may not work.');
        } else {
          debugPrint('Notification permission granted successfully!');
        }
      } else {
        debugPrint('Notification permission already granted.');
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  // Initialize AudioService on mobile platforms immediately (like web singleton)
  if (!kIsWeb) {
    try {
      debugPrint('Initializing AudioService...');
      audioHandler = await AudioService.init(
        builder: () => LessonAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.islamiclessons.mobile_app.channel.audio',
          androidNotificationChannelName: 'Islamic Audio Lessons',
          androidNotificationIcon: 'drawable/ic_stat_music_note',
          androidStopForegroundOnPause: false,
          androidShowNotificationBadge: true,
        ),
      );
      debugPrint('AudioService initialized successfully in main()');
      debugPrint('AudioHandler type: ${audioHandler.runtimeType}');
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize AudioService in main(): $e');
      debugPrint('StackTrace: $stackTrace');
      // Continue anyway - will try lazy initialization if needed
    }
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// Initialize AudioService lazily on first use
Future<void> initializeAudioServiceIfNeeded() async {
  if (kIsWeb || audioHandler != null) return;

  try {
    audioHandler = await AudioService.init(
      builder: () => LessonAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.islamiclessons.mobile_app.channel.audio',
        androidNotificationChannelName: 'Islamic Audio Lessons',
        androidNotificationIcon: 'drawable/ic_stat_music_note',
        androidStopForegroundOnPause: false,
      ),
    );
    debugPrint('AudioService initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize AudioService: $e');
    debugPrint('StackTrace: $stackTrace');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);

    // Determine which screen to show
    Widget homeScreen;
    if (authState.isLoading) {
      // Show splash screen while checking authentication
      homeScreen = const SplashScreen();
    } else if (authState.isAuthenticated) {
      // Show home screen if authenticated
      homeScreen = const HomeScreen();
    } else {
      // Show login screen if not authenticated
      homeScreen = const LoginScreen();
    }

    return MaterialApp(
      title: 'Islamic Audio Lessons',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      home: homeScreen,
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
