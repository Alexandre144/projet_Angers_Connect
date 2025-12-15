import 'package:flutter/material.dart';

/// Widget générique pour afficher les informations d'un objet sous forme de clé/valeur.
class GenericInfoDialog extends StatelessWidget {
  final String title;
  final List<MapEntry<String, dynamic>> fields;

  const GenericInfoDialog({
    super.key,
    required this.title,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: fields.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key} : ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text(
                    entry.value?.toString() ?? '-',
                    softWrap: true,
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

