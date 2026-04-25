import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget child;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), leading: leading, actions: actions),
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
