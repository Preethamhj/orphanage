import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  File? _file;
  String? _filePath;
  final ValueNotifier<List<String>> liveLogs = ValueNotifier<List<String>>(<String>[]);
  static const int _maxInMemoryLines = 300;

  String? get filePath => _filePath;

  Future<void> init() async {
    if (_file != null) return;
    final externalDir = await getExternalStorageDirectory();
    final baseDir = externalDir ?? await getApplicationDocumentsDirectory();
    final logsDir = Directory('${baseDir.path}/logs');
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    _filePath = '${logsDir.path}/app_events.txt';
    _file = File(_filePath!);
    if (!await _file!.exists()) {
      await _file!.create(recursive: true);
    }
    await log('logger_initialized', details: {'path': _filePath});
  }

  Future<void> log(String event, {Map<String, Object?>? details}) async {
    try {
      final file = _file;
      if (file == null) return;
      final ts = DateTime.now().toIso8601String();
      final payload = details == null ? '' : ' | $details';
      final line = '[$ts] $event$payload';
      await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
      final current = List<String>.from(liveLogs.value)..add(line);
      if (current.length > _maxInMemoryLines) {
        current.removeRange(0, current.length - _maxInMemoryLines);
      }
      liveLogs.value = current;
    } catch (_) {}
  }

  Future<void> logError(
    String event,
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?>? details,
  }) async {
    final data = <String, Object?>{
      if (details != null) ...details,
      'error': error.toString(),
      if (stackTrace != null) 'stack': stackTrace.toString(),
    };
    await log(event, details: data);
  }

  void clearLiveLogs() {
    liveLogs.value = <String>[];
  }
}
