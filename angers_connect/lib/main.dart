import 'package:flutter/material.dart';
import 'ui/screens/home.dart';
import 'ui/screens/lines_screen.dart';
import 'ui/screens/parking_screen.dart';
import 'ui/screens/incidents_screen.dart';

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
      initialRoute: '/home',
      routes: {
        '/home': (context) => const Home(),
        '/lines': (context) => const LinesScreen(),
        '/parking': (context) => const ParkingScreen(),
        '/incidents': (context) => const IncidentsScreen(),
      },
    );
  }
}
