import 'dart:async';
import 'package:flutter/material.dart';

/// Widget générique de barre de recherche avec suggestions et sélection.
/// [items] : liste d'éléments à filtrer
/// [itemToString] : fonction pour extraire le texte à rechercher
/// [onSelected] : callback appelé avec l'élément sélectionné
class SearchBarAutocomplete<T extends Object> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemToString;
  final void Function(T?) onSelected;
  final String hintText;
  final TextEditingController? controller;

  const SearchBarAutocomplete({
    super.key,
    required this.items,
    required this.itemToString,
    required this.onSelected,
    this.hintText = 'Rechercher...',
    this.controller,
  });

  @override
  State<SearchBarAutocomplete<T>> createState() => _SearchBarAutocompleteState<T>();
}

class _SearchBarAutocompleteState<T extends Object> extends State<SearchBarAutocomplete<T>> {
  late TextEditingController _controller;
  bool _isExternalController = false;
  Timer? _debounce;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isExternalController = true;
    } else {
      _controller = TextEditingController();
    }
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    if (!_isExternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final query = _controller.text;
    if (_lastQuery == query) return;
    _lastQuery = query;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSelected(null); // null pour signaler un changement de texte
    });
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<T>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return <T>[];
        }
        return widget.items.where((item) =>
          widget.itemToString(item).toLowerCase().contains(textEditingValue.text.toLowerCase())
        );
      },
      displayStringForOption: widget.itemToString,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Utilise toujours le contrôleur externe si fourni
        final effectiveController = widget.controller ?? controller;
        if (controller != effectiveController) {
          controller.text = effectiveController.text;
        }
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: effectiveController,
            focusNode: focusNode,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: widget.hintText,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: effectiveController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        effectiveController.clear();
                        widget.onSelected(null);
                      },
                    )
                  : null,
            ),
          ),
        );
      },
      onSelected: widget.onSelected,
    );
  }
}
