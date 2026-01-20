import 'package:brainrot/view/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/routes/app_routes.dart';
import 'core/themes/app_theme.dart';
import 'generated/l10n.dart';
import 'view_model/app_view_model.dart';
import 'view_model/home_view_model.dart';
import 'view_model/blocking_view_model.dart';

class BrainrotApp extends StatelessWidget {
  const BrainrotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppViewModel()..loadSettings()),
        ChangeNotifierProvider(create: (_) => BlockingViewModel()..initialize()),
        // Add more providers here as needed
      ],
      child: Consumer<AppViewModel>(
        builder: (context, appViewModel, child) {
          return MaterialApp.router(
            title: 'Brainrot',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appViewModel.themeMode,
            locale: appViewModel.locale,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            routerConfig: AppRoutes.router,
          );
        },
      ),
    );
  }
}
