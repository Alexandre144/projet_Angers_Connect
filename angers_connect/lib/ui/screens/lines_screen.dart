import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import '../../blocs/tram_line_cubit.dart';
import '../../models/tram_line.dart';
import '../../models/tram_arret.dart';
import '../../blocs/tram_arret_cubit.dart';
import '../../services/favorites_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/generic_info_dialog.dart';
import '../widgets/favorites_list_dialog.dart';

class LinesScreen extends StatefulWidget {
  const LinesScreen({super.key});

  @override
  State<LinesScreen> createState() => _LinesScreenState();
}

class _LinesScreenState extends State<LinesScreen> {
  final Set<String> visibleTramLines = {'A', 'B', 'C'};
  final Set<String> visibleBusLines = {};
  bool showTramDropdown = false;
  bool showBusDropdown = false;
  Map<String, Set<String>> lineToStops = {};
  bool mappingLoaded = false;

  final FavoritesService _favService = FavoritesService();
  static const String _favCategory = 'arrets';
  int _favoritesVersion = 0;
  final MapController _mapController = MapController();

  Future<void> loadLineStopMapping() async {
    if (mappingLoaded) return;
    final file = File('lib/annexes/arrets_lignes_irigo.txt');
    if (!await file.exists()) return;
    final lines = await file.readAsLines();
    final Map<String, Set<String>> map = {};
    for (final l in lines.skip(1)) { // skip header
      final parts = l.split(';');
      if (parts.length < 4) continue;
      final routeShortName = parts[3].trim().toUpperCase();
      final stopId = parts[1].trim().toUpperCase();
      map.putIfAbsent(routeShortName, () => <String>{}).add(stopId);
    }
    setState(() {
      lineToStops = map;
      mappingLoaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    loadLineStopMapping();
  }

  Map<String, dynamic> _arretToMap(TramArret arret) {
    return {
      'stopId': arret.stopId,
      'stopCode': arret.stopCode,
      'stopName': arret.stopName,
      'lat': arret.lat,
      'lon': arret.lon,
      'stopDesc': arret.stopDesc,
      'parentStation': arret.parentStation,
      'stopTimezone': arret.stopTimezone,
      'accessible': arret.accessible,
      'routeShortNames': arret.routeShortNames.toList(),
    };
  }

  void _showArretDialog(TramArret arret) {
    final arretMap = _arretToMap(arret);
    showDialog(
      context: context,
      builder: (ctx) => GenericInfoDialog(
        title: arret.stopName,
        fields: [
          MapEntry('Code', arret.stopCode),
          MapEntry('Nom', arret.stopName),
          if (arret.stopDesc != null && arret.stopDesc!.isNotEmpty)
            MapEntry('Description', arret.stopDesc),
          MapEntry('Accessibilité', arret.accessible ? 'Oui' : 'Non'),
          if (arret.parentStation != null && arret.parentStation!.isNotEmpty)
            MapEntry('Station parente', arret.parentStation),
          MapEntry('Fuseau horaire', arret.stopTimezone),
          MapEntry('Coordonnées', '(${arret.lat}, ${arret.lon})'),
        ],
        isFavorite: () => _favService.isFavorite(_favCategory, arretMap),
        onToggleFavorite: () async {
          final isFav = await _favService.isFavorite(_favCategory, arretMap);
          if (isFav) {
            await _favService.removeFavorite(_favCategory, arretMap);
          } else {
            await _favService.addFavorite(_favCategory, arretMap);
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
        title: 'Favoris - Arrêts',
        favorites: favorites,
        itemTitle: (item) => item['stopName']?.toString() ?? 'Sans nom',
        onItemTap: (item) {
          final lat = item['lat'];
          final lon = item['lon'];
          if (lat != null && lon != null) {
            final position = LatLng(lat, lon);
            _mapController.move(position, 16.0);
          }
          final arret = TramArret(
            stopId: item['stopId']?.toString() ?? '',
            stopCode: item['stopCode']?.toString() ?? '',
            stopName: item['stopName']?.toString() ?? '',
            lat: item['lat'] ?? 0.0,
            lon: item['lon'] ?? 0.0,
            stopDesc: item['stopDesc']?.toString(),
            parentStation: item['parentStation']?.toString(),
            stopTimezone: item['stopTimezone']?.toString() ?? '',
            accessible: item['accessible'] == true,
            routeShortNames: Set<String>.from((item['routeShortNames'] as List?)?.map((e) => e.toString()) ?? []),
          );
          _showArretDialog(arret);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lignes Bus / Tram'),
        actions: [
          IconButton(icon: const Icon(Icons.star), tooltip: 'Favoris', onPressed: _showFavoritesList),
        ],
      ),
      drawer: const AppDrawer(),
      body: BlocBuilder<TramLineCubit, List<TramLine>>(
        builder: (context, tramLines) {
          return BlocBuilder<TramArretCubit, List<TramArret>>(
            builder: (context, arrets) {
              if (tramLines.isEmpty || arrets.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final LatLng initialCenter = LatLng(47.473460, -0.565297);
              // Séparer trams et bus
              final trams = tramLines.where((l) => l.routeType.toLowerCase() == 'tram').toList();
              // Tri personnalisé des bus :
              final bus = List<TramLine>.from(tramLines.where((l) => l.routeType.toLowerCase() == 'bus'));
              // Bus spéciaux (lettres uniquement)
              final specialBus = bus.where((l) => RegExp(r'^[A-Za-z]+$').hasMatch(l.routeShortName)).toList();
              // Bus numériques purs (ex: 1, 2, ..., 99, 100...)
              final numericBus = bus.where((l) => RegExp(r'^[0-9]+$').hasMatch(l.routeShortName)).toList();
              // Bus mixtes (ex: E22, 12A, etc.) doivent être insérés à leur place numérique globale
              // On fusionne before100 et mixedBefore100, triés ensemble par valeur numérique
              final mixedBus = bus.where((l) => !RegExp(r'^[A-Za-z]+$').hasMatch(l.routeShortName) && !RegExp(r'^[0-9]+$').hasMatch(l.routeShortName)).toList();
              // Trier bus numériques
              numericBus.sort((a, b) => int.parse(a.routeShortName).compareTo(int.parse(b.routeShortName)));
              // Trier bus spéciaux alphabétiquement
              specialBus.sort((a, b) => a.routeShortName.compareTo(b.routeShortName));
              // Trier bus mixtes par valeur numérique extraite (ex: E22 = 22, 12A = 12), puis alphabétiquement
              mixedBus.sort((a, b) {
                final aNum = int.tryParse(RegExp(r'([0-9]+)').firstMatch(a.routeShortName)?.group(1) ?? '') ?? 0;
                final bNum = int.tryParse(RegExp(r'([0-9]+)').firstMatch(b.routeShortName)?.group(1) ?? '') ?? 0;
                if (aNum != bNum) return aNum.compareTo(bNum);
                return a.routeShortName.compareTo(b.routeShortName);
              });
              // Insérer les bus spéciaux juste avant les bus numériques >= 100
              final before100 = numericBus.where((l) => int.parse(l.routeShortName) < 100).toList();
              final after99 = numericBus.where((l) => int.parse(l.routeShortName) >= 100).toList();
              // Les mixtes (E22, 12A, etc.) doivent rester dans l'ordre numérique global
              // On les place entre before100 et after99 selon leur valeur numérique
              final mixedBefore100 = mixedBus.where((l) => (int.tryParse(RegExp(r'([0-9]+)').firstMatch(l.routeShortName)?.group(1) ?? '') ?? 0) < 100).toList();
              final mixedAfter99 = mixedBus.where((l) => (int.tryParse(RegExp(r'([0-9]+)').firstMatch(l.routeShortName)?.group(1) ?? '') ?? 0) >= 100).toList();
              // Fusionner before100 et mixedBefore100 pour garder l'ordre numérique global
              final List<TramLine> before100WithMixed = [...before100, ...mixedBefore100];
              before100WithMixed.sort((a, b) {
                final aNum = int.tryParse(RegExp(r'([0-9]+)').firstMatch(a.routeShortName)?.group(1) ?? '') ?? 0;
                final bNum = int.tryParse(RegExp(r'([0-9]+)').firstMatch(b.routeShortName)?.group(1) ?? '') ?? 0;
                if (aNum != bNum) return aNum.compareTo(bNum);
                return a.routeShortName.compareTo(b.routeShortName);
              });
              // Idem pour after99 et mixedAfter99
              final List<TramLine> after99WithMixed = [...after99, ...mixedAfter99];
              after99WithMixed.sort((a, b) {
                final aNum = int.tryParse(RegExp(r'([0-9]+)').firstMatch(a.routeShortName)?.group(1) ?? '') ?? 0;
                final bNum = int.tryParse(RegExp(r'([0-9]+)').firstMatch(b.routeShortName)?.group(1) ?? '') ?? 0;
                if (aNum != bNum) return aNum.compareTo(bNum);
                return a.routeShortName.compareTo(b.routeShortName);
              });
              // Construction finale :
              final sortedBus = [
                ...before100WithMixed,
                ...specialBus,
                ...after99WithMixed
              ];
              // Filtrer les arrêts à afficher :
              final Set<String> lignesVisibles = {
                ...visibleTramLines,
                ...visibleBusLines,
              };
              // Filtrage : n'afficher que les arrêts dont la liste des lignes intersecte les lignes visibles
              final arretsFiltres = arrets.where((arret) {
                return arret.routeShortNames.any((ligne) => lignesVisibles.contains(ligne));
              }).toList();
              final arretsVisibles = arretsFiltres;
              return FutureBuilder<List<Map<String, dynamic>>>(
                key: ValueKey(_favoritesVersion),
                future: _favService.getFavorites(_favCategory),
                builder: (context, snapshot) {
                  final favoriteIds = <String>{};
                  if (snapshot.hasData) {
                    for (final fav in snapshot.data!) {
                      final stopId = fav['stopId']?.toString() ?? '';
                      favoriteIds.add(stopId);
                    }
                  }
                  return Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
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
                        polylines: [
                          // Pour chaque ligne de tram, créer une polyline par tronçon (MultiLineString)
                          ...trams.where((l) => visibleTramLines.contains(l.routeShortName)).expand((tramLine) =>
                            tramLine.shapeCoordinates.map((segment) {
                              final List<LatLng> points = segment.map((coord) => LatLng(coord[1], coord[0])).toList();
                              return Polyline(
                                points: points,
                                color: Color(int.parse('FF${tramLine.routeColor}', radix: 16)),
                                strokeWidth: 5.0,
                              );
                            })
                          ),
                          // Pour chaque ligne de bus, idem
                          ...bus.where((l) => visibleBusLines.contains(l.routeShortName)).expand((busLine) =>
                            busLine.shapeCoordinates.map((segment) {
                              final List<LatLng> points = segment.map((coord) => LatLng(coord[1], coord[0])).toList();
                              return Polyline(
                                points: points,
                                color: Color(int.parse('FF${busLine.routeColor}', radix: 16)),
                                strokeWidth: 5.0,
                              );
                            })
                          ),
                        ],
                      ),
                      MarkerLayer(
                            markers: [
                              ...arretsVisibles.map((arret) {
                                final isFavorite = favoriteIds.contains(arret.stopId);
                                return Marker(
                                  point: LatLng(arret.lat, arret.lon),
                                  width: 36,
                                  height: 36,
                                  child: GestureDetector(
                                    onTap: () => _showArretDialog(arret),
                                    child: Tooltip(
                                      message: arret.stopName,
                                      child: Icon(
                                        arret.accessible ? Icons.location_on : Icons.location_on_outlined,
                                        color: isFavorite ? Colors.amber : (arret.accessible ? Colors.blue : Colors.grey),
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                    ],
                  ),
                  // Boutons Tram et Bus en bas à gauche
                  Positioned(
                    left: 16,
                    bottom: 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bouton Tram
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FloatingActionButton(
                              heroTag: 'tram',
                              mini: true,
                              onPressed: () {
                                setState(() {
                                  showTramDropdown = !showTramDropdown;
                                  showBusDropdown = false;
                                });
                              },
                              child: const Icon(Icons.tram),
                            ),
                            if (showTramDropdown)
                              Container(
                                margin: const EdgeInsets.only(left: 12),
                                constraints: const BoxConstraints(maxWidth: 400),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)],
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: trams.map((line) => InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (visibleTramLines.contains(line.routeShortName)) {
                                            visibleTramLines.remove(line.routeShortName);
                                          } else {
                                            visibleTramLines.add(line.routeShortName);
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: visibleTramLines.contains(line.routeShortName)
                                                ? Color(int.parse('FF${line.routeColor}', radix: 16))
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: Color(int.parse('FF${line.routeColor}', radix: 16)),
                                              width: 2,
                                            ),
                                          ),
                                          child: Text(
                                            line.routeShortName,
                                            style: TextStyle(
                                              color: visibleTramLines.contains(line.routeShortName)
                                                  ? Colors.white
                                                  : Color(int.parse('FF${line.routeColor}', radix: 16)),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )).toList(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Bouton Bus
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FloatingActionButton(
                              heroTag: 'bus',
                              mini: true,
                              onPressed: () {
                                setState(() {
                                  showBusDropdown = !showBusDropdown;
                                  showTramDropdown = false;
                                });
                              },
                              child: const Icon(Icons.directions_bus),
                            ),
                            if (showBusDropdown)
                              Container(
                                margin: const EdgeInsets.only(left: 12),
                                constraints: const BoxConstraints(maxWidth: 600),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)],
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: sortedBus.map((line) => InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (visibleBusLines.contains(line.routeShortName)) {
                                            visibleBusLines.remove(line.routeShortName);
                                          } else {
                                            visibleBusLines.add(line.routeShortName);
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: visibleBusLines.contains(line.routeShortName)
                                                ? Color(int.parse('FF${line.routeColor}', radix: 16))
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: Color(int.parse('FF${line.routeColor}', radix: 16)),
                                              width: 2,
                                            ),
                                          ),
                                          child: Text(
                                            line.routeShortName,
                                            style: TextStyle(
                                              color: visibleBusLines.contains(line.routeShortName)
                                                  ? Colors.white
                                                  : Color(int.parse('FF${line.routeColor}', radix: 16)),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )).toList(),
                                  ),
                                ),
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
