import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/app_drawer.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = false;

  static const LatLng _angersCenter = LatLng(47.473076284, -0.57174862);
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();

      try {
        _mapController.move(_angersCenter, 13.0);
      } catch (_) {
        // ignore si l'API diffère, la carte restera néanmoins visible
      }
    });
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chargement des incidents...')),
    );

    // Simule un appel réseau minimal
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incidents chargés (démo)')),
    );
  }

  @override
  void dispose() {
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

            // Carte minimale affichée pour la ville d'Angers
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  options: MapOptions(),
                  mapController: _mapController,
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'fr.angers_connect.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 48,
                          height: 48,
                          point: _angersCenter,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 36,
                          ),
                        ),
                      ],
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
