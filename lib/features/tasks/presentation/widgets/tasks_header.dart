import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../week_counter/ui/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../utils/task_l10n.dart';

/// Date eyebrow and a large greeting, in the same type as the Week screens.
class TasksHeader extends StatelessWidget {
  const TasksHeader({required this.now, super.key});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final String dateLabel = DateFormat('EEEE, d MMMM', context.l10n.localeName).format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          dateLabel,
          style: t.callout.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Semantics(
          header: true,
          child: Text(context.l10n.greeting(now), style: t.largeTitle),
        ),
      ],
    );
  }
}
