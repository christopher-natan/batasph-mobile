import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/app_binding.dart';
import 'package:batasph_mobile/config/theme/my_theme.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/routes/app_pages.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // First, so everything below — including its own failures — is recorded.
  await BatasphLogger.init();
  BatasphLogger.lifecycle('App starting');

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await MySharedPref.init();

  // Foreground/background transitions, for correlating "what was the user
  // doing" with the timestamps around a problem.
  AppLifecycleListener(
    onStateChange: (state) => BatasphLogger.lifecycle(state.name),
  );

  // No runZonedGuarded here: uncaught async errors are already caught by
  // PlatformDispatcher.onError (installed by BatasphLogger.init), and a custom
  // zone would put runApp in a different zone from ensureInitialized above,
  // which Flutter flags as a zone mismatch.
  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      ensureScreenSize: true,
      builder: (context, child) {
        final isLight = MySharedPref.getThemeIsLight();
        return GetMaterialApp(
          title: 'BatasPH',
          debugShowCheckedModeBanner: false,
          theme: MyTheme.getThemeData(isLight: true),
          darkTheme: MyTheme.getThemeData(isLight: false),
          themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.noScaling),
            child: child!,
          ),
          initialBinding: AppBinding(),
          initialRoute: AppPages.INITIAL,
          getPages: AppPages.routes,
          // Every push/pop/replace across the whole app, without touching a
          // single page.
          routingCallback: (routing) {
            if (routing == null) return;
            final action = routing.isBack == true ? 'back to' : 'to';
            BatasphLogger.nav(
              '$action ${routing.current}'
              '${routing.previous.isNotEmpty ? ' (from ${routing.previous})' : ''}',
            );
          },
        );
      },
    ),
  );
}
