import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/journey_setup_screen.dart';
import 'screens/active_journey_screen.dart';
import 'screens/sos_escalation_screen.dart';
import 'screens/journey_complete_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/fake_call_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences wrapper
  final storageService = await StorageService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const GekkoApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const JourneySetupScreen(),
    ),
    GoRoute(
      path: '/active',
      builder: (context, state) => const ActiveJourneyScreen(),
    ),
    GoRoute(
      path: '/sos',
      builder: (context, state) => const SosEscalationScreen(),
    ),
    GoRoute(
      path: '/complete',
      builder: (context, state) => const JourneyCompleteScreen(),
    ),
    GoRoute(
      path: '/contacts',
      builder: (context, state) => const ContactsScreen(),
    ),
    GoRoute(
      path: '/fake-call',
      builder: (context, state) => const FakeCallScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class GekkoApp extends StatelessWidget {
  const GekkoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gekko — Personal Safety Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
