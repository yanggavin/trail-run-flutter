import 'package:flutter/material.dart';

import '../../domain/enums/privacy_level.dart';

/// Widget for selecting privacy level with visual indicators
class PrivacyLevelSelector extends StatelessWidget {
  final PrivacyLevel selectedLevel;
  final ValueChanged<PrivacyLevel> onChanged;

  const PrivacyLevelSelector({
    super.key,
    required this.selectedLevel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: PrivacyLevel.values.map((level) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _PrivacyLevelOption(
            level: level,
            isSelected: selectedLevel == level,
            onTap: () => onChanged(level),
          ),
        );
      }).toList(),
    );
  }
}

/// Individual privacy level option
class _PrivacyLevelOption extends StatelessWidget {
  final PrivacyLevel level;
  final bool isSelected;
  final VoidCallback onTap;

  const _PrivacyLevelOption({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? colorScheme.primary 
              : colorScheme.outline.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected 
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
        ),
        child: Row(
          children: [
            // Privacy level icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  level.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Privacy level details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getDescription(level),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 24,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: colorScheme.outline,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  /// Get icon background color based on privacy level
  Color _getIconBackgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (level) {
      case PrivacyLevel.private:
        return colorScheme.errorContainer;
      case PrivacyLevel.friends:
        return colorScheme.tertiaryContainer;
      case PrivacyLevel.public:
        return colorScheme.primaryContainer;
    }
  }

  /// Get description for privacy level
  String _getDescription(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.private:
        return 'Only you can see your activities. Location data is rounded to ~1km accuracy when shared.';
      case PrivacyLevel.friends:
        return 'Your friends and followers can see your activities. Location data is rounded to ~100m accuracy.';
      case PrivacyLevel.public:
        return 'Anyone can see your activities with full location accuracy. Use with caution.';
    }
  }
}