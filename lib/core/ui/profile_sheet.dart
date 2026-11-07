import 'package:flutter/material.dart';

import '../../features/reminders/domain/usecases/reschedule_all_reminders.dart';
import '../../features/week_counter/ui/kit/glass.dart';
import '../../features/week_counter/ui/kit/group.dart';
import '../../features/week_counter/ui/kit/sheet.dart';
import '../../features/week_counter/ui/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../copy/copy_pack.dart';
import '../copy/profile_controller.dart';
import '../di/injection.dart';

/// Opens the sheet with the name field and the choice of tone.
/// [welcome] is the first-launch version.
Future<void> showProfileSheet(BuildContext context, {bool welcome = false}) {
  return showAppSheet<void>(
    context,
    title: welcome
        ? context.l10n.profileWelcomeTitle
        : context.l10n.profileTitle,
    builder: (_) => _ProfileForm(welcome: welcome),
  );
}

/// Round glass button that opens the sheet; used in screen headers.
class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      icon: Icons.face_rounded,
      label: context.l10n.profileButton,
      onTap: () => showProfileSheet(context),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.welcome});

  final bool welcome;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final ProfileController _profile = getIt<ProfileController>();
  late final TextEditingController _name =
      TextEditingController(text: _profile.name ?? '');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final NavigatorState navigator = Navigator.of(context);
    await _profile.setName(_name.text);
    await _profile.markAsked();
    // Notification wording depends on the name and tone.
    await getIt<RescheduleAllReminders>()();
    if (navigator.mounted) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Tokens t = context.tokens;
    final AppLocalizations l10n = context.l10n;
    return ListenableBuilder(
      listenable: _profile,
      builder: (BuildContext context, Widget? _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (widget.welcome) ...<Widget>[
              Text(
                l10n.profileWelcomeBody,
                style: t.callout.copyWith(color: t.ink2),
              ),
              const SizedBox(height: 14),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: t.sheetCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _name,
                maxLength: 24,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                style: t.body,
                decoration: InputDecoration(
                  labelText: l10n.profileNameLabel,
                  hintText: l10n.profileNameHint,
                  counterText: '',
                ),
                onSubmitted: (_) => _finish(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.profileToneTitle,
              style: t.footnote.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Group(
              margin: EdgeInsets.zero,
              color: t.sheetCard,
              children: <Widget>[
                for (final CopyTone tone in CopyTone.values)
                  GroupRow(
                    icon: switch (tone) {
                      CopyTone.friendly => Icons.emoji_emotions_rounded,
                      CopyTone.calm => Icons.spa_rounded,
                      CopyTone.coach => Icons.sports_rounded,
                    },
                    title: switch (tone) {
                      CopyTone.friendly => l10n.toneFriendly,
                      CopyTone.calm => l10n.toneCalm,
                      CopyTone.coach => l10n.toneCoach,
                    },
                    subtitle: switch (tone) {
                      CopyTone.friendly => l10n.toneFriendlyDesc,
                      CopyTone.calm => l10n.toneCalmDesc,
                      CopyTone.coach => l10n.toneCoachDesc,
                    },
                    selected: _profile.tone == tone,
                    onTap: () => _profile.setTone(tone),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _finish,
              child: Text(l10n.profileDone),
            ),
          ],
        );
      },
    );
  }
}
