import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/app_drawer.dart';
import '../widgets/generic_info_dialog.dart';
import '../widgets/search_bar_autocomplete.dart';
import '../widgets/favorites_list_dialog.dart';
import '../../models/incident_model.dart';
import '../../repositories/incidents_repository.dart';
import '../../blocs/incidents_cubit.dart';
import '../../services/favorites_service.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final IncidentsRepository _repo = IncidentsRepository();
  late final IncidentsCubit _cubit = IncidentsCubit(_repo);
  final FavoritesService _favService = FavoritesService();
  static const String _favCategory = 'incidents';
  int _favoritesVersion = 0;

  static const LatLng _angersCenter = LatLng(47.473076284, -0.57174862);
  final MapController _mapController = MapController();
  LatLng? _centerOn;
  Position? _userPosition;

  String? _formatDate(String? s) {
    if (s == null) return null;
    try {
      final dt = DateTime.parse(s).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return s;
    }
  }

  String _mapTraffic(String? t) {
    if (t == null) return '-';
    switch (t.toLowerCase()) {
      case 'slow': return 'Ralentissement';
      case 'deviated': return 'Déviation';
      default: return t;
    }
  }

  List<MapEntry<String, dynamic>> _buildDialogFields(Incident i) {
    final fields = <MapEntry<String, dynamic>>[];
    void add(String label, dynamic value) {
      if (value == null) return;
      final s = value.toString();
      if (s.trim().isEmpty) return;
      fields.add(MapEntry(label, s));
    }
    add('Description', i.description);
    add('Adresse', i.address);
    add('Début', _formatDate(i.startAt));
    add('Fin', _formatDate(i.endAt));
    add('Impact circulation', _mapTraffic(i.traffic));
    add('Impact tramway', i.isTramway == 1 ? 'Oui' : (i.isTramway == 0 ? 'Non' : null));
    add('Contact', i.contact);
    add('Email', i.email);
    add('Type', i.type);
    add('Lien', i.link);
    return fields;
  }

  Map<String, dynamic> _incidentToMap(Incident i) {
    return {
      'id': i.id,
      'title': i.title,
      'lat': i.lat,
      'lon': i.lon,
      'description': i.description,
      'address': i.address,
      'startAt': i.startAt,
      'endAt': i.endAt,
      'traffic': i.traffic,
      'contact': i.contact,
      'email': i.email,
      'isTramway': i.isTramway,
      'type': i.type,
      'link': i.link,
    };
  }

  void _showIncidentDialog(Incident incident) {
    final fields = _buildDialogFields(incident);
    final incidentMap = _incidentToMap(incident);
    showDialog(
      context: context,
      builder: (ctx) => GenericInfoDialog(
        title: incident.title,
        fields: fields,
        isFavorite: () => _favService.isFavorite(_favCategory, incidentMap),
        onToggleFavorite: () async {
          final isFav = await _favService.isFavorite(_favCategory, incidentMap);
          if (isFav) {
            await _favService.removeFavorite(_favCategory, incidentMap);
          } else {
            await _favService.addFavorite(_favCategory, incidentMap);
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
        title: 'Favoris - Incidents',
        favorites: favorites,
        itemTitle: (item) => item['title']?.toString() ?? 'Sans titre',
        onItemTap: (item) {
          final lat = item['lat'];
          final lon = item['lon'];
          if (lat != null && lon != null) {
            final position = LatLng(lat, lon);
            setState(() => _centerOn = position);
            _mapController.move(position, 16.0);
          }

          final incident = Incident(
            id: item['id'] ?? 0,
            title: item['title'] ?? '',
            lat: item['lat'],
            lon: item['lon'],
            rawFields: item,
          );
          _showIncidentDialog(incident);
        },
      ),
    );
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      setState(() => _userPosition = pos);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.load();
      _initLocation();
      Future.delayed(const Duration(milliseconds: 500), () {
        try { _mapController.move(_angersCenter, 13.0); } catch (_) {}
      });
    });
  }

  void _onSearchChanged() => setState(() => _centerOn = null);

  void _clearSearch() {
    _searchController.clear();
    setState(() => _centerOn = null);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidents'),
        actions: [
          IconButton(icon: const Icon(Icons.star), tooltip: 'Favoris', onPressed: _showFavoritesList),
        ],
      ),
      drawer: const AppDrawer(),
      body: BlocBuilder<IncidentsCubit, List<Incident>>(
        bloc: _cubit,
        builder: (context, incidentsList) {
          final filteredIncidents = _searchController.text.isEmpty
              ? incidentsList
              : incidentsList.where((i) {
                  final query = _searchController.text.toLowerCase();
                  return (i.title.toLowerCase().contains(query)) || (i.address?.toLowerCase().contains(query) ?? false);
                }).toList();

          final allItems = incidentsList.map((i) => {'obj': i, 'label': i.title}).toList();

          if (incidentsList.isEmpty) {
            return const Center(child: Text('Aucun incident à afficher'));
          }

          final initialPosition = _centerOn ??
              (filteredIncidents.isNotEmpty && filteredIncidents.first.lat != null && filteredIncidents.first.lon != null
                  ? LatLng(filteredIncidents.first.lat!, filteredIncidents.first.lon!)
                  : _angersCenter);

          return FutureBuilder<List<Map<String, dynamic>>>(
            key: ValueKey(_favoritesVersion),
            future: _favService.getFavorites(_favCategory),
            builder: (context, snapshot) {
              final favoriteIds = <String>{};
              if (snapshot.hasData) {
                for (final fav in snapshot.data!) {
                  favoriteIds.add('id_${fav['id']}');
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
                          hintText: 'Rechercher un incident...',
                          onSelected: (item) {
                            if (item != null) {
                              final Incident incident = item['obj'];
                              if (incident.lat != null && incident.lon != null) {
                                final pos = LatLng(incident.lat!, incident.lon!);
                                setState(() { _centerOn = pos; _searchController.text = item['label'] ?? ''; });
                                _mapController.move(pos, _mapController.camera.zoom);
                              }
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
                            ...filteredIncidents.where((i) => i.lat != null && i.lon != null).map((i) {
                              final isFavorite = favoriteIds.contains('id_${i.id}');
                              return Marker(
                                point: LatLng(i.lat!, i.lon!),
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () => _showIncidentDialog(i),
                                  child: Icon(Icons.location_pin, size: 40, color: isFavorite ? Colors.amber : Colors.red),
                                ),
                              );
                            }),
                            if (_userPosition != null)
                              Marker(
                                point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                                width: 48,
                                height: 48,
                                child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 36),
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
      ),
    );
  }
}
