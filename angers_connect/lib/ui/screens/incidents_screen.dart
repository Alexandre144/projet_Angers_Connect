import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/app_drawer.dart';
import '../widgets/generic_info_dialog.dart';
import '../../data/models/incident_model.dart';
import '../../data/repositories/incidents_repository.dart';
import '../../logic/cubit/incidents_cubit.dart';
import 'package:geolocator/geolocator.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = false;

  final IncidentsRepository _repo = IncidentsRepository();
  late final IncidentsCubit _cubit = IncidentsCubit(_repo);
  bool _hasSearched = false;

  static const LatLng _angersCenter = LatLng(47.473076284, -0.57174862);
  final MapController _mapController = MapController();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() => _cubit.load());
      _initLocation();
      // Recentrer la carte sur Angers après un court délai
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          _mapController.move(_angersCenter, 13.0);
        } catch (_) {}
      });
    });
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chargement des incidents...')));
    try {
      _hasSearched = true;
      await _cubit.load(q: _searchController.text.trim());
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incidents chargés (démo)')));
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  void dispose() {
    _cubit.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidents'),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onSubmitted: (value) => _refresh(),
              decoration: InputDecoration(
                hintText: 'Rechercher un incident (titre ou adresse)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _refresh(),
                ),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  options: MapOptions(),
                  mapController: _mapController,
                  children: [
                    TileLayer(
                      // Utiliser l'URL sans {s} pour éviter les warnings OSM
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'fr.angers_connect.app',
                    ),
                    BlocBuilder<IncidentsCubit, List<Incident>>(
                      bloc: _cubit,
                      builder: (context, incidents) {

                        if (_hasSearched && incidents.isEmpty) {
                          return Center(child: Text('Aucun résultat', style: Theme.of(context).textTheme.titleMedium));
                        }

                        final markers = <Marker>[];
                        // centre Angers
                        markers.add(Marker(width: 48, height: 48, point: _angersCenter, child: const Icon(Icons.location_on, color: Colors.blueGrey, size: 30)));

                        for (final i in incidents) {
                          if (i.lat != null && i.lon != null) {
                            markers.add(Marker(
                              width: 40,
                              height: 40,
                              point: LatLng(i.lat!, i.lon!),
                              child: GestureDetector(
                                onTap: () {
                                  // Construire les champs pour le dialog à partir du modèle
                                  final fields = _buildDialogFields(i);

                                  showDialog(context: context, builder: (ctx) => GenericInfoDialog(title: i.title, fields: fields));
                                },
                                child: const Icon(Icons.place, color: Colors.red, size: 28),
                              ),
                            ));
                          }
                        }

                        // position utilisateur (si disponible) - icône plus visible (ajoutée en dernier pour être au-dessus)
                        if (_userPosition != null) {
                          markers.add(Marker(
                            width: 48,
                            height: 48,
                            point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                            child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 36),
                          ));
                        }

                        return MarkerLayer(markers: markers);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _refresh,
                icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.refresh),
                label: Text(_loading ? 'Chargement...' : 'Actualiser'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
