import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';
import 'utils/auth_state.dart';
import 'utils/locale_provider.dart';

/// Application entry point.
///
/// Configures edge-to-edge display, RTL Arabic directionality, and the
/// shared app theme + auth state + locale provider. All routes are
/// declared in [_router] so the welcome → auth → dashboard flow is
/// wired in a single discoverable place.
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
        ChangeNotifierProvider<LocaleProvider>(
          create: (_) => LocaleProvider(initial: AppLanguage.arabic),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, locale, _) {
          return MaterialApp(
            title: locale.t('app.title'),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            // Locale is driven by the LocaleProvider so the
            // LanguageSwitcher can flip the whole app at runtime.
            locale: locale.locale,
            supportedLocales: const [
              Locale('ar', 'MR'),
              Locale('ar'),
              Locale('fr', 'FR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Directionality is driven by the LocaleProvider so
            // switching to French flips the layout to LTR automatically.
            builder: (context, child) => Directionality(
              textDirection: locale.textDirection,
              child: child!,
            ),
            initialRoute: WelcomeScreen.route,
            onGenerateRoute: _router,
          );
        },
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
