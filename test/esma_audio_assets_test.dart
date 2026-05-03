import 'package:esmaulhusna_muslimbg/esmaulhusna_muslimbg.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('esma pronunciation audio assets are bundled', () async {
    final packageNames = await EsmaulHusna.getNames('tr');

    expect(packageNames, hasLength(100));
    expect(packageNames.first['audio'], isEmpty);
    final packageAudioPaths = packageNames
        .skip(1)
        .map((name) => name['audio'])
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .toList(growable: false);

    expect(packageAudioPaths, hasLength(99));

    for (final audioPath in packageAudioPaths) {
      final audio = await rootBundle.load(audioPath);
      expect(audio.lengthInBytes, greaterThan(0));
    }

    final allahAudio = await rootBundle.load('assets/audio/esma/allah.mp3');

    expect(allahAudio.lengthInBytes, greaterThan(0));
  });
}
