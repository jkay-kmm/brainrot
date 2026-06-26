import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_routes.dart';
import 'l10n/l10n.dart';
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
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => BlockingViewModel()..initialize()),
      ],
      child: Consumer<AppViewModel>(
        builder: (context, appViewModel, child) {
          return MaterialApp.router(
            title: 'Brainrot',
            debugShowCheckedModeBanner: false,
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
