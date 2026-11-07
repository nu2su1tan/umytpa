import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../week_counter/ui/kit/buttons.dart';
import '../../../week_counter/ui/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../utils/task_l10n.dart';

class TasksErrorView extends StatelessWidget {
  const TasksErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPadding * 1.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: t.danger.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 30, color: t.danger),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.errorTitle,
              style: t.navTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(context.l10n.domainMessage(message), style: t.callout, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            AppButton(label: context.l10n.retry, onTap: onRetry, expand: false),
          ],
        ),
      ),
    );
  }
}
