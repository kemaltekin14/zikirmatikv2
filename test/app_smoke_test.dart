import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zikirmatik_v2/app/zikirmatik_app.dart';
import 'package:zikirmatik_v2/features/counter/presentation/counter_screen.dart';
import 'package:zikirmatik_v2/features/dashboard/presentation/dashboard_screen.dart';
import 'package:zikirmatik_v2/features/dhikr_library/presentation/dhikr_library_screen.dart';
import 'package:zikirmatik_v2/features/splash/presentation/splash_screen.dart';

void main() {
  Future<void> pumpMobileApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(child: ZikirmatikApp()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 850));
    for (
      var i = 0;
      i < 20 && find.byType(SplashScreen).evaluate().isNotEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    int maxPumps = 20,
  }) async {
    for (var i = 0; i < maxPumps && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('app starts with asset based splash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: ZikirmatikApp()));
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('home is the first screen and choose CTA opens library', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const Key('counter.increment')), findsNothing);

    await tester.tap(find.byKey(const Key('home.chooseDhikr')));
    await pumpUntilFound(tester, find.byType(DhikrLibraryScreen));

    expect(find.byType(DhikrLibraryScreen), findsOneWidget);
    expect(find.byKey(const Key('dhikr.start.subhanallah')), findsOneWidget);
  });

  testWidgets('library selection opens counter and counter resets', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.byKey(const Key('home.chooseDhikr')));
    await pumpUntilFound(
      tester,
      find.byKey(const Key('dhikr.start.subhanallah')),
    );

    await tester.tap(find.byKey(const Key('dhikr.start.subhanallah')));
    await pumpUntilFound(tester, find.byKey(const Key('counter.increment')));

    expect(find.byType(CounterScreen), findsOneWidget);
    expect(find.text('Subhanallah'), findsWidgets);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('counter.increment')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('quick start opens library before selection and counter after', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.byKey(const Key('home.quickStart')));
    await pumpUntilFound(tester, find.byType(DhikrLibraryScreen));

    expect(find.byType(DhikrLibraryScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('dhikr.start.subhanallah')));
    await pumpUntilFound(tester, find.byKey(const Key('counter.increment')));

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await pumpUntilFound(tester, find.byType(HomeScreen));

    await tester.tap(find.byKey(const Key('home.quickStart')));
    await pumpUntilFound(tester, find.byKey(const Key('counter.increment')));

    expect(find.byType(CounterScreen), findsOneWidget);
    expect(find.text('Subhanallah'), findsWidgets);
  });
}
