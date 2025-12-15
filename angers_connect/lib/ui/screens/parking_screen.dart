import 'package:angers_connect/blocs/parking_velo_cubit.dart';
import 'package:angers_connect/blocs/parking_voiture_cubit.dart';
import 'package:angers_connect/models/parking_velo.dart';
import 'package:angers_connect/models/parking_voiture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/app_drawer.dart';
import '../widgets/generic_info_dialog.dart';
import '../widgets/search_bar_autocomplete.dart';

class ParkingScreen extends StatefulWidget {
  const ParkingScreen({super.key});

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  LatLng? _centerOn;
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController(); // Ajout du contrôleur de carte

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _centerOn = null;
    });
  }

  void _handleSearch(dynamic item, List<ParkingVelo> parkingVeloList, List<ParkingVoiture> parkingVoitureList) {
    if (item == null) {
      setState(() {
        _centerOn = null;
      });
    } else {
      final LatLng pos = item['obj'].position;
      setState(() {
        _centerOn = pos;
        _searchController.text = item['label'] ?? '';
      });
      // Centrer la carte sur la position choisie
      _mapController.move(pos, _mapController.camera.zoom);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _centerOn = null;
    });
  }

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
              // Filtrage unique sur les deux listes
              List<ParkingVelo> filteredVelos = _searchController.text.isEmpty
                  ? parkingVeloList
                  : parkingVeloList.where((p) => p.nom_parkng.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
              List<ParkingVoiture> filteredVoitures = _searchController.text.isEmpty
                  ? parkingVoitureList
                  : parkingVoitureList.where((p) => p.nom.toLowerCase().contains(_searchController.text.toLowerCase())).toList();

              final allItems = [
                ...parkingVeloList.map((p) => {'type': 'velo', 'obj': p, 'label': p.nom_parkng}),
                ...parkingVoitureList.map((p) => {'type': 'voiture', 'obj': p, 'label': p.nom}),
              ];

              if (parkingVeloList.isEmpty && parkingVoitureList.isEmpty) {
                return const Center(
                  child: Text('Aucun parking à afficher'),
                );
              }

              final initialPosition = _centerOn ??
                  (filteredVelos.isNotEmpty
                      ? filteredVelos.first.position
                      : (filteredVoitures.isNotEmpty
                          ? filteredVoitures.first.position
                          : null));
              if (initialPosition == null) {
                return const Center(child: Text('Aucun parking à afficher'));
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        SearchBarAutocomplete<Map<String, dynamic>>(
                          controller: _searchController,
                          items: allItems,
                          itemToString: (item) => item['label'] ?? '',
                          hintText: 'Rechercher un parking... (vélo ou voiture)',
                          onSelected: (item) {
                            if (item == null) {
                              // Ne rien faire ici, le filtrage se fait via le listener
                            } else {
                              final LatLng pos = item['obj'].position;
                              setState(() {
                                _centerOn = pos;
                                _searchController.text = item['label'] ?? '';
                              });
                              // Centrer la carte sur la position choisie
                              _mapController.move(pos, _mapController.camera.zoom);
                            }
                          },
                        ),
                        if (_searchController.text.isNotEmpty)
                          Positioned(
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FlutterMap(
                      mapController: _mapController, // Lier le contrôleur à la carte
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
                          markers: [
                            ...filteredVelos.map((parking) {
                              return Marker(
                                point: parking.position,
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => GenericInfoDialog(
                                        title: parking.nom_parkng,
                                        fields: [
                                          MapEntry('Nom', parking.nom_parkng),
                                          MapEntry('Capacité maximal', parking.capacite),
                                          MapEntry('Accès', parking.acces),
                                          MapEntry('Dernière MAJ', parking.date_maj),
                                        ],
                                      ),
                                    );
                                  },
                                  child: const Icon(
                                    Icons.location_pin,
                                    size: 40,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            }),
                            ...filteredVoitures.map((parking) {
                              return Marker(
                                point: parking.position,
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => GenericInfoDialog(
                                        title: parking.nom,
                                        fields: [
                                          MapEntry('Nom', parking.nom),
                                          MapEntry('Nb places disponibles', parking.disponible),
                                        ],
                                      ),
                                    );
                                  },
                                  child: const Icon(
                                    Icons.location_pin,
                                    size: 40,
                                    color: Colors.blue,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
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
