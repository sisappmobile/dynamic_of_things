// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

class ListResponse {
  List<Chart> charts = [];

  ListResponse();

  factory ListResponse.fromJson(Map<String, dynamic> json) => ListResponse()
    ..charts = json["charts"] != null ? List<Chart>.from(json["charts"].map((e) {
      String type = e["type"];

      if (type == "Card") {
        return Summary.fromJson(e);
      } else if (type == "Bar Chart") {
        return Bar.fromJson(e);
      }
    }),) : [];
}

class Chart {
  late String id;
  late String title;
  late String type;
  late int size;

  Chart();

  factory Chart.fromJson(Map<String, dynamic> json) => Chart()
    ..id = json["id"]
    ..title = json["title"]
    ..type = json["type"]
    ..size = json["size"];
}

class Summary extends Chart {
  late String? icon;
  late String? color;

  Summary();

  factory Summary.fromJson(Map<String, dynamic> json) => Summary()
    ..id = json["id"]
    ..title = json["title"]
    ..type = json["type"]
    ..size = json["size"]
    ..icon = json["icon"]
    ..color = json["color"];
}

class Bar extends Chart {
  late String xLabel;
  late String yLabel;

  Bar();

  factory Bar.fromJson(Map<String, dynamic> json) => Bar()
    ..id = json["id"]
    ..title = json["title"]
    ..type = json["type"]
    ..size = json["size"]
    ..xLabel = json["xLabel"]
    ..yLabel = json["yLabel"];
}