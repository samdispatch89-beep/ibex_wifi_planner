import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/planner_controller.dart';
import 'repositories/planner_repository.dart';
import 'views/planner_dashboard_view.dart';

class IbexPlannerApp extends StatelessWidget {
  const IbexPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0B6E4F);

    return MultiProvider(
      providers: [
        Provider<PlannerRepository>(create: (_) => PlannerRepository()),
        ChangeNotifierProvider<PlannerController>(
          create: (context) =>
              PlannerController(repository: context.read<PlannerRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Ibex WiFi Planner',
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);

          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: mediaQuery.textScaler.clamp(
                minScaleFactor: 0.95,
                maxScaleFactor: 1.15,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: seed,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF4F7F1),
          useMaterial3: true,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
            },
          ),
          cardTheme: const CardThemeData(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
          ),
        ),
        home: const PlannerDashboardView(),
      ),
    );
  }
}
