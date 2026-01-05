import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/app_drawer.dart';
import '../widgets/generic_info_dialog.dart';
import '../widgets/search_bar_autocomplete.dart';
import '../../models/incident_model.dart';
import '../../repositories/incidents_repository.dart';
import '../../blocs/incidents_cubit.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final IncidentsRepository _repo = IncidentsRepository();
  late final IncidentsCubit _cubit = IncidentsCubit(_repo);

  static const LatLng _angersCenter = LatLng(47.473076284, -0.57174862);
  final MapController _mapController = MapController();
  LatLng? _centerOn;
  Position? _userPosition;

  String? _formatDate(String? s) {
    if (s == null) return null;
    try {
      final dt = DateTime.parse(s).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    } catch (_) {
      return s; // si parsing échoue, retourner la valeur brute
    }
  }

  String _mapTraffic(String? t) {
    if (t == null) return '-';
    switch (t.toLowerCase()) {
      case 'slow':
        return 'Ralentissement';
      case 'deviated':
        return 'Déviation';
      default:
        return t;
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
    } catch (_) {
      // ignore errors silently for now
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.load();
      _initLocation();
      // Recentrer la carte sur Angers après un court délai
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          _mapController.move(_angersCenter, 13.0);
        } catch (_) {}
      });
    });
  }

  void _onSearchChanged() {
    setState(() {
      _centerOn = null;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _centerOn = null;
    });
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
      ),
      drawer: const AppDrawer(),
      body: BlocBuilder<IncidentsCubit, List<Incident>>(
        bloc: _cubit,
        builder: (context, incidentsList) {
          // Filtrage en temps réel
          final filteredIncidents = _searchController.text.isEmpty
              ? incidentsList
              : incidentsList.where((i) {
                  final query = _searchController.text.toLowerCase();
                  return (i.title.toLowerCase().contains(query)) ||
                         (i.address?.toLowerCase().contains(query) ?? false);
                }).toList();

          // Préparer les items pour l'autocomplétion
          final allItems = incidentsList.map((i) => {
            'obj': i,
            'label': i.title,
          }).toList();

          if (incidentsList.isEmpty) {
            return const Center(
              child: Text('Aucun incident à afficher'),
            );
          }

          // Position initiale : centrer sur le premier incident filtré ou sur Angers
          final initialPosition = _centerOn ??
              (filteredIncidents.isNotEmpty && filteredIncidents.first.lat != null && filteredIncidents.first.lon != null
                  ? LatLng(filteredIncidents.first.lat!, filteredIncidents.first.lon!)
                  : _angersCenter);

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
                      hintText: 'Rechercher un incident... (titre ou adresse)',
                      onSelected: (item) {
                        if (item == null) {
                          // Filtrage automatique géré par le listener
                        } else {
                          final Incident incident = item['obj'];
                          if (incident.lat != null && incident.lon != null) {
                            final pos = LatLng(incident.lat!, incident.lon!);
                            setState(() {
                              _centerOn = pos;
                              _searchController.text = item['label'] ?? '';
                            });
                            _mapController.move(pos, _mapController.camera.zoom);
                          }
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
                  mapController: _mapController,
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
                        // Incidents filtrés
                        ...filteredIncidents.where((i) => i.lat != null && i.lon != null).map((i) {
                          return Marker(
                            point: LatLng(i.lat!, i.lon!),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () {
                                final fields = _buildDialogFields(i);
                                showDialog(
                                  context: context,
                                  builder: (context) => GenericInfoDialog(
                                    title: i.title,
                                    fields: fields,
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
                        // Position utilisateur si disponible
                        if (_userPosition != null)
                          Marker(
                            point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.blue,
                              size: 36,
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
      ),
    );
  }
}
