import "dart:typed_data";

class Attachment {
  String? id;
  Uint8List? bytes;
  Uint8List? thumbnail;

  Attachment({
    this.id,
    this.bytes,
    this.thumbnail,
  });
}