import "dart:typed_data";

class Attachment {
  String? name;
  String? mime;
  Uint8List? bytes;
  Uint8List? thumbnail;

  Attachment({
    this.name,
    this.mime,
    this.bytes,
    this.thumbnail,
  });
}