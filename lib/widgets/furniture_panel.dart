import 'package:flutter/material.dart';

import '../models/furniture.dart';
import '../utils/app_constants.dart';

class FurniturePanel extends StatelessWidget {
  const FurniturePanel({
    super.key,
    required this.items,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  });

  final List<FurnitureSpec> items;
  final List<String> tags;
  final String selectedTag;
  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Furniture', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Actual dimensions (meters)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black.withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 20),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      color: kPanelBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tags.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final String tag = tags[index];
                return ChoiceChip(
                  label: Text(tag),
                  selected: tag == selectedTag,
                  onSelected: (_) => onTagSelected(tag),
                  selectedColor: kAccentPurple.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: tag == selectedTag ? kAccentPurple : Colors.black87,
                    fontWeight: tag == selectedTag ? FontWeight.w600 : FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) => FurnitureCard(spec: items[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class FurnitureCard extends StatelessWidget {
  const FurnitureCard({super.key, required this.spec});

  final FurnitureSpec spec;

  @override
  Widget build(BuildContext context) {
    return Draggable<FurnitureSpec>(
      data: spec,
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: _FurnitureCardContent(spec: spec),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _FurnitureCardContent(spec: spec),
      ),
      child: _FurnitureCardContent(spec: spec),
    );
  }
}

class _FurnitureCardContent extends StatelessWidget {
  const _FurnitureCardContent({required this.spec});

  final FurnitureSpec spec;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(spec.name, style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            spec.sizeLabel,
            style: textTheme.bodyMedium?.copyWith(
                  color: Colors.black.withOpacity(0.55),
                ),
          ),
        ],
      ),
    );
  }
}
