
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spawnpk_market_dashboard/pages/item_lookup_page.dart';

import '../../../providers/app_providers.dart';
import '../../../providers/item_providers.dart';
import '../../../theme/app_theme.dart';

class GlobalSearchBar extends ConsumerStatefulWidget {
  const GlobalSearchBar({super.key});

  @override
  ConsumerState<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends ConsumerState<GlobalSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {


  }

  void _saveSearch(String query) {

  }

  @override
  Widget build(BuildContext context) {
    final itemNamesAsync = ref.watch(itemNamesProvider);

    return itemNamesAsync.when(
      data: (names) => RawAutocomplete<String>(
        optionsBuilder: (textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return _recentSearches;
          }
          return names.where(
            (name) => name.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                ),
          );
        },
        onSelected: (selection) {
          _controller.text = selection;
          _saveSearch(selection);
          ref.read(selectedItemProvider.notifier).state = selection;
          

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ItemLookupPage(),
            ),
          );
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'Search for any item...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                onFieldSubmitted();
              }
            },
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: AppColors.surface,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300, maxWidth: 500),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      title: Text(option),
                      leading: options == _recentSearches 
                          ? const Icon(Icons.history, size: 18)
                          : null,
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      loading: () => const TextField(
        enabled: false,
        decoration: InputDecoration(
          hintText: 'Loading items...',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      error: (_, __) => const TextField(
        enabled: false,
        decoration: InputDecoration(
          hintText: 'Error loading items',
          prefixIcon: Icon(Icons.error),
        ),
      ),
    );
  }
}