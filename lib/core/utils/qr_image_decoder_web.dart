// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

Future<String?> decodeQrFromBytes(Uint8List bytes) async {
  try {
    final base64String = base64Encode(bytes);
    final completer = Completer<String?>();
    final jsPromise = js.context.callMethod('decodeQrFromImageData', [base64String]);
    if (jsPromise != null) {
      jsPromise.callMethod('then', [
        (dynamic result) {
          if (!completer.isCompleted) {
            if (result != null && result is String && result.isNotEmpty) {
              completer.complete(result);
            } else {
              completer.complete(null);
            }
          }
        },
        (dynamic err) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        }
      ]);
      return await completer.future.timeout(const Duration(seconds: 4), onTimeout: () => null);
    }
  } catch (e) {
    debugPrint('Web QR Decode Error: $e');
  }
  return null;
}
