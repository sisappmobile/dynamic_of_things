import "dart:typed_data";

class Attachment {
  String? name;
  String? mime;
  String? url;
  Uint8List? bytes;
  Uint8List? thumbnail;

  Attachment({
    this.name,
    this.mime,
    this.url,
    this.bytes,
    this.thumbnail,
  });
}
