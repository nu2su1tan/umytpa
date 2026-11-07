import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/greeting.dart';

class TasksHeader extends StatelessWidget {
  const TasksHeader({required this.now, super.key});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String dateLabel = DateFormat('EEEE, d MMMM').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          dateLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Greeting.forTime(now),
          style: theme.textTheme.headlineLarge,
        ),
      ],
    );
  }
}
