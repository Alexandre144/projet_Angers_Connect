import 'package:flutter/material.dart';

class FavoritesListDialog extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> favorites;
  final String Function(Map<String, dynamic>) itemTitle;
  final void Function(Map<String, dynamic>) onItemTap;

  const FavoritesListDialog({
    super.key,
    required this.title,
    required this.favorites,
    required this.itemTitle,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: favorites.isEmpty
          ? const Padding(padding: EdgeInsets.all(16.0), child: Text('Aucun favori enregistré'))
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final item = favorites[index];
                  return ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text(itemTitle(item)),
                    onTap: () {
                      Navigator.of(context).pop();
                      onItemTap(item);
                    },
                  );
                },
              ),
            ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer')),
      ],
    );
  }
}

