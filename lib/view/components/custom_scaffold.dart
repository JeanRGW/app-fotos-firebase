import 'package:flutter/material.dart';

class CustomScaffold extends StatelessWidget {
  final Widget body;
  final bool returnToPrevious;
  final String? title;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final bool hasAppBar;
  final PreferredSizeWidget? appBar;

  const CustomScaffold({
    super.key,
    required this.body,
    this.returnToPrevious = false,
    this.title,
    this.floatingActionButton,
    this.actions,
    this.hasAppBar = true,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          appBar ??
          (hasAppBar
              ? AppBar(
                  title: Text(title ?? 'Custom Scaffold'),
                  centerTitle: true,
                  leading: returnToPrevious
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        )
                      : null,
                  actions: actions,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                )
              : null),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
