import 'package:flutter/material.dart';

/// Widget générique de barre de recherche réutilisable.
/// [items] : liste d'éléments à filtrer
/// [itemToString] : fonction pour extraire le texte à rechercher
/// [onFiltered] : callback appelé avec la liste filtrée
class SearchBar<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemToString;
  final void Function(List<T>) onFiltered;
  final String hintText;

  const SearchBar({
    super.key,
    required this.items,
    required this.itemToString,
    required this.onFiltered,
    this.hintText = 'Rechercher...'
  });

  @override
  State<SearchBar<T>> createState() => _SearchBarState<T>();
}

class _SearchBarState<T> extends State<SearchBar<T>> {
  late TextEditingController _controller;
  List<T> _filtered = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _filtered = widget.items;
  }

  @override
  void didUpdateWidget(covariant SearchBar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filtered = widget.items;
      _filter(_controller.text);
    }
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.items;
      } else {
        _filtered = widget.items.where((item) =>
          widget.itemToString(item).toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
      widget.onFiltered(_filtered);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: widget.hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: _filter,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

