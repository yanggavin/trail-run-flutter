import 'package:flutter/material.dart';
import '../../data/services/accessibility_service.dart';

/// Accessible button that adapts to system accessibility settings
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? semanticHint;
  final ButtonStyle? style;
  final bool autofocus;

  const AccessibleButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.style,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isHighContrast = AccessibilityService.isHighContrastEnabled(context);
    final colors = AccessibilityService.getAccessibilityColors(context);
    
    final accessibleStyle = style ?? ElevatedButton.styleFrom(
      backgroundColor: isHighContrast ? colors.primary : null,
      foregroundColor: isHighContrast ? colors.onPrimary : null,
      minimumSize: Size.square(AccessibilityService.getMinimumTouchTargetSize()),
    );

    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: onPressed != null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: accessibleStyle,
        autofocus: autofocus,
        child: child,
      ),
    );
  }
}

/// Accessible icon button with proper touch target size
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? semanticHint;
  final Color? color;
  final double? iconSize;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.color,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final isHighContrast = AccessibilityService.isHighContrastEnabled(context);
    final colors = AccessibilityService.getAccessibilityColors(context);
    
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: onPressed != null,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isHighContrast ? colors.onSurface : color,
          size: iconSize,
        ),
        constraints: BoxConstraints(
          minWidth: AccessibilityService.getMinimumTouchTargetSize(),
          minHeight: AccessibilityService.getMinimumTouchTargetSize(),
        ),
      ),
    );
  }
}

/// Accessible text that adapts to system text settings
class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? semanticLabel;

  const AccessibleText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isHighContrast = AccessibilityService.isHighContrastEnabled(context);
    final colors = AccessibilityService.getAccessibilityColors(context);
    final textStyles = AccessibilityService.getAccessibilityTextStyles(context);
    
    TextStyle? accessibleStyle = style;
    if (isHighContrast) {
      accessibleStyle = style?.copyWith(
        color: colors.onSurface,
      ) ?? TextStyle(color: colors.onSurface);
    }

    return Semantics(
      label: semanticLabel ?? text,
      child: Text(
        text,
        style: accessibleStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// Accessible card with proper contrast and touch targets
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isHighContrast = AccessibilityService.isHighContrastEnabled(context);
    final colors = AccessibilityService.getAccessibilityColors(context);
    
    Widget cardChild = Card(
      margin: margin,
      color: isHighContrast ? colors.surface : null,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );

    if (onTap != null) {
      cardChild = Semantics(
        label: semanticLabel,
        hint: semanticHint,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: cardChild,
        ),
      );
    } else if (semanticLabel != null) {
      cardChild = Semantics(
        label: semanticLabel,
        child: cardChild,
      );
    }

    return cardChild;
  }
}

/// Accessible list tile with proper semantics
class AccessibleListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String semanticLabel;
  final String? semanticHint;
  final bool enabled;

  const AccessibleListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    required this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isHighContrast = AccessibilityService.isHighContrastEnabled(context);
    final colors = AccessibilityService.getAccessibilityColors(context);
    
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      enabled: enabled,
      child: ListTile(
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: trailing,
        onTap: enabled ? onTap : null,
        tileColor: isHighContrast ? colors.surface : null,
        textColor: isHighContrast ? colors.onSurface : null,
        iconColor: isHighContrast ? colors.onSurface : null,
      ),
    );
  }
}

/// Accessible progress indicator with semantic announcements
class AccessibleProgressIndicator extends StatefulWidget {
  final double? value;
  final String semanticLabel;
  final String? semanticValue;
  final bool announceProgress;

  const AccessibleProgressIndicator({
    super.key,
    this.value,
    required this.semanticLabel,
    this.semanticValue,
    this.announceProgress = false,
  });

  @override
  State<AccessibleProgressIndicator> createState() => _AccessibleProgressIndicatorState();
}

class _AccessibleProgressIndicatorState extends State<AccessibleProgressIndicator> {
  double? _lastAnnouncedValue;

  @override
  void didUpdateWidget(AccessibleProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.announceProgress && 
        widget.value != null && 
        oldWidget.value != widget.value) {
      _announceProgressIfNeeded();
    }
  }

  void _announceProgressIfNeeded() {
    if (widget.value == null) return;
    
    final currentValue = (widget.value! * 100).round();
    final lastValue = _lastAnnouncedValue != null 
        ? (_lastAnnouncedValue! * 100).round() 
        : null;
    
    // Announce every 10% change
    if (lastValue == null || (currentValue - lastValue).abs() >= 10) {
      AccessibilityService.announceToScreenReader('$currentValue percent complete');
      _lastAnnouncedValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHighContrast = AccessibilityService.isHighContrastEnabled(context);
    final colors = AccessibilityService.getAccessibilityColors(context);
    
    return Semantics(
      label: widget.semanticLabel,
      value: widget.semanticValue ?? 
          (widget.value != null ? '${(widget.value! * 100).round()}%' : null),
      child: LinearProgressIndicator(
        value: widget.value,
        backgroundColor: isHighContrast ? colors.surface : null,
        valueColor: AlwaysStoppedAnimation<Color>(
          isHighContrast ? colors.primary : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Accessible switch with proper semantics
class AccessibleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;
  final String? semanticHint;

  const AccessibleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    final isHighContrast = AccessibilityService.isHighContrastEnabled(context);
    final colors = AccessibilityService.getAccessibilityColors(context);
    
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      toggled: value,
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: isHighContrast ? colors.primary : null,
        inactiveThumbColor: isHighContrast ? colors.surface : null,
        inactiveTrackColor: isHighContrast ? colors.onSurface.withOpacity(0.3) : null,
      ),
    );
  }
}

/// Accessible slider with proper semantics and announcements
class AccessibleSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String semanticLabel;
  final String Function(double)? semanticFormatterCallback;

  const AccessibleSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    required this.semanticLabel,
    this.semanticFormatterCallback,
  });

  @override
  State<AccessibleSlider> createState() => _AccessibleSliderState();
}

class _AccessibleSliderState extends State<AccessibleSlider> {
  @override
  Widget build(BuildContext context) {
    final isHighContrast = AccessibilityService.isHighContrastEnabled(context);
    final colors = AccessibilityService.getAccessibilityColors(context);
    
    return Semantics(
      label: widget.semanticLabel,
      value: widget.semanticFormatterCallback?.call(widget.value) ?? 
          widget.value.toStringAsFixed(1),
      slider: true,
      child: Slider(
        value: widget.value,
        onChanged: widget.onChanged,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        activeColor: isHighContrast ? colors.primary : null,
        inactiveColor: isHighContrast ? colors.onSurface.withOpacity(0.3) : null,
        thumbColor: isHighContrast ? colors.primary : null,
      ),
    );
  }
}