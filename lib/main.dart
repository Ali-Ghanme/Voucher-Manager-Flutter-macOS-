import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:voucher_manager/core/theme/app_theme_dark.dart';
import 'package:window_manager/window_manager.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/repository_providers.dart';
import 'presentation/screens/compact_floating_screen.dart';
import 'presentation/screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window_manager before runApp so we can control the
  // native macOS window (size, title bar, always-on-top) from the
  // very first frame.
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(AppConstants.normalWindowWidth, AppConstants.normalWindowHeight),
    minimumSize: Size(360, 480),
    center: true,
    title: 'مدير بطاقات الفاوتشر',
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: VoucherManagerApp()));
}

class VoucherManagerApp extends ConsumerWidget {
  const VoucherManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = ref.watch(isCompactModeProvider);

    return ScreenUtilInit(
        ensureScreenSize: true,
        designSize:
            AppConstants.compactWindowHeight > AppConstants.compactWindowWidth
                ? const Size(AppConstants.compactWindowHeight,
                    AppConstants.compactWindowWidth)
                : const Size(AppConstants.compactWindowWidth,
                    AppConstants.compactWindowHeight),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            darkTheme: appThemeDark(),
            theme: appThemeLight(),
            themeMode: ThemeMode.system,
            locale: const Locale('ar'),
            builder: (context, child) => Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
            home:
                isCompact ? const CompactFloatingScreen() : const MainScreen(),
          );
        });
  }
}
