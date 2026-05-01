import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local/app_database.dart';
import '../../../core/data/local/database_provider.dart';
import '../../esma/data/esma_data.dart';
import '../../settings/application/settings_controller.dart';
import '../data/builtin_dhikrs.dart';
import '../domain/dhikr_item.dart';

final dhikrItemsProvider = StreamProvider<List<DhikrItem>>((ref) async* {
  final favorites = ref.watch(settingsControllerProvider).favorites;
  final database = ref.watch(appDatabaseProvider);
  final builtIns =
      [...builtinDhikrs, ...esmaItems.map((item) => item.toDhikr())]
          .map((item) => item.copyWith(isFavorite: favorites.contains(item.id)))
          .toList();

  yield builtIns;

  await for (final customRecords in database.watchCustomDhikrs()) {
    final custom = customRecords.map(_recordToDhikr).toList();
    yield [...builtIns, ...custom];
  }
});

final dhikrRepositoryProvider = Provider<DhikrRepository>((ref) {
  return DhikrRepository(ref.watch(appDatabaseProvider));
});

class DhikrRepository {
  const DhikrRepository(this._database);

  final AppDatabase _database;

  Future<void> addCustomDhikr({
    required String name,
    required String category,
    required int defaultTarget,
    String? arabicText,
    String? meaning,
  }) {
    return _database.upsertCustomDhikr(
      name: name,
      category: category,
      defaultTarget: defaultTarget,
      arabicText: arabicText,
      meaning: meaning,
    );
  }

  Future<void> setCustomDhikrFavorite({
    required String id,
    required bool isFavorite,
  }) {
    return _database.setCustomDhikrFavorite(id: id, isFavorite: isFavorite);
  }
}

DhikrItem _recordToDhikr(DhikrRecord record) {
  return DhikrItem(
    id: record.id,
    name: record.name,
    arabicText: record.arabicText,
    meaning: record.meaning,
    category: record.category,
    defaultTarget: record.defaultTarget,
    isFavorite: record.isFavorite,
    isBuiltIn: record.isBuiltIn,
  );
}
