import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../week_counter/ui/theme/tokens.dart';

/// Asks for any "remind me N minutes/hours/days before" value.
Future<Duration?> showCustomReminderDialog(
  BuildContext context,
  Duration? initial,
) {
  return showDialog<Duration>(
    context: context,
    builder: (BuildContext _) => _CustomReminderDialog(initial: initial),
  );
}

class _CustomReminderDialog extends StatefulWidget {
  const _CustomReminderDialog({this.initial});

  final Duration? initial;

  @override
  State<_CustomReminderDialog> createState() => _CustomReminderDialogState();
}

class _CustomReminderDialogState extends State<_CustomReminderDialog> {
  static const List<int> _perUnit = <int>[1, 60, 1440];
  static const List<int> _maxAmount = <int>[10080, 168, 60];

  late final TextEditingController _controller;
  late int _unit;

  @override
  void initState() {
    super.initState();
    final int minutes = widget.initial?.inMinutes ?? 15;
    final bool days = minutes >= 1440 && minutes % 1440 == 0;
    final bool hours = !days && minutes >= 60 && minutes % 60 == 0;
    _unit = days ? 2 : (hours ? 1 : 0);
    final int amount =
        days ? minutes ~/ 1440 : (hours ? minutes ~/ 60 : minutes);
    _controller = TextEditingController(text: '$amount');
  }

  // Owned by the State so it lives exactly as long as the field does,
  // including the dialog's closing animation.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _value => int.tryParse(_controller.text);

  bool get _valid {
    final int? v = _value;
    return v != null && v >= 1 && v <= _maxAmount[_unit];
  }

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final AppLocalizations l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.customReminderTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            style: t.sectionTitle,
            decoration: InputDecoration(hintText: l10n.customReminderHint),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (final (int i, String label) in <String>[
                l10n.unitMinutes,
                l10n.unitHours,
                l10n.unitDays,
              ].indexed)
                ChoiceChip(
                  label: Text(label),
                  selected: _unit == i,
                  onSelected: (_) => setState(() => _unit = i),
                ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.of(context).pop(
                    Duration(minutes: _value! * _perUnit[_unit]),
                  )
              : null,
          child: Text(l10n.customReminderApply),
        ),
      ],
    );
  }
}
