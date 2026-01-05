import 'package:flutter/material.dart';

class GenericInfoDialog extends StatefulWidget {
  final String title;
  final List<MapEntry<String, dynamic>> fields;
  final Future<bool> Function()? isFavorite;
  final Future<void> Function()? onToggleFavorite;

  const GenericInfoDialog({
    super.key,
    required this.title,
    required this.fields,
    this.isFavorite,
    this.onToggleFavorite,
  });

  @override
  State<GenericInfoDialog> createState() => _GenericInfoDialogState();
}

class _GenericInfoDialogState extends State<GenericInfoDialog> {
  bool _isFavorite = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    if (widget.isFavorite != null) {
      try {
        final result = await widget.isFavorite!();
        if (mounted) setState(() { _isFavorite = result; _loading = false; });
      } catch (_) {
        if (mounted) setState(() { _isFavorite = false; _loading = false; });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.onToggleFavorite != null) {
      try {
        await widget.onToggleFavorite!();
        if (mounted) setState(() => _isFavorite = !_isFavorite);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showFavorite = widget.isFavorite != null && widget.onToggleFavorite != null;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(widget.title)),
          if (showFavorite && !_loading)
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.star : Icons.star_border,
                color: _isFavorite ? Colors.amber : null,
              ),
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.fields.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${entry.key} : ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(entry.value?.toString() ?? '-', softWrap: true)),
                ],
              ),
            )).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer')),
      ],
    );
  }
}
