import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class LinesScreen extends StatelessWidget {
  const LinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lignes Bus / Tram'),
      ),
      drawer: const AppDrawer(),
      body: const Center(
        child: Text('Liste des lignes de bus et tram'),
      ),
    );
  }
}
