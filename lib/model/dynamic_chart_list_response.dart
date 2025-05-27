// ignore_for_file: always_put_required_named_parameters_first, always_specify_types

class ListResponse {
  final List<Chart> charts;

  ListResponse({
    required this.charts,
  });

  factory ListResponse.fromJson(Map<String, dynamic> json) => ListResponse(
    charts: json["charts"] != null ? List<Chart>.from(
      json["charts"].map((e) {
        String type = e["type"];

        if (type == "Card") {
          return Summary.fromJson(e);
        } else if (type == "Bar Chart") {
          return Bar.fromJson(e);
        }
      }),
    ) : [],
  );
}

class Chart {
  final String id;
  final String title;
  final String type;
  final int size;

  Chart({
    required this.id,
    required this.title,
    required this.type,
    required this.size,
  });

  factory Chart.fromJson(Map<String, dynamic> json) => Chart(
    id: json["id"],
    title: json["title"],
    type: json["type"],
    size: json["size"],
  );
}

class Summary extends Chart {
  final String? icon;
  final String? color;

  Summary({
    required super.id,
    required super.title,
    required super.type,
    required super.size,
    required this.icon,
    required this.color,
  });

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
    id: json["id"],
    title: json["title"],
    type: json["type"],
    size: json["size"],
    icon: json["icon"],
    color: json["color"],
  );
}

class Bar extends Chart {
  final String xLabel;
  final String yLabel;

  Bar({
    required super.id,
    required super.title,
    required super.type,
    required super.size,
    required this.xLabel,
    required this.yLabel,
  });

  factory Bar.fromJson(Map<String, dynamic> json) => Bar(
    id: json["id"],
    title: json["title"],
    type: json["type"],
    size: json["size"],
    xLabel: json["xLabel"],
    yLabel: json["yLabel"],
  );
}
