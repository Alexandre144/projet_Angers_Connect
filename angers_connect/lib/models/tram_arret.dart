class TramArret {
  final String stopId;
  final String stopCode;
  final String stopName;
  final double lon;
  final double lat;
  final String? stopDesc;
  final String? parentStation;
  final String stopTimezone;
  final bool accessible;
  final Set<String> routeShortNames; // lignes desservant cet arrêt

  TramArret({
    required this.stopId,
    required this.stopCode,
    required this.stopName,
    required this.lon,
    required this.lat,
    this.stopDesc,
    this.parentStation,
    required this.stopTimezone,
    required this.accessible,
    required this.routeShortNames,
  });

  factory TramArret.fromJson(Map<String, dynamic> json, [Set<String>? routeShortNames]) {
    final coords = json['stop_coordinates'] ?? {};
    return TramArret(
      stopId: json['stop_id'] ?? '',
      stopCode: json['stop_code'] ?? '',
      stopName: json['stop_name'] ?? '',
      lon: (coords['lon'] as num?)?.toDouble() ?? 0.0,
      lat: (coords['lat'] as num?)?.toDouble() ?? 0.0,
      stopDesc: json['stop_desc'],
      parentStation: json['parent_station'],
      stopTimezone: json['stop_timezone'] ?? '',
      accessible: (json['wheelchair_boarding'] ?? '') == '1',
      routeShortNames: routeShortNames ?? {},
    );
  }
}