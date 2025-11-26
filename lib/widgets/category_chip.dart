import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget hiển thị category chip (circular button với hình ảnh)
/// Style giống với thiết kế mẫu
class CategoryChip extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool isSelected;

  const CategoryChip({
    super.key,
    required this.label,
    this.imageUrl,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            // Circular image container
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Colors.orange
                      : Colors.grey.withOpacity(0.3),
                  width: isSelected ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.place,
                            size: 30,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.place,
                          size: 30,
                          color: Colors.grey[600],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // Label text
            SizedBox(
              width: 70,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.orange[700] : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget hiển thị danh sách category chips (horizontal scrollable)
class CategoryChipList extends StatelessWidget {
  final List<CategoryItem> categories;
  final String? selectedCategory;
  final Function(String)? onCategorySelected;

  const CategoryChipList({
    super.key,
    required this.categories,
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category.id;
          return CategoryChip(
            label: category.label,
            imageUrl: category.imageUrl,
            isSelected: isSelected,
            onTap: () => onCategorySelected?.call(category.id),
          );
        },
      ),
    );
  }
}

/// Model cho category item
class CategoryItem {
  final String id;
  final String label;
  final String? imageUrl;

  CategoryItem({
    required this.id,
    required this.label,
    this.imageUrl,
  });
}

