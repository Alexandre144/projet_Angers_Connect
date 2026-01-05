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
      // On contraint la hauteur pour que le contenu puisse défiler si nécessaire
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: fields.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key} : ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  // Le texte occupe l'espace restant et wrap normalement. On évite tout fit/scale.
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