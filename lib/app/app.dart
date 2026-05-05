import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/router.dart';
import 'package:studysync_syria/app/theme.dart';

/// الجذر التطبيق "فيزياء وكيمياء بكالوريا سوريا".
class StudySyncApp extends StatefulWidget {
  const StudySyncApp({super.key});

  @override
  State<StudySyncApp> createState() => _StudySyncAppState();
}

class _StudySyncAppState extends State<StudySyncApp> {
  late final GoRouter _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return MaterialApp.router(
      title: 'منصة خطوات التعليمية',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // اللغة العربية افتراضياً مع دعم RTL.
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      // فرض اتجاه الكتابة من اليمين إلى اليسار على كامل شجرة العرض،
      // إضافةً إلى التأكد من تطبيق اتجاه RTL على نوافذ go_router
      // التي تُستهل خارج شجرة Builder الأساسية.
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
