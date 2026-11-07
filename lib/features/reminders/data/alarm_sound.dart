import 'dart:io';

import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The sound a task alarm plays: the one bundled with the app, or a file the
/// user picked on their device.
///
/// Read from storage each time (not cached) because the notification button
/// handlers run in a separate isolate and must see the same choice.
class AlarmSound {
  const AlarmSound({this.fileName, this.label});

  /// Built-in sound.
  static const AlarmSound builtIn = AlarmSound();

  static const String _fileKey = 'alarm_sound_file';
  static const String _labelKey = 'alarm_sound_label';

  static const List<String> allowedExtensions = <String>[
    'mp3',
    'm4a',
    'opus',
    'wav',
    'aiff',
    'aif',
    'caf',
    'ogg',
    'aac',
  ];

  /// iOS plays notification sounds only from these formats, so the rest are
  /// converted to CAF (see `AppDelegate.convertToCaf`).
  static const Set<String> _iosNative = <String>{'wav', 'aiff', 'aif', 'caf'};

  static const MethodChannel _audio = MethodChannel('umytpa/audio');

  /// Name of the copied file; `null` for the built-in sound.
  final String? fileName;

  /// What the user sees: the original file name.
  final String? label;

  bool get isCustom => fileName != null;

  /// Android channels are immutable, so each custom sound gets its own.
  String get androidChannelId => 'task_alarm_c_${fileName.hashCode.abs()}';

  static Future<AlarmSound> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final String? file = prefs.getString(_fileKey);
    if (file == null || !File(await _pathFor(file)).existsSync()) {
      return builtIn;
    }
    return AlarmSound(fileName: file, label: prefs.getString(_labelKey));
  }

  /// Full path of the copied file.
  Future<String?> path() async =>
      fileName == null ? null : _pathFor(fileName!);

  /// iOS looks for notification sounds in `Library/Sounds`.
  static Future<String> _pathFor(String file) async {
    final Directory base = Platform.isIOS
        ? Directory('${(await getLibraryDirectory()).path}/Sounds')
        : Directory('${(await getApplicationSupportDirectory()).path}/sounds');
    if (!base.existsSync()) {
      await base.create(recursive: true);
    }
    return '${base.path}/$file';
  }

  /// Lets the user choose a file, copies it into the app and remembers it.
  /// Returns `null` when they cancel.
  static Future<AlarmSound?> pick() async {
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    final String? source = picked.isEmpty ? null : picked.first.path;
    if (source == null) {
      return null;
    }
    String extension = source.split('.').last.toLowerCase();
    final bool convert = Platform.isIOS && !_iosNative.contains(extension);
    if (convert) {
      extension = 'caf';
    }
    // A new name each time, so the system never plays an older cached copy.
    final String stored =
        'alarm_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final String target = await _pathFor(stored);
    if (convert) {
      await _audio.invokeMethod<bool>(
        'toCaf',
        <String, String>{'source': source, 'target': target},
      );
    } else {
      await File(source).copy(target);
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? old = prefs.getString(_fileKey);
    await prefs.setString(_fileKey, stored);
    await prefs.setString(_labelKey, picked.first.name);
    if (old != null) {
      await _delete(old);
    }
    return AlarmSound(fileName: stored, label: picked.first.name);
  }

  /// Goes back to the built-in sound.
  static Future<void> reset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? old = prefs.getString(_fileKey);
    await prefs.remove(_fileKey);
    await prefs.remove(_labelKey);
    if (old != null) {
      await _delete(old);
    }
  }

  static Future<void> _delete(String file) async {
    final File f = File(await _pathFor(file));
    if (f.existsSync()) {
      await f.delete();
    }
  }
}
