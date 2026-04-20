import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Card showing success or error message (e.g. payment key result).
class ResultMessageCard extends StatelessWidget {
  const ResultMessageCard({
    super.key,
    required this.message,
    required this.isSuccess,
  });

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: isSuccess ? AppTokens.successSurface : AppTokens.errorSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: isSuccess ? AppTokens.success : AppTokens.error,
          width: 1,
        ),
      ),
      child: SelectableText(
        message,
        style: TextStyle(
          color: isSuccess
              ? AppTokens.successOnSurface
              : AppTokens.errorOnSurface,
        ),
      ),
    );
  }
}
