import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/injection.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../reminders/domain/reminder_scheduler.dart';
import '../../../week_counter/ui/kit/pressable.dart';
import '../../../week_counter/ui/theme/tokens.dart';
import '../../data/voice_input.dart';
import '../../domain/usecases/parse_smart_input.dart';
import '../../domain/usecases/quick_times.dart';
import '../utils/task_l10n.dart';

/// One line to add a task: type (or dictate) "Call mom in 20 min", press
/// send. Several lines make several tasks. Shows how the text was read while
/// you type, and offers one-tap times.
class QuickAddBar extends StatefulWidget {
  const QuickAddBar({required this.onSubmit, this.initialText, super.key});

  /// Creates the tasks; returns how many were made and the first error.
  final Future<({int created, String? error})> Function(
    String text,
    QuickTimeKind? time,
  )
  onSubmit;
  final String? initialText;

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<QuickAddBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  final VoiceInput _voice = VoiceInput();
  QuickTimeKind? _time;
  bool _listening = false;
  bool _busy = false;
  bool _permissionAsked = false;
  String _textBeforeVoice = '';

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialText ?? '';
    _controller.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    unawaited(_voice.stop());
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String text = _controller.text.trim();
    if (text.isEmpty || _busy) {
      return;
    }
    setState(() => _busy = true);
    if (_listening) {
      await _voice.stop();
    }
    await _askNotificationsOnce();
    final ({int created, String? error}) result = await widget.onSubmit(
      text,
      _time,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _listening = false;
      if (result.created > 0) {
        _controller.clear();
        _time = null;
      }
    });
    final AppLocalizations l10n = context.l10n;
    final String? message = result.error != null
        ? l10n.domainMessage(result.error!)
        : (result.created > 1 ? l10n.quickAddedCount(result.created) : null);
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
    if (result.created > 0) {
      unawaited(HapticFeedback.lightImpact());
    }
  }

  /// Reminders need the notification permission; ask once, the first time.
  Future<void> _askNotificationsOnce() async {
    if (_permissionAsked) {
      return;
    }
    _permissionAsked = true;
    try {
      final ReminderScheduler scheduler = getIt<ReminderScheduler>();
      if (!(await scheduler.checkNotificationsPermission()).isGranted) {
        await scheduler.requestNotificationsPermission();
      }
    } on Object {
      // Not being able to ask must not block adding the task.
    }
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _voice.stop();
      if (mounted) {
        setState(() => _listening = false);
      }
      return;
    }
    _textBeforeVoice = _controller.text.trim();
    final bool ok = await _voice.start(
      languageCode: context.l10n.localeName,
      onText: (String words, {required bool isFinal}) {
        if (!mounted) {
          return;
        }
        final String joined = _textBeforeVoice.isEmpty
            ? words
            : '$_textBeforeVoice $words';
        _controller.value = TextEditingValue(
          text: joined,
          selection: TextSelection.collapsed(offset: joined.length),
        );
      },
      onStopped: () {
        if (mounted) {
          setState(() => _listening = false);
        }
      },
    );
    if (!mounted) {
      return;
    }
    if (ok) {
      setState(() => _listening = true);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.quickVoiceUnavailable)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final AppLocalizations l10n = context.l10n;
    final DateTime now = DateTime.now();
    final String text = _controller.text;
    final bool hasText = text.trim().isNotEmpty;
    final bool firstLineOnly = !text.trim().contains('\n');
    final SmartInput smart = SmartInputParser.parse(text, now: now);
    final String summary = hasText && firstLineOnly && smart.found
        ? l10n.smartSummary(smart, now: now)
        : '';
    final bool expanded = _focus.hasFocus || hasText;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 480,
                  style: t.callout,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => unawaited(_submit()),
                  decoration: InputDecoration(
                    hintText: l10n.quickAddHint,
                    hintStyle: t.callout.copyWith(color: t.ink2),
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.quickVoice,
                onPressed: _busy ? null : () => unawaited(_toggleVoice()),
                icon: Icon(
                  _listening
                      ? Icons.stop_circle_rounded
                      : Icons.mic_none_rounded,
                  color: _listening ? t.danger : t.ink2,
                ),
              ),
              if (hasText)
                IconButton(
                  tooltip: l10n.addTask,
                  onPressed: _busy ? null : () => unawaited(_submit()),
                  icon: Icon(Icons.arrow_upward_rounded, color: t.violetInk),
                  style: IconButton.styleFrom(backgroundColor: t.violetSoft),
                ),
            ],
          ),
          if (summary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 8),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: t.violetInk,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      summary,
                      style: t.footnote.copyWith(
                        color: t.violetInk,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 10, right: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final QuickTimeKind kind in QuickTimes.available(now))
                    _TimeChip(
                      label: l10n.quickTimeLabel(kind),
                      selected: _time == kind,
                      onTap: () =>
                          setState(() => _time = _time == kind ? null : kind),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    return Pressable(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: selected ? t.violetSoft : t.surface2,
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: t.footnote.copyWith(
            color: selected ? t.violetInk : t.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
