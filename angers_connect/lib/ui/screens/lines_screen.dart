import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../blocs/tram_line_cubit.dart';
import '../../models/tram_line.dart';
import '../widgets/app_drawer.dart';

class LinesScreen extends StatefulWidget {
  const LinesScreen({super.key});

  @override
  State<LinesScreen> createState() => _LinesScreenState();
}

class _LinesScreenState extends State<LinesScreen> {
  // Par défaut, seules les lignes de tram A, B, C sont visibles
  final Set<String> visibleTramLines = {'A', 'B', 'C'};
  final Set<String> visibleBusLines = {};
  bool showTramDropdown = false;
  bool showBusDropdown = false;

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
          return Stack(
            children: [
              FlutterMap(
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
      ),
    );
  }
}
