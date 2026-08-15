import 'package:uuid/uuid.dart';

/// Service managing QR code payload formatting and verification
class QRService {
  final Uuid _uuid;

  QRService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  /// Generates a standardized QR payload for a registration
  String generateQRPayload(String registrationId) {
    final prefix = 'EASE';
    final randomPart = _uuid.v4().substring(0, 8);
    final idPart = registrationId.length > 8 ? registrationId.substring(0, 8) : registrationId;
    return '$prefix-$idPart-$randomPart';
  }

  /// Validates whether a scanned QR string matches the expected format
  bool isValidEventEaseQR(String rawPayload) {
    final trimmed = rawPayload.trim();
    return trimmed.startsWith('EASE-') || trimmed.length >= 8;
  }
}
