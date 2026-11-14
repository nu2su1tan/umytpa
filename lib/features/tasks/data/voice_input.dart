import 'package:speech_to_text/speech_to_text.dart';

/// Dictation for the quick-add line. Everything is best effort: when the
/// microphone or speech recognition is not allowed, [start] returns `false`
/// and the caller tells the user.
class VoiceInput {
  VoiceInput({SpeechToText? engine}) : _engine = engine ?? SpeechToText();

  final SpeechToText _engine;
  bool _ready = false;

  bool get isListening => _engine.isListening;

  static String _localeFor(String languageCode) => switch (languageCode) {
    'ru' => 'ru_RU',
    'kk' => 'kk_KZ',
    _ => 'en_US',
  };

  /// Starts listening. [onText] gets the recognised text so far; [onStopped]
  /// fires when listening ends on its own (silence, error or [stop]).
  Future<bool> start({
    required String languageCode,
    required void Function(String text, {required bool isFinal}) onText,
    required void Function() onStopped,
  }) async {
    try {
      if (!_ready) {
        _ready = await _engine.initialize(
          onStatus: (String status) {
            if (status == 'done' || status == 'notListening') {
              onStopped();
            }
          },
          onError: (_) => onStopped(),
        );
      }
      if (!_ready) {
        return false;
      }
      await _engine.listen(
        onResult: (result) =>
            onText(result.recognizedWords, isFinal: result.finalResult),
        listenOptions: SpeechListenOptions(
          localeId: _localeFor(languageCode),
          partialResults: true,
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 30),
        ),
      );
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _engine.stop();
    } on Object {
      // Already stopped.
    }
  }
}
