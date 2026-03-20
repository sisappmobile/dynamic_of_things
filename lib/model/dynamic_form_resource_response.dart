import "package:dynamic_of_things/helper/formats.dart";

class DynamicFormResourceResponse {
  late String key;
  List<DynamicFormResourceFieldItem> fields = [];
  List<DynamicFormResourceDetailSetupItem> detailSetups = [];
  List<DynamicFormResourceLoadOnFieldItem> loadOnFields = [];

  DynamicFormResourceResponse();

  factory DynamicFormResourceResponse.fromJson(Map<String, dynamic> json) => DynamicFormResourceResponse()
    ..key = json["key"]
    ..fields = json["fields"] != null ? List<DynamicFormResourceFieldItem>.from(json["fields"].map((e) => DynamicFormResourceFieldItem.fromJson(e))) : []
    ..detailSetups = json["detailSetups"] != null ? List<DynamicFormResourceDetailSetupItem>.from(json["detailSetups"].map((e) => DynamicFormResourceDetailSetupItem.fromJson(e))) : []
    ..loadOnFields = json["loadOnFields"] != null ? List<DynamicFormResourceLoadOnFieldItem>.from(json["loadOnFields"].map((e) => DynamicFormResourceLoadOnFieldItem.fromJson(e))) : [];
}

class DynamicFormResourceDetailSetupItem {
  late String srcKey;
  late String dstKey;

  DynamicFormResourceDetailSetupItem();

  factory DynamicFormResourceDetailSetupItem.fromJson(Map<String, dynamic> json) => DynamicFormResourceDetailSetupItem()
    ..srcKey = json["srcKey"] ?? ""
    ..dstKey = json["dstKey"] ?? "";
}

class DynamicFormResourceFieldItem {
  late String name;
  late String type;
  late String description;
  late bool showed;

  DynamicFormResourceFieldItem();

  factory DynamicFormResourceFieldItem.fromJson(Map<String, dynamic> json) => DynamicFormResourceFieldItem()
    ..name = json["name"] ?? ""
    ..type = json["type"] ?? ""
    ..description = json["description"] ?? ""
    ..showed = Formats.tryParseBool(json["showed"]);
}

class DynamicFormResourceLoadOnFieldItem {
  late bool detail;
  late String source;
  late String target;

  DynamicFormResourceLoadOnFieldItem();

  factory DynamicFormResourceLoadOnFieldItem.fromJson(Map<String, dynamic> json) => DynamicFormResourceLoadOnFieldItem()
    ..detail = json["detail"] ?? false
    ..source = json["source"] ?? ""
    ..target = json["target"] ?? "";
}