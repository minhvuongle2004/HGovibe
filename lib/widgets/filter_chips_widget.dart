import 'package:flutter/material.dart';

/// Widget hiển thị filter chips horizontal scrollable
class FilterChipsWidget extends StatelessWidget {
  final List<String> chips;
  final String? selectedChip;
  final Function(String)? onChipSelected;
  final VoidCallback? onFilterTap;

  const FilterChipsWidget({
    super.key,
    required this.chips,
    this.selectedChip,
    this.onChipSelected,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: chips.length,
              itemBuilder: (context, index) {
                final chip = chips[index];
                final isSelected = chip == selectedChip;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(chip),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (onChipSelected != null) {
                        onChipSelected!(chip);
                      }
                    },
                    selectedColor: Colors.orange.withOpacity(0.2),
                    checkmarkColor: Colors.orange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.orange : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          // Filter icon
          if (onFilterTap != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: onFilterTap,
                tooltip: 'Lọc',
              ),
            ),
        ],
      ),
    );
  }
}









