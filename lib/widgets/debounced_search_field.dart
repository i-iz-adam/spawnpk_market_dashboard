import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';


class DebouncedSearchField extends StatefulWidget {
  const DebouncedSearchField({
    super.key,
    required this.onChanged,
    this.hintText = 'Search...',
    this.suggestions = const [],
    this.onSuggestionSelected,
    this.onSubmitted,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.controller,
  });

  final ValueChanged<String> onChanged;
  final String hintText;
  final List<String> suggestions;
  final ValueChanged<String>? onSuggestionSelected;
  final ValueChanged<String>? onSubmitted;
  final Duration debounceDuration;
  final TextEditingController? controller;

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  late TextEditingController _controller;
  Timer? _debounce;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _showSuggestions = false;
  bool _isSelectingSuggestion = false; // Add this flag

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
    

    if (_isSelectingSuggestion) return;
    
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      if (!mounted) return;
      widget.onChanged(_controller.text);
      _updateSuggestionsOverlay();
    });
  }

  List<String> get _filteredSuggestions {
    final query = _controller.text.toLowerCase().trim();
    if (query.isEmpty) return [];
    return widget.suggestions
        .where((s) => s.toLowerCase().contains(query))
        .take(10)
        .toList();
  }

  void _updateSuggestionsOverlay() {
    final filtered = _filteredSuggestions;
    _showSuggestions = filtered.isNotEmpty;

    if (_showSuggestions) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
  _removeOverlay();
  final overlayState = Overlay.of(context);
  _overlayEntry = OverlayEntry(
    builder: (context) => Stack(
      children: [

        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent, // Changed from opaque
            onTap: _removeOverlay,
            child: Container(color: Colors.transparent), // Add transparent container
          ),
        ),
        Positioned(
          width: _getOverlayWidth(),
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, _getOverlayHeight()),
            child: GestureDetector(
              onTap: () {}, // Prevent taps from passing through to barrier
              child: Material(
                elevation: 8,
                shadowColor: Colors.black38,
                borderRadius: BorderRadius.circular(AppRadius.md),
                color: Theme.of(context).colorScheme.surface,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _filteredSuggestions.length,
                    itemBuilder: (context, index) {
                      final s = _filteredSuggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text(s),
                        onTap: () {
                          print('Item tapped: $s');
                          _selectSuggestion(s);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  overlayState.insert(_overlayEntry!);
}

void _selectSuggestion(String s) {
  print('_selectSuggestion called with: $s');
  _isSelectingSuggestion = true;
  _controller.text = s;
  _controller.selection = TextSelection.collapsed(offset: s.length);
  _isSelectingSuggestion = false;
  
  _removeOverlay();
  
  widget.onSuggestionSelected?.call(s);
  widget.onChanged(s);
}

  double _getOverlayWidth() {
    final box = context.findRenderObject() as RenderBox?;
    return box?.size.width ?? 300;
  }

  double _getOverlayHeight() {
    final box = context.findRenderObject() as RenderBox?;
    return box?.size.height ?? 48;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _showSuggestions = false;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    _removeOverlay();
                  },
                )
              : null,
        ),
        onSubmitted: widget.onSubmitted != null
            ? (v) {
                _removeOverlay();
                widget.onSubmitted!(v.trim());
              }
            : null,
        onTapOutside: (_) => _removeOverlay(),
      ),
    );
  }
}