import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zikirmatik_v2/app/zikirmatik_app.dart';
import 'package:zikirmatik_v2/features/counter/presentation/zikr_counter_screen.dart';
import 'package:zikirmatik_v2/features/dashboard/presentation/dashboard_screen.dart';
import 'package:zikirmatik_v2/features/dhikr_library/data/builtin_dhikrs.dart';
import 'package:zikirmatik_v2/features/dhikr_library/presentation/dhikr_library_screen.dart';
import 'package:zikirmatik_v2/features/splash/presentation/splash_screen.dart';

void main() {
  Future<void> pumpMobileApp(
    WidgetTester tester, {
    Map<String, Object> sharedPreferences = const {},
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    SharedPreferences.setMockInitialValues(sharedPreferences);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(child: ZikirmatikApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4650));
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

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.menu_rounded).hitTestable().first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
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
    expect(find.byKey(const Key('dhikr.card.subhanallah')), findsOneWidget);
  });

  testWidgets('home bottom nav stays close to bottom with iPhone inset', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(393, 852),
              padding: EdgeInsets.only(top: 47, bottom: 34),
            ),
            child: HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    final quickStartCenter = tester.getCenter(
      find.byKey(const Key('home.quickStart')),
    );

    expect(quickStartCenter.dy, greaterThan(790));
  });

  testWidgets('home header scrolls with the page content', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(393, 852),
              padding: EdgeInsets.only(top: 47, bottom: 34),
            ),
            child: HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    final menuIcon = find.byIcon(Icons.menu_rounded);
    final topBeforeScroll = tester.getTopLeft(menuIcon).dy;

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -160),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.getTopLeft(menuIcon).dy, lessThan(topBeforeScroll - 80));
  });

  testWidgets('library selection opens counter and counter resets', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.byKey(const Key('home.chooseDhikr')));
    await pumpUntilFound(
      tester,
      find.byKey(const Key('dhikr.card.subhanallah')),
    );

    await tester.tap(find.byKey(const Key('dhikr.card.subhanallah')));
    final startButton = find.byKey(const Key('dhikr.detail.start'));
    await pumpUntilFound(tester, startButton);
    await tester.dragFrom(const Offset(196, 790), const Offset(0, -900));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(startButton);
    await pumpUntilFound(tester, find.byKey(const Key('counter.increment')));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(ZikrCounterScreen), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    final counterFinder = find.byKey(const Key('counter.increment'));

    await tester.tap(counterFinder);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('TESBİH\nMODU'));
    await tester.pump(const Duration(milliseconds: 2200));

    await tester.tap(counterFinder);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('0'), findsOneWidget);

    final tesbihCounterRect = tester.getRect(counterFinder);
    final tesbihPullStart = Offset(
      tesbihCounterRect.left + tesbihCounterRect.width * 0.86,
      tesbihCounterRect.top + tesbihCounterRect.height * 0.30,
    );

    await tester.timedDragFrom(
      tesbihPullStart,
      const Offset(0, 220),
      const Duration(milliseconds: 600),
    );
    await tester.pump(const Duration(milliseconds: 360));

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets(
    'quick start opens default counter on fresh install and counter after',
    (tester) async {
      await pumpMobileApp(tester);

      await tester.tap(find.byKey(const Key('home.quickStart')));
      await pumpUntilFound(tester, find.byKey(const Key('counter.increment')));

      expect(find.byType(ZikrCounterScreen), findsOneWidget);

      await pumpMobileApp(
        tester,
        sharedPreferences: {'counter.lastStartedDhikrId': 'subhanallah'},
      );

      await tester.tap(find.byKey(const Key('home.quickStart')));
      await pumpUntilFound(tester, find.byKey(const Key('counter.increment')));

      expect(find.byType(ZikrCounterScreen), findsOneWidget);
      expect(find.byKey(const Key('counter.increment')), findsOneWidget);
    },
  );

  testWidgets('cupertino menu waits for drawer close before returning home', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pumpMobileApp(tester);

      await tester.tap(find.byKey(const Key('home.chooseDhikr')));
      await pumpUntilFound(tester, find.byType(DhikrLibraryScreen));
      await openMenu(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.text('Ana Sayfa'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(DhikrLibraryScreen), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await pumpUntilFound(tester, find.byType(HomeScreen));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('material menu returns home without extra delay', (tester) async {
    await pumpMobileApp(tester);

    await tester.tap(find.byKey(const Key('home.chooseDhikr')));
    await pumpUntilFound(tester, find.byType(DhikrLibraryScreen));
    await openMenu(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Ana Sayfa'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('menu restores active dhikr from the last started id', (
    tester,
  ) async {
    final restoredDhikr = builtinDhikrs.firstWhere(
      (item) => item.id == 'estagfirullah',
    );

    await pumpMobileApp(
      tester,
      sharedPreferences: {'counter.lastStartedDhikrId': restoredDhikr.id},
    );

    expect(find.text(restoredDhikr.name), findsOneWidget);
    expect(find.text('0 / ${restoredDhikr.defaultTarget}'), findsOneWidget);

    await openMenu(tester);

    expect(find.byType(Drawer), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text(restoredDhikr.name),
      ),
      findsOneWidget,
    );
  });

  testWidgets('menu restores active counter session after restart', (
    tester,
  ) async {
    final session = jsonEncode({
      'activeDhikr': {
        'id': 'custom-sabah-virdi',
        'name': 'Sabah virdi',
        'category': 'Ozel',
        'defaultTarget': 41,
        'isBuiltIn': false,
      },
      'count': 12,
      'target': 41,
    });

    await pumpMobileApp(
      tester,
      sharedPreferences: {'counter.activeSession': session},
    );

    expect(find.text('Sabah virdi'), findsOneWidget);
    expect(find.text('12 / 41'), findsOneWidget);

    await openMenu(tester);

    expect(find.byType(Drawer), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Sabah virdi'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(Drawer), matching: find.text('%29')),
      findsOneWidget,
    );
  });
}
