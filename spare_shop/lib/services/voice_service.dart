import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:developer' as developer;
import 'models.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;
  String _lastWords = '';

  void startListening(void Function(String) onResult) {
    if (!_listening) {
      bool available = _speech.initialize();
      if (available) {
        _listening = true;
        _speech.listen(
          onResult: (String result) => onResult(result),
          localeName: 'en-KE',
        );
      }
    }
  }

  void stopListening() {
    if (_listening) {
      _speech.stop();
      _listening = false;
    }
  }
}