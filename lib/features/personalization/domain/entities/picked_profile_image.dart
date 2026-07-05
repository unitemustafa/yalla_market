import 'dart:typed_data';

class PickedProfileImage {
  const PickedProfileImage({
    required this.bytes,
    required this.fileName,
    this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String? mimeType;
}
