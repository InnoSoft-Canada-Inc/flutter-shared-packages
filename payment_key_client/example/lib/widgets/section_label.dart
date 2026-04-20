import 'package:flutter/material.dart';

/// Section heading used to group form areas (e.g. "Card details", "Session").
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ) ??
          const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}
