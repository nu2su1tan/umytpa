import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quick_actions/quick_actions.dart';

/// Ways to start adding a task from outside the app.
enum EntryKind {
  /// Home-screen shortcut or the widget's "+": open the new-task form.
  newTask,

  /// Text shared from another app: open the form with it filled in.
  share,

  /// Spoken to Siri: add the task right away.
  add,
}

class ExternalEntry {
  const ExternalEntry(this.kind, [this.text]);

  final EntryKind kind;
  final String? text;
}

/// Receives "add a task" requests from shortcuts, the share sheet, Siri and
/// the Android widget. The page that handles them listens to [pending]; an
/// entry that arrives before the page exists simply waits there.
abstract final class ExternalEntries {
  static const MethodChannel _channel = MethodChannel('umytpa/entry');
  static const String _newTaskShortcut = 'new_task';

  static final ValueNotifier<ExternalEntry?> pending =
      ValueNotifier<ExternalEntry?>(null);

  static bool _started = false;

  /// [newTaskLabel] is the shortcut's title in the user's language.
  static Future<void> start({required String newTaskLabel}) async {
    if (_started || !(Platform.isIOS || Platform.isAndroid)) {
      return;
    }
    _started = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'changed') {
        await pull();
      }
    });
    try {
      final QuickActions quick = const QuickActions();
      await quick.initialize((String type) {
        if (type == _newTaskShortcut) {
          pending.value = const ExternalEntry(EntryKind.newTask);
        }
      });
      await quick.setShortcutItems(<ShortcutItem>[
        ShortcutItem(
          type: _newTaskShortcut,
          localizedTitle: newTaskLabel,
          icon: Platform.isIOS ? 'UIApplicationShortcutIconTypeAdd' : null,
        ),
      ]);
    } on Object {
      // Shortcuts are a convenience.
    }
    await pull();
  }

  /// Asks the platform whether something is waiting (share, widget, Siri).
  static Future<void> pull() async {
    try {
      final Map<Object?, Object?>? raw =
          await _channel.invokeMapMethod<Object?, Object?>('take');
      if (raw == null) {
        return;
      }
      final String? text = (raw['text'] as String?)?.trim();
      final ExternalEntry? entry = switch (raw['kind']) {
        'new' => const ExternalEntry(EntryKind.newTask),
        'share' when text != null && text.isNotEmpty =>
          ExternalEntry(EntryKind.share, text),
        'add' when text != null && text.isNotEmpty =>
          ExternalEntry(EntryKind.add, text),
        _ => null,
      };
      if (entry != null) {
        pending.value = entry;
      }
    } on Object {
      // No native side (tests, desktop): nothing is waiting.
    }
  }

  /// Marks the waiting entry as handled.
  static ExternalEntry? consume() {
    final ExternalEntry? entry = pending.value;
    pending.value = null;
    return entry;
  }
}
