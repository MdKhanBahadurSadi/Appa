import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, paused, stopped }

class PdfTtsService {
  late FlutterTts _flutterTts;
  TtsState _ttsState = TtsState.stopped;

  Function(TtsState state)? onStateChanged;
  Function(int start, int end, String word)? onProgress;

  PdfTtsService() {
    init();
  }

  Future<void> init() async {
    _flutterTts = FlutterTts();

    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
      onStateChanged?.call(_ttsState);
    });

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
      onStateChanged?.call(_ttsState);
    });

    _flutterTts.setPauseHandler(() {
      _ttsState = TtsState.paused;
      onStateChanged?.call(_ttsState);
    });

    _flutterTts.setContinueHandler(() {
      _ttsState = TtsState.playing;
      onStateChanged?.call(_ttsState);
    });

    _flutterTts.setErrorHandler((msg) {
      _ttsState = TtsState.stopped;
      onStateChanged?.call(_ttsState);
    });

    _flutterTts.setProgressHandler((String text, int start, int end, String word) {
      onProgress?.call(start, end, word);
    });
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _flutterTts.speak(text);
  }

  Future<void> pause() async {
    await _flutterTts.pause();
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _ttsState = TtsState.stopped;
    onStateChanged?.call(_ttsState);
  }

  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  TtsState get state => _ttsState;
  
  void dispose() {
    _flutterTts.stop();
  }
}
