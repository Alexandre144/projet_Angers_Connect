class TramLine {
  final String routeId;
  final String routeShortName;
  final String routeLongName;
  final String routeColor;
  final String routeType;
  final List<List<List<double>>> shapeCoordinates;
  final List<double> geoPoint;

  TramLine({
    required this.routeId,
    required this.routeShortName,
    required this.routeLongName,
    required this.routeColor,
    required this.routeType,
    required this.shapeCoordinates,
    required this.geoPoint,
  });

  factory TramLine.fromJson(Map<String, dynamic> json) {
    final fields = json['fields'] ?? {};
    final shape = fields['shape']?['coordinates'] ?? [];
    final geoPoint = List<double>.from(fields['geo_point_2d'] ?? []);
    return TramLine(
      routeId: fields['route_id'] ?? '',
      routeShortName: fields['route_short_name'] ?? '',
      routeLongName: fields['route_long_name'] ?? '',
      routeColor: fields['route_color'] ?? '',
      routeType: fields['route_type'] ?? '',
      shapeCoordinates: shape is List
          ? (shape as List)
              .map<List<List<double>>>((l) => (l as List)
                  .map<List<double>>((ll) => (ll as List)
                      .map<double>((v) => v.toDouble())
                      .toList())
                  .toList())
              .toList()
          : [],
      geoPoint: geoPoint,
    );
  }
}