class Incident {
  final int id;
  final String title;
  final double? lat;
  final double? lon;

  const Incident({required this.id, required this.title, this.lat, this.lon});

  factory Incident.fromJson(Map<String, dynamic> json) {
    final fields = json['fields'] is Map ? Map<String, dynamic>.from(json['fields']) : Map<String, dynamic>.from(json);

    final id = (fields['id'] is int) ? fields['id'] as int : int.tryParse('${fields['id']}') ?? 0;
    final title = (fields['title'] ?? '').toString();

    double? lat;
    double? lon;
    final gp = fields['geo_point_2d'];
    if (gp is List && gp.length >= 2) {
      lat = (gp[0] is num) ? (gp[0] as num).toDouble() : double.tryParse('${gp[0]}');
      lon = (gp[1] is num) ? (gp[1] as num).toDouble() : double.tryParse('${gp[1]}');
    }

    return Incident(id: id, title: title, lat: lat, lon: lon);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (lat != null && lon != null) 'geo_point_2d': [lat, lon],
      };
}
