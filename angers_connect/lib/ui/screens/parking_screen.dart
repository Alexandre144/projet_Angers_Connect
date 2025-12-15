import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class ParkingScreen extends StatelessWidget {
  const ParkingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parkings'),
      ),
      drawer: const AppDrawer(),
      body: const Center(
        child: Text('Parkings vélos et voitures'),
      ),
    );
  }
}
