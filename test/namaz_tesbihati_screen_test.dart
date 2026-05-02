import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zikirmatik_v2/features/namaz_tesbihati/presentation/namaz_tesbihati_screen.dart';

void main() {
  testWidgets('shows completed prayer chip for current day', (tester) async {
    SharedPreferences.setMockInitialValues({
      'namazTesbihati.completionDay': _dayKey(DateTime.now()),
      'namazTesbihati.completedPrayerTimes': <String>['3'],
    });

    await _pumpScreen(tester);

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('ignores completed prayer chip from previous day', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'namazTesbihati.completionDay': _dayKey(
        DateTime.now().subtract(const Duration(days: 1)),
      ),
      'namazTesbihati.completedPrayerTimes': <String>['3'],
    });

    await _pumpScreen(tester);

    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });
}

Future<void> _pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(393, 852)),
          child: NamazTesbihatiScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

String _dayKey(DateTime date) {
  final localDate = date.toLocal();
  final year = localDate.year.toString().padLeft(4, '0');
  final month = localDate.month.toString().padLeft(2, '0');
  final day = localDate.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
