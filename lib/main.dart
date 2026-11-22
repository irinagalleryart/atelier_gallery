import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'controllers/gallery_data_controller.dart';
import 'controllers/locale_controller.dart';
import 'core/config/app_config.dart';
import 'l10n/app_localizations.dart';
import 'screens/admin_screen.dart';
import 'screens/gallery_home_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize language locale state from persistent storage
  final localeController = LocaleController();
  await localeController.loadSavedLocale();

  // Initialize shared data controller for gallery state
  final dataController = GalleryDataController();

  // Initialize app configuration (YAML / dart-define)
  await AppConfig.load();

  // Initialize Supabase Flutter SDK
  await SupabaseService.initialize();

  // Load initial gallery data asynchronously
  await dataController.loadAllData();

  runApp(AtelierGalleryApp(
    localeController: localeController,
    dataController: dataController,
  ));
}

class AtelierGalleryApp extends StatelessWidget {
  final LocaleController localeController;
  final GalleryDataController dataController;

  const AtelierGalleryApp({
    super.key,
    required this.localeController,
    required this.dataController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Atelier Gallery',
          debugShowCheckedModeBanner: false,
          locale: localeController.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            final uri = Uri.parse(settings.name ?? '/');
            if (uri.path == '/admin') {
              return MaterialPageRoute(
                builder: (_) => AdminScreen(
                  localeController: localeController,
                  dataController: dataController,
                ),
                settings: settings,
              );
            }
            return MaterialPageRoute(
              builder: (_) => GalleryHomeScreen(
                localeController: localeController,
                dataController: dataController,
              ),
              settings: settings,
            );
          },
        );
      },
    );
  }
}
