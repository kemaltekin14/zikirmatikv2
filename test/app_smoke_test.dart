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
import 'package:zikirmatik_v2/features/esma/data/esma_data.dart';
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

  test('builtin istigfar list includes researched entries', () {
    final istigfarItems = builtinDhikrs
        .where((item) => item.category == 'İstiğfar')
        .toList();
    final istigfarIds = istigfarItems.map((item) => item.id).toSet();

    expect(
      istigfarIds,
      containsAll({
        'estagfirullah',
        'estagfirullah-el-azim',
        'seyyidul-istigfar',
        'rabbigfir-li-ve-tub-aleyye',
        'subhanallahi-bihamdihi-estagfirullah',
        'allahumme-inneke-afuvvun',
        'rabbena-zalemna',
        'yunus-duasi',
      }),
    );

    expect(
      builtinDhikrs
          .firstWhere((item) => item.id == 'rabbigfir-li-ve-tub-aleyye')
          .name,
      'Rabbiğfir lî ve tüb aleyye, inneke ente’t-Tevvâbü’r-Rahîm',
    );
    expect(
      builtinDhikrs.firstWhere((item) => item.id == 'yunus-duasi').name,
      'Lâ ilâhe illâ ente sübhâneke innî küntü mine’z-zâlimîn',
    );
    expect(
      builtinDhikrs
          .firstWhere((item) => item.id == 'estagfirullah-el-azim')
          .name,
      'Estağfirullahe’l-azîm ellezî lâ ilâhe illâ hüve’l-Hayyü’l-Kayyûm ve etûbü ileyh',
    );
    expect(
      builtinDhikrs
          .firstWhere((item) => item.id == 'allahumme-inneke-afuvvun')
          .name,
      'Allahümme inneke afüvvün tühibbü’l-afve fa‘fü annî',
    );
  });

  test('builtin tesbih list includes contemplative long meanings', () {
    final tesbihItems = builtinDhikrs
        .where((item) => item.category == 'Tesbih')
        .toList();

    expect(
      tesbihItems.map((item) => item.id),
      containsAll({
        'subhanallah',
        'elhamdulillah',
        'allahu-ekber',
        'subhanallahi-ve-bihamdihi',
        'subhanallahi-bihamdihi-adede-halkihi',
        'subhanallahil-azim',
        'allahumme-salli',
      }),
    );

    for (final item in tesbihItems) {
      expect(
        item.longMeaning?.trim().length ?? 0,
        greaterThan(120),
        reason: '${item.id} should have a detailed meaning for the sheet',
      );
    }

    expect(
      builtinDhikrs.firstWhere((item) => item.id == 'subhanallahil-azim').name,
      "Sübhanallahi ve bihamdihî, sübhanallahi'l-azîm",
    );
  });

  test('builtin tevhid list includes simple kelime-i tevhid', () {
    final tevhidIds = builtinDhikrs
        .where((item) => item.category == 'Tevhid')
        .map((item) => item.id)
        .toSet();

    expect(
      tevhidIds,
      containsAll({
        'la-ilahe-illallah',
        'la-ilahe-illallah-vahdehu',
        'la-havle',
      }),
    );
    expect(
      builtinDhikrs.firstWhere((item) => item.id == 'la-ilahe-illallah').name,
      'Lâ ilâhe illallah',
    );
  });

  test('all new non-esma builtin dhikrs must include long meanings', () {
    final nonEsmaItems = builtinDhikrs
        .where((item) => item.category != 'Esma-ül Hüsna')
        .toList();

    for (final item in nonEsmaItems) {
      expect(
        item.longMeaning?.trim().length ?? 0,
        greaterThan(120),
        reason:
            '${item.id} should include a researched long meaning before release',
      );
    }
  });

  test('esma total count excludes Allah heading entry', () {
    expect(esmaItems.length, greaterThan(99));
    expect(esmaItems.where((item) => item.name == 'Allah'), hasLength(1));
    expect(esmaItems.where((item) => item.hasDisplayNumber), hasLength(99));
  });

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
    expect(
      find.byKey(const Key('dhikr.category.tesbih.card.subhanallah')),
      findsOneWidget,
    );
    expect(find.text('Dua'), findsNothing);
  });

  testWidgets('library add button opens custom dhikr sheet', (tester) async {
    await pumpMobileApp(tester);

    await tester.tap(find.byKey(const Key('home.chooseDhikr')));
    await pumpUntilFound(tester, find.byType(DhikrLibraryScreen));

    await tester.tap(find.byKey(const Key('dhikr.addCustom')));
    await pumpUntilFound(tester, find.byKey(const Key('dhikr.customSheet')));

    expect(find.byKey(const Key('dhikr.customSheet')), findsOneWidget);
    expect(find.text('Arapça metin (isteğe bağlı)'), findsOneWidget);
    expect(
      find.text('Kendi zikrini kütüphaneye özel bir kart olarak ekle.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const Key('dhikr.categoryField')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('dhikr.categoryField')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('dhikr.categoryOption.dua')), findsNothing);
    expect(find.byKey(const Key('dhikr.categoryOption.tevhid')), findsWidgets);

    await tester.tap(
      find.byKey(const Key('dhikr.categoryOption.tevhid')).first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('Vazgeç'));
    await tester.tap(find.text('Vazgeç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('dhikr.customSheet')), findsNothing);
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
    const firstGroupedDhikrKey = Key('dhikr.category.tesbih.card.subhanallah');

    await pumpMobileApp(tester);

    await tester.tap(find.byKey(const Key('home.chooseDhikr')));
    await pumpUntilFound(tester, find.byKey(firstGroupedDhikrKey));

    await tester.tap(find.byKey(firstGroupedDhikrKey));
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
    'quick start opens estagfirullah when there is no ongoing counter',
    (tester) async {
      final fallbackDhikr = builtinDhikrs.firstWhere(
        (item) => item.id == 'estagfirullah',
      );

      await pumpMobileApp(tester);

      await tester.tap(find.byKey(const Key('home.quickStart')));
      await pumpUntilFound(tester, find.byKey(const Key('counter.increment')));

      expect(find.byType(ZikrCounterScreen), findsOneWidget);
      expect(find.text(fallbackDhikr.name), findsWidgets);

      await pumpMobileApp(
        tester,
        sharedPreferences: {'counter.lastStartedDhikrId': 'subhanallah'},
      );

      await tester.tap(find.byKey(const Key('home.quickStart')));
      await pumpUntilFound(tester, find.byKey(const Key('counter.increment')));

      expect(find.byType(ZikrCounterScreen), findsOneWidget);
      expect(find.byKey(const Key('counter.increment')), findsOneWidget);
      expect(find.text(fallbackDhikr.name), findsWidgets);
    },
  );

  testWidgets('quick start resumes active counter session after restart', (
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
      'count': 10,
      'target': 41,
    });

    await pumpMobileApp(
      tester,
      sharedPreferences: {'counter.activeSession': session},
    );

    await tester.tap(find.byKey(const Key('home.quickStart')));
    await pumpUntilFound(tester, find.byKey(const Key('counter.increment')));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(ZikrCounterScreen), findsOneWidget);
    expect(find.text('Sabah virdi'), findsWidgets);
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('cupertino menu waits for drawer to close before navigation', (
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
      await tester.pump(const Duration(milliseconds: 140));

      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(Drawer), findsOneWidget);

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

  testWidgets('menu esma badge excludes Allah heading entry', (tester) async {
    await pumpMobileApp(tester);
    await openMenu(tester);

    expect(find.byType(Drawer), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Esma-ül Hüsna'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(Drawer), matching: find.text('99')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(Drawer), matching: find.text('100')),
      findsNothing,
    );
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

    await openMenu(tester);

    expect(find.byType(Drawer), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Aktif zikir'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text(restoredDhikr.name),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(Drawer), matching: find.text('%0')),
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

    await tester.tap(find.byKey(const Key('menu.activeDhikrCard')));
    await tester.pump();
    await pumpUntilFound(tester, find.byType(ZikrCounterScreen));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(ZikrCounterScreen), findsOneWidget);
    expect(find.text('Sabah virdi'), findsWidgets);
    expect(find.text('12'), findsOneWidget);
  });
}
