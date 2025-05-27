class DynamicFormResourceResponse {
  final List<DynamicFormResourceFieldItem> fields;
  final List<Map<String, dynamic>> data;
  final List<DynamicFormResourceDetailSetupItem> detailSetups;
  final List<DynamicFormResourceLoadOnFieldItem> loadOnFields;

  DynamicFormResourceResponse({
    required this.fields,
    required this.data,
    required this.detailSetups,
    required this.loadOnFields,
  });

  factory DynamicFormResourceResponse.fromJson(Map<String, dynamic> json) => DynamicFormResourceResponse(
    fields: json["fields"] != null ? List<DynamicFormResourceFieldItem>.from(json["fields"].map((e) => DynamicFormResourceFieldItem.fromJson(e))) : [],
    data: json["data"] != null ? List<Map<String, dynamic>>.from(json["data"].map((e) => e)) : [],
    detailSetups: json["detailSetups"] != null ? List<DynamicFormResourceDetailSetupItem>.from(json["detailSetups"].map((e) => DynamicFormResourceDetailSetupItem.fromJson(e))) : [],
    loadOnFields: json["loadOnFields"] != null ? List<DynamicFormResourceLoadOnFieldItem>.from(json["loadOnFields"].map((e) => DynamicFormResourceLoadOnFieldItem.fromJson(e))) : [],
  );
}

class DynamicFormResourceDetailSetupItem {
  final String srcKey;
  final String dstKey;

  DynamicFormResourceDetailSetupItem({
    required this.srcKey,
    required this.dstKey,
  });

  factory DynamicFormResourceDetailSetupItem.fromJson(Map<String, dynamic> json) => DynamicFormResourceDetailSetupItem(
    srcKey: json["srcKey"] ?? "",
    dstKey: json["dstKey"] ?? "",
  );
}

class DynamicFormResourceFieldItem {
  final String name;
  final String type;
  final String description;
  final bool primaryKey;

  DynamicFormResourceFieldItem({
    required this.name,
    required this.type,
    required this.description,
    required this.primaryKey,
  });

  factory DynamicFormResourceFieldItem.fromJson(Map<String, dynamic> json) => DynamicFormResourceFieldItem(
    name: json["name"] ?? "",
    type: json["type"] ?? "",
    description: json["description"] ?? "",
    primaryKey: json["primaryKey"] ?? false,
  );
}

class DynamicFormResourceLoadOnFieldItem {
  final bool detail;
  final String source;
  final String target;

  DynamicFormResourceLoadOnFieldItem({
    required this.detail,
    required this.source,
    required this.target,
  });

  factory DynamicFormResourceLoadOnFieldItem.fromJson(Map<String, dynamic> json) => DynamicFormResourceLoadOnFieldItem(
    detail: json["detail"] ?? false,
    source: json["source"] ?? "",
    target: json["target"] ?? "",
  );
}