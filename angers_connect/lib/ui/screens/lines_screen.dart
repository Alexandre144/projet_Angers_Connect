import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../blocs/tram_line_cubit.dart';
import '../../models/tram_line.dart';
import '../widgets/app_drawer.dart';

class LinesScreen extends StatelessWidget {
  const LinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lignes Bus / Tram'),
      ),
      drawer: const AppDrawer(),
      body: BlocBuilder<TramLineCubit, List<TramLine>>(
        builder: (context, tramLines) {
          if (tramLines.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          // Centrer la carte sur Angers
          final LatLng initialCenter = LatLng(47.473460, -0.565297);
          return FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.angers_connect',
              ),
              PolylineLayer(
                polylines: tramLines.map((tramLine) {
                  // On récupère toutes les coordonnées de la ligne (MultiLineString)
                  final List<LatLng> points = tramLine.shapeCoordinates.expand((line) => line.map((coord) => LatLng(coord[1], coord[0]))).toList();
                  return Polyline(
                    points: points,
                    color: Color(int.parse('FF${tramLine.routeColor}', radix: 16)),
                    strokeWidth: 5.0,
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
