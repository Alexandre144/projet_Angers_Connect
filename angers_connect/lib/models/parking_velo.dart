import 'package:latlong2/latlong.dart';

class ParkingVelo {
  final String nomParkng;
  final String capacite;
  final String acces;
  final String dateMaj;
  final LatLng position;

  const ParkingVelo(
    this.nomParkng,
    this.capacite,
    this.acces,
    this.dateMaj,
    this.position,
  );

  Map<String, dynamic> toJson() {
    return {
      'nom_parkng': nomParkng,
      'capacite': capacite,
      'acces': acces,
      'date_maj': dateMaj,
      'lon': position.longitude,
      'lat': position.latitude,
    };
  }

  factory ParkingVelo.fromJson(Map<String, dynamic> json) {
    final geo = json['geo_point_2d'];
    double lat = 0.0;
    double lon = 0.0;
    if (geo is Map<String, dynamic>) {
      lat = (geo['lat'] as num?)?.toDouble() ?? 0.0;
      lon = (geo['lon'] as num?)?.toDouble() ?? 0.0;
    }
    return ParkingVelo(
      json['nom_parkng'] as String? ?? '',
      json['capacite'] as String? ?? '',
      json['acces'] as String? ?? '',
      json['date_maj'] as String? ?? '',
      LatLng(lat, lon),
    );
  }
}