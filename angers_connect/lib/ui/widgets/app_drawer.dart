import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Text(
              'Angers Connect',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.directions_bus),
            title: const Text('Lignes Bus / Tram'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/lines');
            },
          ),

          ListTile(
            leading: const Icon(Icons.local_parking),
            title: const Text('Parkings'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/parking');
            },
          ),

          ListTile(
            leading: const Icon(Icons.warning),
            title: const Text('Incidents'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/incidents');
            },
          ),
        ],
      ),
    );
  }
}
