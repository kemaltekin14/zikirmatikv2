import 'package:audioplayers/audioplayers.dart';
import 'package:esmaulhusna_muslimbg/esmaulhusna_muslimbg.dart';
import 'package:flutter/services.dart';

import '../domain/esma_item.dart';

class EsmaAudioService {
  EsmaAudioService() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  static const _allahAudioAsset = 'assets/audio/esma/allah.mp3';

  final AudioPlayer _player = AudioPlayer();
  Future<List<Map<String, String>>>? _packageNamesFuture;

  Future<void> play(EsmaItem item) async {
    final assetPath = await _audioAssetPathFor(item);
    if (assetPath == null || assetPath.isEmpty) return;

    final bytes = await rootBundle.load(assetPath);
    final audioBytes = bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    await _player.stop();
    await _player.play(
      BytesSource(audioBytes, mimeType: _mimeTypeFor(assetPath)),
    );
  }

  Future<void> stop() {
    return _player.stop();
  }

  Future<void> dispose() {
    return _player.dispose();
  }

  Future<String?> _audioAssetPathFor(EsmaItem item) async {
    if (!item.hasDisplayNumber) return _allahAudioAsset;

    final names = await (_packageNamesFuture ??= EsmaulHusna.getNames('tr'));
    if (item.number < 0 || item.number >= names.length) return null;
    return names[item.number]['audio'];
  }

  String _mimeTypeFor(String assetPath) {
    if (assetPath.toLowerCase().endsWith('.ogg')) return 'audio/ogg';
    return 'audio/mpeg';
  }
}
