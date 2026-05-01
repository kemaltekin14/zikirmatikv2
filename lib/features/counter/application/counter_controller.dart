import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/local/database_provider.dart';
import '../../../core/services/interaction_feedback_service.dart';
import '../../../core/services/app_services.dart';
import '../../dhikr_library/data/builtin_dhikrs.dart';
import '../../dhikr_library/domain/dhikr_item.dart';
import '../../esma/data/esma_data.dart';

class CounterState {
  const CounterState({
    required this.activeDhikr,
    required this.count,
    required this.target,
    this.completed = false,
  });

  final DhikrItem activeDhikr;
  final int count;
  final int target;
  final bool completed;

  bool get isInfinite => target == 0;
  double get progress =>
      isInfinite || target == 0 ? 0 : (count / target).clamp(0, 1);

  CounterState copyWith({
    DhikrItem? activeDhikr,
    int? count,
    int? target,
    bool? completed,
  }) {
    return CounterState(
      activeDhikr: activeDhikr ?? this.activeDhikr,
      count: count ?? this.count,
      target: target ?? this.target,
      completed: completed ?? this.completed,
    );
  }
}

class CounterController extends Notifier<CounterState> {
  static const _activeSessionStorageKey = 'counter.activeSession';

  var _changedBeforeRestore = false;

  @override
  CounterState build() {
    final defaultDhikr = builtinDhikrs.first;
    Future.microtask(_restoreActiveSession);
    return CounterState(
      activeDhikr: defaultDhikr,
      count: 0,
      target: defaultDhikr.defaultTarget,
    );
  }

  void startDhikr(DhikrItem dhikr, {int? target, int initialCount = 0}) {
    final resolvedTarget = target ?? dhikr.defaultTarget;
    final positiveInitialCount = initialCount < 0 ? 0 : initialCount;
    final resolvedCount =
        resolvedTarget > 0 && positiveInitialCount > resolvedTarget
        ? resolvedTarget
        : positiveInitialCount;

    state = CounterState(
      activeDhikr: dhikr,
      count: resolvedCount,
      target: resolvedTarget,
      completed: resolvedTarget > 0 && resolvedCount >= resolvedTarget,
    );
    _changedBeforeRestore = true;
    ref.read(lastStartedDhikrIdProvider.notifier).remember(dhikr.id);
    unawaited(_persistActiveSession());
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logEvent('counter_start', parameters: {'dhikr_id': dhikr.id}),
    );
  }

  void setTarget(int target) {
    state = state.copyWith(target: target, completed: false);
    _changedBeforeRestore = true;
    unawaited(_persistActiveSession());
  }

  void increment({bool useTesbihFeedback = false}) {
    if (!state.isInfinite && state.count >= state.target) return;

    final nextCount = state.count + 1;
    final completed = !state.isInfinite && nextCount >= state.target;
    state = state.copyWith(count: nextCount, completed: completed);
    _changedBeforeRestore = true;
    unawaited(_persistActiveSession());

    final feedback = ref.read(interactionFeedbackServiceProvider);
    if (completed) {
      feedback.success();
    } else if (useTesbihFeedback) {
      feedback.tesbihTick();
    } else {
      feedback.counterTick();
    }

    unawaited(
      ref
          .read(appDatabaseProvider)
          .logCounterEvent(
            dhikrId: state.activeDhikr.id,
            dhikrName: state.activeDhikr.name,
            delta: 1,
            countAfter: nextCount,
            target: state.target,
            eventType: completed ? 'completed' : 'increment',
          ),
    );
  }

  void decrement() {
    if (state.count <= 0) return;
    final nextCount = state.count - 1;
    state = state.copyWith(count: nextCount, completed: false);
    _changedBeforeRestore = true;
    unawaited(_persistActiveSession());

    unawaited(
      ref
          .read(appDatabaseProvider)
          .logCounterEvent(
            dhikrId: state.activeDhikr.id,
            dhikrName: state.activeDhikr.name,
            delta: -1,
            countAfter: nextCount,
            target: state.target,
            eventType: 'decrement',
          ),
    );
  }

  void reset() {
    state = state.copyWith(count: 0, completed: false);
    _changedBeforeRestore = true;
    unawaited(_persistActiveSession());
    unawaited(
      ref
          .read(appDatabaseProvider)
          .logCounterEvent(
            dhikrId: state.activeDhikr.id,
            dhikrName: state.activeDhikr.name,
            delta: 0,
            countAfter: 0,
            target: state.target,
            eventType: 'reset',
          ),
    );
  }

  void dismissCompletion() {
    state = state.copyWith(completed: false);
  }

  Future<void> _restoreActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_activeSessionStorageKey);
    CounterState? restored;

    if (sessionJson != null) {
      restored = _stateFromJson(sessionJson);
    }

    restored ??= _stateFromLastStartedId(
      prefs.getString(LastStartedDhikrIdController.storageKey),
    );

    if (restored == null || _changedBeforeRestore) return;
    state = restored;
  }

  Future<void> _persistActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSessionStorageKey, _stateToJson(state));
  }

  CounterState? _stateFromLastStartedId(String? dhikrId) {
    final dhikr = _knownDhikrById(dhikrId);
    if (dhikr == null) return null;
    return CounterState(
      activeDhikr: dhikr,
      count: 0,
      target: dhikr.defaultTarget,
    );
  }

  CounterState? _stateFromJson(String value) {
    try {
      final json = jsonDecode(value);
      if (json is! Map<String, Object?>) return null;

      final dhikr = _dhikrFromJson(json['activeDhikr']);
      if (dhikr == null) return null;

      final storedTarget = _intFromJson(json['target']);
      final target = storedTarget == null || storedTarget < 0
          ? dhikr.defaultTarget
          : storedTarget;
      final rawCount = _intFromJson(json['count']) ?? 0;
      final count = rawCount < 0
          ? 0
          : target > 0 && rawCount > target
          ? target
          : rawCount;

      return CounterState(
        activeDhikr: dhikr,
        count: count,
        target: target,
        completed: false,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  String _stateToJson(CounterState state) {
    return jsonEncode({
      'activeDhikr': _dhikrToJson(state.activeDhikr),
      'count': state.count,
      'target': state.target,
    });
  }

  Map<String, Object?> _dhikrToJson(DhikrItem dhikr) {
    return {
      'id': dhikr.id,
      'name': dhikr.name,
      'category': dhikr.category,
      'defaultTarget': dhikr.defaultTarget,
      'arabicText': dhikr.arabicText,
      'meaning': dhikr.meaning,
      'longMeaning': dhikr.longMeaning,
      'isBuiltIn': dhikr.isBuiltIn,
    };
  }

  DhikrItem? _dhikrFromJson(Object? value) {
    if (value is! Map<String, Object?>) return null;

    final id = value['id'];
    if (id is! String || id.isEmpty) return null;

    final knownDhikr = _knownDhikrById(id);
    if (knownDhikr != null) return knownDhikr;

    final name = value['name'];
    final category = value['category'];
    final defaultTarget = _intFromJson(value['defaultTarget']);
    if (name is! String ||
        name.isEmpty ||
        category is! String ||
        category.isEmpty ||
        defaultTarget == null) {
      return null;
    }

    final isBuiltIn = value['isBuiltIn'];

    return DhikrItem(
      id: id,
      name: name,
      category: category,
      defaultTarget: defaultTarget,
      arabicText: _nullableStringFromJson(value['arabicText']),
      meaning: _nullableStringFromJson(value['meaning']),
      longMeaning: _nullableStringFromJson(value['longMeaning']),
      isBuiltIn: isBuiltIn is bool ? isBuiltIn : false,
    );
  }

  DhikrItem? _knownDhikrById(String? id) {
    if (id == null) return null;

    for (final item in builtinDhikrs) {
      if (item.id == id) return item;
    }
    for (final item in esmaItems) {
      final dhikr = item.toDhikr();
      if (dhikr.id == id) return dhikr;
    }

    return null;
  }

  int? _intFromJson(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  String? _nullableStringFromJson(Object? value) {
    return value is String && value.isNotEmpty ? value : null;
  }
}

final counterControllerProvider =
    NotifierProvider<CounterController, CounterState>(CounterController.new);

class LastStartedDhikrIdController extends Notifier<String?> {
  static const storageKey = 'counter.lastStartedDhikrId';

  var _changedBeforeRestore = false;

  @override
  String? build() {
    Future.microtask(_restore);
    return null;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (_changedBeforeRestore) return;
    state = prefs.getString(storageKey);
  }

  void remember(String dhikrId) {
    state = dhikrId;
    _changedBeforeRestore = true;
    unawaited(_persist(dhikrId));
  }

  Future<void> _persist(String dhikrId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, dhikrId);
  }
}

final lastStartedDhikrIdProvider =
    NotifierProvider<LastStartedDhikrIdController, String?>(
      LastStartedDhikrIdController.new,
    );
