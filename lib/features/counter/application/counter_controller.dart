import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/local/database_provider.dart';
import '../../../core/services/interaction_feedback_service.dart';
import '../../../core/services/app_services.dart';
import '../../dhikr_library/data/builtin_dhikrs.dart';
import '../../dhikr_library/domain/dhikr_item.dart';

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
  @override
  CounterState build() {
    final defaultDhikr = builtinDhikrs.first;
    return CounterState(
      activeDhikr: defaultDhikr,
      count: 0,
      target: defaultDhikr.defaultTarget,
    );
  }

  void startDhikr(DhikrItem dhikr, {int? target}) {
    state = CounterState(
      activeDhikr: dhikr,
      count: 0,
      target: target ?? dhikr.defaultTarget,
    );
    ref.read(lastStartedDhikrIdProvider.notifier).remember(dhikr.id);
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logEvent('counter_start', parameters: {'dhikr_id': dhikr.id}),
    );
  }

  void setTarget(int target) {
    state = state.copyWith(target: target, completed: false);
  }

  void increment() {
    if (!state.isInfinite && state.count >= state.target) return;

    final nextCount = state.count + 1;
    final completed = !state.isInfinite && nextCount >= state.target;
    state = state.copyWith(count: nextCount, completed: completed);

    final feedback = ref.read(interactionFeedbackServiceProvider);
    if (completed) {
      feedback.success();
    } else {
      feedback.selection();
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
}

final counterControllerProvider =
    NotifierProvider<CounterController, CounterState>(CounterController.new);

class LastStartedDhikrIdController extends Notifier<String?> {
  static const _storageKey = 'counter.lastStartedDhikrId';

  @override
  String? build() {
    Future.microtask(_restore);
    return null;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_storageKey);
  }

  void remember(String dhikrId) {
    state = dhikrId;
    unawaited(_persist(dhikrId));
  }

  Future<void> _persist(String dhikrId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, dhikrId);
  }
}

final lastStartedDhikrIdProvider =
    NotifierProvider<LastStartedDhikrIdController, String?>(
      LastStartedDhikrIdController.new,
    );
