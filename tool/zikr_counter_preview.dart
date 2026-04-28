import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zikirmatik_v2/features/counter/presentation/zikr_counter_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: _ZikrCounterPreviewApp()));
}

class _ZikrCounterPreviewApp extends StatelessWidget {
  const _ZikrCounterPreviewApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ZikrCounterScreen(),
    );
  }
}
