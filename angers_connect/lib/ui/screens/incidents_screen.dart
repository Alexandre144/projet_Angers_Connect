import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/app_drawer.dart';
import '../../data/models/incident_model.dart';
import '../../data/repositories/incidents_repository.dart';
import '../../logic/cubit/incidents_cubit.dart';

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

  static const LatLng _angersCenter = LatLng(47.473076284, -0.57174862);
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() => _cubit.load());

      try {
        _mapController.move(_angersCenter, 13.0);
      } catch (_) {
        // ignore si l'API diffère, la carte restera néanmoins visible
      }
    });
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chargement des incidents...')));
    try {
      await _cubit.load();
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
              decoration: InputDecoration(
                hintText: 'Rechercher un incident (titre ou adresse)',
                prefixIcon: const Icon(Icons.search),
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
                        final markers = <Marker>[
                          Marker(
                            width: 48,
                            height: 48,
                            point: _angersCenter,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.blueGrey,
                              size: 30,
                            ),
                          ),
                        ];

                        for (final i in incidents) {
                          if (i.lat != null && i.lon != null) {
                            markers.add(Marker(width: 40, height: 40, point: LatLng(i.lat!, i.lon!), child: const Icon(Icons.place, color: Colors.red, size: 28)));
                          }
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
