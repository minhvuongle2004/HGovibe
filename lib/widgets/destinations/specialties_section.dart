import 'package:flutter/material.dart';
import 'package:smart_travel_app/models/destinations/destination.dart';
import 'specialty_card.dart';

/// Section hiển thị danh sách đặc sản với filter tabs
class SpecialtiesSection extends StatefulWidget {
  final List<Specialty> specialties;
  final Function(Specialty)? onSpecialtyTap;

  const SpecialtiesSection({
    super.key,
    required this.specialties,
    this.onSpecialtyTap,
  });

  @override
  State<SpecialtiesSection> createState() => _SpecialtiesSectionState();
}

class _SpecialtiesSectionState extends State<SpecialtiesSection> {
  String _selectedFilter = 'all'; // 'all', 'food', 'drink', 'other'

  /// Lấy danh sách các type có trong specialties
  List<String> get _availableTypes {
    final types = widget.specialties.map((s) => s.type.toLowerCase()).toSet();
    return types.toList()..sort();
  }

  List<Specialty> get _filteredSpecialties {
    if (_selectedFilter == 'all') {
      return widget.specialties;
    } else if (_selectedFilter == 'food') {
      return widget.specialties
          .where((s) => s.type.toLowerCase() == 'food')
          .toList();
    } else if (_selectedFilter == 'drink') {
      return widget.specialties
          .where((s) => s.type.toLowerCase() == 'drink')
          .toList();
    } else if (_selectedFilter == 'other') {
      return widget.specialties.where((s) {
        final type = s.type.toLowerCase();
        return type != 'food' && type != 'drink';
      }).toList();
    }
    return widget.specialties;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.specialties.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.restaurant, size: 20, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text(
              'Đặc sản & Ẩm thực',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Filter tabs - chỉ hiển thị nếu có nhiều loại
        if (_availableTypes.length > 1)
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('Tất cả', 'all'),
                const SizedBox(width: 8),
                if (_availableTypes.contains('food'))
                  _buildFilterChip('Đồ ăn', 'food'),
                if (_availableTypes.contains('food') &&
                    _availableTypes.contains('drink'))
                  const SizedBox(width: 8),
                if (_availableTypes.contains('drink'))
                  _buildFilterChip('Đồ uống', 'drink'),
                // Hiển thị "Khác" nếu có type khác ngoài food/drink
                if (_availableTypes.any(
                  (t) => t != 'food' && t != 'drink',
                )) ...[
                  const SizedBox(width: 8),
                  _buildFilterChip('Khác', 'other'),
                ],
              ],
            ),
          ),
        if (_availableTypes.length > 1) const SizedBox(height: 12),
        // List of specialties
        if (_filteredSpecialties.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Không có đặc sản nào với bộ lọc này',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ..._filteredSpecialties.asMap().entries.map((entry) {
            final index = entry.key;
            final specialty = entry.value;
            return AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 300 + (index * 50)),
              child: SpecialtyCard(
                specialty: specialty,
                onTap: widget.onSpecialtyTap != null
                    ? () => widget.onSpecialtyTap!(specialty)
                    : null,
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
      selectedColor: Colors.orange.withOpacity(0.2),
      checkmarkColor: Colors.orange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.orange : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
    );
  }
}
