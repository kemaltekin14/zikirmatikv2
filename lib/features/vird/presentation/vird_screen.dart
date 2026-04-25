import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local/database_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';

class VirdStep {
  const VirdStep({
    required this.title,
    required this.text,
    required this.target,
  });

  final String title;
  final String text;
  final int target;
}

const _virdId = 'daily-basic-vird';
const _virdSteps = [
  VirdStep(title: 'İstiğfar', text: 'Estağfirullah', target: 100),
  VirdStep(
    title: 'Salavat',
    text: 'Allahümme salli ala seyyidina Muhammed',
    target: 100,
  ),
  VirdStep(title: 'Tevhid', text: 'La ilahe illallah', target: 100),
];

class VirdScreen extends ConsumerStatefulWidget {
  const VirdScreen({super.key});

  @override
  ConsumerState<VirdScreen> createState() => _VirdScreenState();
}

class _VirdScreenState extends ConsumerState<VirdScreen> {
  int _stepIndex = 0;
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final step = _virdSteps[_stepIndex];

    return AppScaffold(
      title: 'Vird programı',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Günlük vird placeholder',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(step.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(step.text),
          const SizedBox(height: 24),
          LinearProgressIndicator(value: _count / step.target),
          const SizedBox(height: 12),
          Text('$_count / ${step.target}', textAlign: TextAlign.center),
          const Spacer(),
          FilledButton(onPressed: _increment, child: const Text('Say')),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => setState(() {
              _stepIndex = 0;
              _count = 0;
            }),
            child: const Text('Baştan başlat'),
          ),
        ],
      ),
    );
  }

  void _increment() {
    final step = _virdSteps[_stepIndex];
    setState(() {
      if (_count + 1 >= step.target) {
        if (_stepIndex < _virdSteps.length - 1) {
          _stepIndex += 1;
          _count = 0;
        } else {
          _count = step.target;
        }
      } else {
        _count += 1;
      }
    });
    unawaited(
      ref
          .read(appDatabaseProvider)
          .upsertVirdProgress(
            virdId: _virdId,
            stepIndex: _stepIndex,
            count: _count,
            target: _virdSteps[_stepIndex].target,
          ),
    );
  }
}
