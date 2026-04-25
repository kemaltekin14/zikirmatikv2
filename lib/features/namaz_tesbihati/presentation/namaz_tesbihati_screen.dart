import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class TesbihatStep {
  const TesbihatStep({
    required this.title,
    required this.text,
    required this.target,
  });

  final String title;
  final String text;
  final int target;
}

const _steps = [
  TesbihatStep(title: 'Subhanallah', text: 'سبحان الله', target: 33),
  TesbihatStep(title: 'Elhamdulillah', text: 'الحمد لله', target: 33),
  TesbihatStep(title: 'Allahu Ekber', text: 'الله أكبر', target: 33),
];

class NamazTesbihatiScreen extends StatefulWidget {
  const NamazTesbihatiScreen({super.key});

  @override
  State<NamazTesbihatiScreen> createState() => _NamazTesbihatiScreenState();
}

class _NamazTesbihatiScreenState extends State<NamazTesbihatiScreen> {
  int _stepIndex = 0;
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];
    final isLastStep = _stepIndex == _steps.length - 1;

    return AppScaffold(
      title: 'Namaz tesbihati',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Adım ${_stepIndex + 1}/${_steps.length}'),
          const SizedBox(height: 12),
          Text(step.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(step.text, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          LinearProgressIndicator(value: _count / step.target),
          const SizedBox(height: 12),
          Text('$_count / ${step.target}', textAlign: TextAlign.center),
          const Spacer(),
          FilledButton(
            onPressed: () {
              setState(() {
                if (_count + 1 >= step.target) {
                  if (isLastStep) {
                    _count = step.target;
                  } else {
                    _stepIndex += 1;
                    _count = 0;
                  }
                } else {
                  _count += 1;
                }
              });
            },
            child: const Text('Say'),
          ),
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
}
