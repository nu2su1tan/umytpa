// Consolidated localization export for the merged app
// This file re-exports the generated localization classes from the
// week_counter feature so that the rest of the codebase can import a
// single stable path.

export 'package:umytpa/features/week_counter/l10n/app_localizations.dart';
export 'package:umytpa/features/week_counter/l10n/app_localizations_en.dart';
export 'package:umytpa/features/week_counter/l10n/app_localizations_ru.dart';
export 'package:umytpa/features/week_counter/l10n/award_copy.dart';
export 'package:umytpa/features/week_counter/l10n/jokes.dart';
export 'package:umytpa/features/week_counter/l10n/labels.dart';
export 'package:umytpa/features/week_counter/l10n/country_names.dart';


// ignore_for_file: directives_ordering
import 'package:flutter/widgets.dart';
import 'package:umytpa/features/week_counter/l10n/app_localizations.dart';
import 'package:umytpa/features/week_counter/l10n/app_localizations_en.dart';

/// `context.l10n` — the current strings, English when no delegate is mounted
/// (e.g. a bare widget under test).
extension AppL10nContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsEn();
}
