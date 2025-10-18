import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/routes/app_routes.dart';
import 'core/themes/app_theme.dart';
import 'view_model/app_view_model.dart';
import 'view_model/home_view_model.dart';
import 'view_model/blocking_view_model.dart';

class BrainrotApp extends StatelessWidget {
  const BrainrotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppViewModel()),
        ChangeNotifierProvider(create: (_) => BlockingViewModel()),
        // Add more providers here as needed
      ],
      child: MaterialApp.router(
        title: 'Brainrot',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Removed dark theme functionality
        routerConfig: AppRoutes.router,
      ),
    );
  }
}
