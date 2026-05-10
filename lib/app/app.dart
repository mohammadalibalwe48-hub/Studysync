import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/router.dart';
import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/services/theme_service.dart';

/// Root widget for the Educational Steps Platform student app.
class StudySyncApp extends StatefulWidget {
  const StudySyncApp({super.key});

  @override
  State<StudySyncApp> createState() => _StudySyncAppState();
}

class _StudySyncAppState extends State<StudySyncApp> {
  late final GoRouter _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (BuildContext context, _) {
        final ThemeMode mode = ThemeService.instance.mode;
        final Brightness sysBrightness =
            MediaQuery.platformBrightnessOf(context);
        final bool isDark = mode == ThemeMode.dark ||
            (mode == ThemeMode.system &&
                sysBrightness == Brightness.dark);
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: isDark
              ? const Color(0xFF11102A) // matches dark surface
              : const Color(0xFFF7F4FF), // matches AppTheme.background
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ));

        return MaterialApp.router(
          title: 'Educational Steps Platform',
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          // Arabic by default with full RTL support.
          locale: const Locale('ar'),
          supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          // Force RTL across the whole widget tree, including go_router
          // pages that are built outside the main Builder tree.
          builder: (BuildContext context, Widget? child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
