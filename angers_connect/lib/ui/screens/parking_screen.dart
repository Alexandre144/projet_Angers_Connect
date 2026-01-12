import 'dart:async';
import 'package:angers_connect/blocs/parking_velo_cubit.dart';
import 'package:angers_connect/blocs/parking_voiture_cubit.dart';
import 'package:angers_connect/models/parking_velo.dart';
import 'package:angers_connect/models/parking_voiture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/app_drawer.dart';
import '../widgets/generic_info_dialog.dart';
import '../widgets/search_bar_autocomplete.dart';
import '../widgets/favorites_list_dialog.dart';
import '../../services/favorites_service.dart';
import '../../services/geolocation_helper.dart';

class ParkingScreen extends StatefulWidget {
  const ParkingScreen({super.key});

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  LatLng? _centerOn;
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  final FavoritesService _favService = FavoritesService();
  static const String _favCategory = 'parkings';
  int _favoritesVersion = 0;
  Position? _userPosition;

  Future<void> _initLocation() async {
    try {
      final pos = await GeolocationHelper.getCurrentPosition();
      if (pos == null) return;
      if (mounted) {
        setState(() => _userPosition = pos);
      }
    } catch (_) {
      // Géolocalisation optionnelle
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initLocation();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() => _centerOn = null);

  void _clearSearch() {
    _searchController.clear();
    setState(() => _centerOn = null);
  }

  Map<String, dynamic> _parkingVeloToMap(ParkingVelo p) {
    return {
      'type': 'velo',
      'nom_parkng': p.nomParkng,
      'capacite': p.capacite,
      'acces': p.acces,
      'date_maj': p.dateMaj,
      'lat': p.position.latitude,
      'lon': p.position.longitude,
    };
  }

  Map<String, dynamic> _parkingVoitureToMap(ParkingVoiture p) {
    return {
      'type': 'voiture',
      'nom': p.nom,
      'disponible': p.disponible,
      'lat': p.position.latitude,
      'lon': p.position.longitude,
    };
  }

  void _showParkingVeloDialog(ParkingVelo parking) {
    final parkingMap = _parkingVeloToMap(parking);
    showDialog(
      context: context,
      builder: (ctx) => GenericInfoDialog(
        title: parking.nomParkng,
        fields: [
          MapEntry('Nom', parking.nomParkng),
          MapEntry('Capacité maximal', parking.capacite),
          MapEntry('Accès', parking.acces),
          MapEntry('Dernière MAJ', parking.dateMaj),
        ],
        isFavorite: () => _favService.isFavorite(_favCategory, parkingMap),
        onToggleFavorite: () async {
          final isFav = await _favService.isFavorite(_favCategory, parkingMap);
          if (isFav) {
            await _favService.removeFavorite(_favCategory, parkingMap);
          } else {
            await _favService.addFavorite(_favCategory, parkingMap);
          }
          setState(() => _favoritesVersion++);
        },
      ),
    );
  }

  void _showParkingVoitureDialog(ParkingVoiture parking) {
    final parkingMap = _parkingVoitureToMap(parking);
    showDialog(
      context: context,
      builder: (ctx) => GenericInfoDialog(
        title: parking.nom,
        fields: [
          MapEntry('Nom', parking.nom),
          MapEntry('Nb places disponibles', parking.disponible),
        ],
        isFavorite: () => _favService.isFavorite(_favCategory, parkingMap),
        onToggleFavorite: () async {
          final isFav = await _favService.isFavorite(_favCategory, parkingMap);
          if (isFav) {
            await _favService.removeFavorite(_favCategory, parkingMap);
          } else {
            await _favService.addFavorite(_favCategory, parkingMap);
          }
          setState(() => _favoritesVersion++);
        },
      ),
    );
  }

  Future<void> _showFavoritesList() async {
    final favorites = await _favService.getFavorites(_favCategory);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => FavoritesListDialog(
        title: 'Favoris - Parkings',
        favorites: favorites,
        itemTitle: (item) {
          final type = item['type']?.toString() ?? '';
          if (type == 'velo') return '🚲 ${item['nom_parkng'] ?? 'Sans nom'}';
          return '🚗 ${item['nom'] ?? 'Sans nom'}';
        },
        onItemTap: (item) {
          final type = item['type']?.toString() ?? '';
          final lat = item['lat'] ?? 0.0;
          final lon = item['lon'] ?? 0.0;
          final position = LatLng(lat, lon);

          setState(() => _centerOn = position);
          _mapController.move(position, 16.0);

          if (type == 'velo') {
            final parking = ParkingVelo(
              item['nom_parkng']?.toString() ?? '',
              item['capacite']?.toString() ?? '',
              item['acces']?.toString() ?? '',
              item['date_maj']?.toString() ?? '',
              position,
            );
            _showParkingVeloDialog(parking);
          } else {
            final parking = ParkingVoiture(
              item['nom']?.toString() ?? '',
              item['disponible']?.toString() ?? '',
              position,
            );
            _showParkingVoitureDialog(parking);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parkings'),
        actions: [
          IconButton(icon: const Icon(Icons.star), tooltip: 'Favoris', onPressed: _showFavoritesList),
        ],
      ),
      drawer: const AppDrawer(),
      body: BlocBuilder<ParkingVeloCubit, List<ParkingVelo>>(
        builder: (context, parkingVeloList) {
          return BlocBuilder<ParkingVoitureCubit, List<ParkingVoiture>>(
            builder: (context, parkingVoitureList) {
              List<ParkingVelo> filteredVelos = _searchController.text.isEmpty
                  ? parkingVeloList
                  : parkingVeloList.where((p) => p.nomParkng.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
              List<ParkingVoiture> filteredVoitures = _searchController.text.isEmpty
                  ? parkingVoitureList
                  : parkingVoitureList.where((p) => p.nom.toLowerCase().contains(_searchController.text.toLowerCase())).toList();

              final allItems = [
                ...parkingVeloList.map((p) => {'type': 'velo', 'obj': p, 'label': p.nomParkng}),
                ...parkingVoitureList.map((p) => {'type': 'voiture', 'obj': p, 'label': p.nom}),
              ];

              if (parkingVeloList.isEmpty && parkingVoitureList.isEmpty) {
                return const Center(child: Text('Aucun parking à afficher'));
              }

              final initialPosition = _centerOn ??
                  (filteredVelos.isNotEmpty
                      ? filteredVelos.first.position
                      : (filteredVoitures.isNotEmpty ? filteredVoitures.first.position : null));
              if (initialPosition == null) {
                return const Center(child: Text('Aucun parking à afficher'));
              }

              return FutureBuilder<List<Map<String, dynamic>>>(
                key: ValueKey(_favoritesVersion),
                future: _favService.getFavorites(_favCategory),
                builder: (context, snapshot) {
                  final favoriteIds = <String>{};
                  if (snapshot.hasData) {
                    for (final fav in snapshot.data!) {
                      final name = fav['nom'] ?? fav['nom_parkng'] ?? '';
                      final lat = fav['lat']?.toString() ?? '';
                      final lon = fav['lon']?.toString() ?? '';
                      favoriteIds.add('${name}_${lat}_$lon');
                    }
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
                              hintText: 'Rechercher un parking...',
                              onSelected: (item) {
                                if (item != null) {
                                  final LatLng pos = item['obj'].position;
                                  setState(() { _centerOn = pos; _searchController.text = item['label'] ?? ''; });
                                  _mapController.move(pos, _mapController.camera.zoom);
                                }
                              },
                            ),
                            if (_searchController.text.isNotEmpty)
                              Positioned(right: 8, child: IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(initialCenter: initialPosition, initialZoom: 13),
                          children: [
                            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.angers_connect'),
                            MarkerLayer(
                              markers: [
                                ...filteredVelos.map((parking) {
                                  final parkingId = '${parking.nomParkng}_${parking.position.latitude}_${parking.position.longitude}';
                                  final isFavorite = favoriteIds.contains(parkingId);
                                  return Marker(
                                    point: parking.position,
                                    width: 40,
                                    height: 40,
                                    child: GestureDetector(
                                      onTap: () => _showParkingVeloDialog(parking),
                                      child: Icon(Icons.location_pin, size: 40, color: isFavorite ? Colors.amber : Colors.red),
                                    ),
                                  );
                                }),
                                ...filteredVoitures.map((parking) {
                                  final parkingId = '${parking.nom}_${parking.position.latitude}_${parking.position.longitude}';
                                  final isFavorite = favoriteIds.contains(parkingId);
                                  return Marker(
                                    point: parking.position,
                                    width: 40,
                                    height: 40,
                                    child: GestureDetector(
                                      onTap: () => _showParkingVoitureDialog(parking),
                                      child: Icon(Icons.location_pin, size: 40, color: isFavorite ? Colors.amber : Colors.blue),
                                    ),
                                  );
                                }),
                                if (_userPosition != null)
                                  Marker(
                                    point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                                    width: 48,
                                    height: 48,
                                    child: const Icon(Icons.person_pin_circle, color: Colors.green, size: 48),
                                  ),
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
          );
        },
      ),
    );
  }
}
