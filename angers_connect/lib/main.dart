import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'ui/screens/lines_screen.dart';
import 'ui/screens/parking_screen.dart';
import 'ui/screens/incidents_screen.dart';
import 'repositories/parking_velo_repository.dart';
import 'repositories/parking_voiture_repository.dart';
import 'repositories/tram_line_repository.dart';
import 'repositories/tram_arret_repository.dart';
import 'blocs/parking_velo_cubit.dart';
import 'blocs/parking_voiture_cubit.dart';
import 'blocs/tram_line_cubit.dart';
import 'blocs/tram_arret_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Angers Connect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/lines',
      routes: {
        '/lines': (context) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => TramLineCubit(TramLineRepository()),
                ),
                BlocProvider(
                  create: (_) => TramArretCubit(TramArretRepository()),
                ),
              ],
              child: const LinesScreen(),
            ),
        '/parking': (context) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => ParkingVeloCubit(ParkingVeloRepository()),
                ),
                BlocProvider(
                  create: (_) => ParkingVoitureCubit(ParkingVoitureRepository()),
                ),
              ],
              child: const ParkingScreen(),
            ),
        '/incidents': (context) => const IncidentsScreen(),
      },
    );
  }
}
