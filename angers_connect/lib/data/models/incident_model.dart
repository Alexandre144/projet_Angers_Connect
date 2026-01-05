class Incident {
  final int id;
  final String title;
  final double? lat;
  final double? lon;
  final Map<String, dynamic>? rawFields;

  const Incident({required this.id, required this.title, this.lat, this.lon, this.rawFields});

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

    return Incident(id: id, title: title, lat: lat, lon: lon, rawFields: fields);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (lat != null && lon != null) 'geo_point_2d': [lat, lon],
      };

  // Getters pratiques
  String? get description => rawFields?['description']?.toString();
  String? get address => rawFields?['address']?.toString();
  String? get startAt => rawFields?['startat']?.toString();
  String? get endAt => rawFields?['endat']?.toString();
  String? get traffic => rawFields?['traffic']?.toString();
  String? get contact => rawFields?['contact']?.toString();
  String? get email => rawFields?['email']?.toString();
  int? get isTramway => (rawFields?['istramway'] is int) ? rawFields!['istramway'] as int : (rawFields?['istramway'] != null ? int.tryParse('${rawFields!['istramway']}') : null);
  String? get idParking => rawFields?['idparking']?.toString();
  String? get image => rawFields?['image']?.toString();
  String? get imageText => rawFields?['imagetext']?.toString();
  String? get link => rawFields?['link']?.toString();
  String? get type => rawFields?['type']?.toString();
}
