import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'store_channel.dart';

final appEnvironmentProvider = Provider<AppEnvironment>((ref) {
  return AppEnvironment.fromDefines();
});
