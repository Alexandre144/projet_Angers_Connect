import 'package:angers_connect/blocs/parking_velo_cubit.dart';
import 'package:angers_connect/blocs/parking_voiture_cubit.dart';
import 'package:angers_connect/models/parking_velo.dart';
import 'package:angers_connect/models/parking_voiture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

import '../widgets/app_drawer.dart';

class ParkingScreen extends StatefulWidget {
  const ParkingScreen({super.key});

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parkings'),
      ),
      drawer: const AppDrawer(),
      body: BlocBuilder<ParkingVeloCubit, List<ParkingVelo>>(
        builder: (context, parkingVeloList) {
          return BlocBuilder<ParkingVoitureCubit, List<ParkingVoiture>>(
            builder: (context, parkingVoitureList) {
              if (parkingVeloList.isEmpty && parkingVoitureList.isEmpty) {
                return const Center(
                  child: Text('Aucun parking à afficher'),
                );
              }

              // Choix du centre initial : priorité vélo, sinon voiture
              final initialPosition = parkingVeloList.isNotEmpty
                  ? parkingVeloList.first.position
                  : (parkingVoitureList.isNotEmpty
                      ? parkingVoitureList.first.position
                      : null);
              if (initialPosition == null) {
                return const Center(child: Text('Aucun parking à afficher'));
              }

              final veloMarkers = parkingVeloList.map((parking) {
                return Marker(
                  point: parking.position,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    size: 40,
                    color: Colors.red,
                  ),
                );
              }).toList();

              final voitureMarkers = parkingVoitureList.map((parking) {
                return Marker(
                  point: parking.position,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    size: 40,
                    color: Colors.blue,
                  ),
                );
              }).toList();

              return FlutterMap(
                options: MapOptions(
                  initialCenter: initialPosition,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.angers_connect',
                  ),
                  MarkerLayer(
                    markers: [...veloMarkers, ...voitureMarkers],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
