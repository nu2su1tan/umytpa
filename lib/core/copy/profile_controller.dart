import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'copy_pack.dart';

/// Who the user is to the app: their name, the tone it speaks in, and when
/// they were last here. Remembered between launches.
class ProfileController extends ChangeNotifier {
  ProfileController._(
    this._prefs, {
    required String? name,
    required CopyTone tone,
    required bool asked,
    required this.previousOpen,
    required this.launchedAt,
  })  : _name = name,
        _tone = tone,
        _asked = asked;

  static const String _nameKey = 'profile_name';
  static const String _toneKey = 'profile_tone';
  static const String _askedKey = 'profile_asked';
  static const String _lastOpenKey = 'profile_last_open';

  /// A neutral profile for tests and previews.
  factory ProfileController.memory({
    String? name,
    CopyTone tone = CopyTone.friendly,
  }) =>
      ProfileController._(
        null,
        name: name,
        tone: tone,
        asked: true,
        previousOpen: null,
        launchedAt: DateTime.now(),
      );

  final SharedPreferences? _prefs;
  String? _name;
  CopyTone _tone;
  bool _asked;

  /// When the app was opened before this launch.
  final DateTime? previousOpen;
  final DateTime launchedAt;

  String? get name => _name;

  CopyTone get tone => _tone;

  /// Whether the "what should I call you" sheet has been shown.
  bool get asked => _asked;

  static Future<ProfileController> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? last = prefs.getInt(_lastOpenKey);
    final DateTime now = DateTime.now();
    final ProfileController controller = ProfileController._(
      prefs,
      name: prefs.getString(_nameKey),
      tone: CopyTone.values
              .where((CopyTone t) => t.name == prefs.getString(_toneKey))
              .firstOrNull ??
          CopyTone.friendly,
      asked: prefs.getBool(_askedKey) ?? false,
      previousOpen:
          last == null ? null : DateTime.fromMillisecondsSinceEpoch(last),
      launchedAt: now,
    );
    await prefs.setInt(_lastOpenKey, now.millisecondsSinceEpoch);
    return controller;
  }

  /// True for a little while after returning from 3+ days away.
  bool isComeback(DateTime now) {
    final DateTime? prev = previousOpen;
    return prev != null &&
        launchedAt.difference(prev) >= const Duration(days: 3) &&
        now.difference(launchedAt).abs() < const Duration(minutes: 30);
  }

  Future<void> setName(String? value) async {
    final String? clean =
        (value == null || value.trim().isEmpty) ? null : value.trim();
    if (clean == _name) {
      return;
    }
    _name = clean;
    notifyListeners();
    if (clean == null) {
      await _prefs?.remove(_nameKey);
    } else {
      await _prefs?.setString(_nameKey, clean);
    }
  }

  Future<void> setTone(CopyTone value) async {
    if (value == _tone) {
      return;
    }
    _tone = value;
    notifyListeners();
    await _prefs?.setString(_toneKey, value.name);
  }

  Future<void> markAsked() async {
    if (_asked) {
      return;
    }
    _asked = true;
    await _prefs?.setBool(_askedKey, true);
  }
}

/// Makes the profile available to the whole widget tree and rebuilds
/// dependents when the name or tone changes.
class ProfileScope extends InheritedNotifier<ProfileController> {
  const ProfileScope({
    required ProfileController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static final ProfileController _fallback = ProfileController.memory();

  static ProfileController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProfileScope>()?.notifier ??
      _fallback;
}

extension CopyContext on BuildContext {
  ProfileController get profile => ProfileScope.of(this);

  /// The voice lines for the current language and tone.
  CopyPack get copy => CopyPack.of(
        Localizations.localeOf(this).languageCode,
        ProfileScope.of(this).tone,
      );
}
