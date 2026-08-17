import 'dart:async';
import 'package:flutter/foundation.dart';
import 'qr_image_decoder_stub.dart'
    if (dart.library.html) 'qr_image_decoder_web.dart' as platform_decoder;

class QrImageDecoder {
  QrImageDecoder._();

  static Future<String?> decodeFromBytes(Uint8List bytes) async {
    if (kIsWeb) {
      return platform_decoder.decodeQrFromBytes(bytes);
    }
    return null;
  }
}
