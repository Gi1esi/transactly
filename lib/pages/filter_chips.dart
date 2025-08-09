import 'package:flutter/material.dart';

class FilterChipsModern extends StatelessWidget {
  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Color primary;
  final Color onBackground;

  const FilterChipsModern({
    super.key,
    required this.filters,
    required this.selectedIndex,
    required this.onSelect,
    required this.primary,
    required this.onBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: List.generate(filters.length, (index) {
        final isSelected = index == selectedIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: isSelected
                ? LinearGradient(
                    colors: [primary.withOpacity(0.9), primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            border: Border.all(color: primary, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onSelect(index),
            child: Text(
              filters[index],
              style: TextStyle(
                color: isSelected ? Colors.white : primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        );
      }),
    );
  }
}