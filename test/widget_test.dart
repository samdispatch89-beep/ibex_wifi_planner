import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ibex_wifi_planner/app.dart';
import 'package:ibex_wifi_planner/controllers/planner_controller.dart';
import 'package:ibex_wifi_planner/views/planner_dashboard_view.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const IbexPlannerApp());
    await tester.pumpAndSettle();
  }

  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first
        .reset();
  });

  testWidgets('dashboard renders on desktop layout', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.reset);
    await pumpAtSize(tester, const Size(1600, 1200));

    expect(find.text('Ibex Planner'), findsOneWidget);
    expect(find.text('System architecture'), findsOneWidget);
    expect(find.text('Global health'), findsOneWidget);
    expect(find.text('RF simulation'), findsOneWidget);
  });

  testWidgets('dashboard renders on tablet layout', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.reset);
    await pumpAtSize(tester, const Size(900, 1200));

    expect(find.text('Ibex Planner'), findsOneWidget);
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('System architecture'), findsOneWidget);
  });

  testWidgets('dashboard renders on mobile layout', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.reset);
    await pumpAtSize(tester, const Size(390, 844));

    expect(find.text('Ibex Planner'), findsOneWidget);
    expect(find.text('Global health'), findsOneWidget);
    expect(find.text('System architecture'), findsOneWidget);
  });

  testWidgets(
    'all dashboard pages render on narrow mobile without exceptions',
    (WidgetTester tester) async {
      addTearDown(tester.view.reset);
      await pumpAtSize(tester, const Size(320, 700));

      final context = tester.element(find.byType(PlannerDashboardView));
      final controller = Provider.of<PlannerController>(context, listen: false);

      for (var index = 0; index < controller.pages.length; index++) {
        final label = controller.pages[index].label;
        controller.selectPage(index);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: label);
      }
    },
  );
}
