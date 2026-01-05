import 'package:latlong2/latlong.dart';

class ParkingVoiture {
  final String nom;
  final String disponible;
  final LatLng position;

  const ParkingVoiture(
    this.nom,
    this.disponible,
    this.position,
  );

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'disponible': disponible,
      'lon': position.longitude,
      'lat': position.latitude,
    };
  }

  factory ParkingVoiture.fromJson(Map<String, dynamic> json) {
    final geo = json['geo_point_2d'];
    double lat = 0.0;
    double lon = 0.0;
    if (geo is Map<String, dynamic>) {
      lat = (geo['lat'] as num?)?.toDouble() ?? 0.0;
      lon = (geo['lon'] as num?)?.toDouble() ?? 0.0;
    }
    return ParkingVoiture(
      json['nom'] as String? ?? '',
      json['disponible'] as String? ?? '',
      LatLng(lat, lon),
    );
  }
}