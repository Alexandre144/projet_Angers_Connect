import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Angers Connect'),
      ),
      drawer: const AppDrawer(),
      body: const Center(
        child: Text(
          'Bienvenue sur Angers Connect',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
