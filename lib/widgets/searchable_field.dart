import 'package:flutter/material.dart';

/// A generic "type to search" field with a dropdown list of matches,
/// built on Flutter's built-in Autocomplete widget (no extra package needed).
class SearchableField<T extends Object> extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final List<T> options;
  final String Function(T option) displayString;
  final bool Function(T option, String query) filter;
  final void Function(T option) onSelected;
  final Widget Function(T option) optionBuilder;
  final TextEditingValue initialValue;
  final bool showClear;
  final VoidCallback? onClear;

  const SearchableField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.options,
    required this.displayString,
    required this.filter,
    required this.onSelected,
    required this.optionBuilder,
    this.initialValue = const TextEditingValue(),
    this.showClear = false,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<T>(
          initialValue: initialValue,
          displayStringForOption: displayString,
          optionsBuilder: (TextEditingValue value) {
            if (value.text.isEmpty) return options;
            final query = value.text.toLowerCase();
            return options.where((o) => filter(o, query));
          },
          onSelected: onSelected,
          fieldViewBuilder: (context, controller, focusNode, onSubmit) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle( fontSize: 13,),
                hintText: hint,
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(icon, size: 20),
                suffixIcon: showClear
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          controller.clear();
                          onClear?.call();
                        },
                      )
                    : const Icon(Icons.arrow_drop_down),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelectedCb, opts) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: opts.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text("No matches found"),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: opts.length,
                            itemBuilder: (context, index) {
                              final option = opts.elementAt(index);
                              return InkWell(
                                onTap: () => onSelectedCb(option),
                                child: optionBuilder(option),
                              );
                            },
                          ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}