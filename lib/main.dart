import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';
import 'utils/auth_state.dart';

/// Application entry point.
///
/// Configures edge-to-edge display, RTL Arabic directionality, and the
/// shared app theme + auth state provider. All routes are declared
/// in [_router] so the welcome → auth → dashboard flow is wired
/// in a single discoverable place.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Force edge-to-edge so the app fills the screen on all platforms
  // (Android notches, iOS safe areas, desktop chrome, web viewport).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Make status + nav bars transparent overlays on top of the brand color.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const ErpMauritaniaApp());
}

class ErpMauritaniaApp extends StatelessWidget {
  const ErpMauritaniaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>(create: (_) => AuthState()),
      ],
      child: MaterialApp(
        title: 'نظام ERP موريتانيا',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // Force Arabic RTL at the application root so every inherited
        // widget (including dialogs/bottom sheets) respects RTL even on
        // non-Arabic system locales.
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        initialRoute: WelcomeScreen.route,
        onGenerateRoute: _router,
      ),
    );
  }

  Route<dynamic>? _router(RouteSettings settings) {
    switch (settings.name) {
      case WelcomeScreen.route:
        return MaterialPageRoute(
            builder: (_) => const WelcomeScreen(), settings: settings);
      default:
        // The auth + dashboard screens receive their role/args via
        // constructor (pushed via Navigator.push) so we fall back to
        // the welcome screen for unknown routes.
        return MaterialPageRoute(
            builder: (_) => const WelcomeScreen(), settings: settings);
    }
  }
}
