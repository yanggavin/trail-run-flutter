import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for handling accessibility features
class AccessibilityService {
  static const MethodChannel _channel = MethodChannel('com.trailrun.accessibility');

  /// Check if screen reader is enabled
  static bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// Check if high contrast mode is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Check if bold text is enabled
  static bool isBoldTextEnabled(BuildContext context) {
    return MediaQuery.of(context).boldText;
  }

  /// Get text scale factor
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }

  /// Check if reduce motion is enabled
  static bool isReduceMotionEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Announce text to screen reader
  static void announceToScreenReader(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Get accessibility-appropriate colors
  static AccessibilityColors getAccessibilityColors(BuildContext context) {
    final theme = Theme.of(context);
    final isHighContrast = isHighContrastEnabled(context);
    
    if (isHighContrast) {
      return AccessibilityColors(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.black,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        background: Colors.white,
        onBackground: Colors.black,
        error: Colors.red.shade900,
        onError: Colors.white,
      );
    } else {
      return AccessibilityColors(
        primary: theme.colorScheme.primary,
        onPrimary: theme.colorScheme.onPrimary,
        secondary: theme.colorScheme.secondary,
        onSecondary: theme.colorScheme.onSecondary,
        surface: theme.colorScheme.surface,
        onSurface: theme.colorScheme.onSurface,
        background: theme.colorScheme.background,
        onBackground: theme.colorScheme.onBackground,
        error: theme.colorScheme.error,
        onError: theme.colorScheme.onError,
      );
    }
  }

  /// Get accessibility-appropriate text styles
  static AccessibilityTextStyles getAccessibilityTextStyles(BuildContext context) {
    final theme = Theme.of(context);
    final isBoldText = isBoldTextEnabled(context);
    final textScaleFactor = getTextScaleFactor(context);
    
    return AccessibilityTextStyles(
      headline1: theme.textTheme.displayLarge?.copyWith(
        fontWeight: isBoldText ? FontWeight.bold : FontWeight.normal,
        fontSize: (theme.textTheme.displayLarge?.fontSize ?? 32) * textScaleFactor,
      ),
      headline2: theme.textTheme.displayMedium?.copyWith(
        fontWeight: isBoldText ? FontWeight.bold : FontWeight.normal,
        fontSize: (theme.textTheme.displayMedium?.fontSize ?? 28) * textScaleFactor,
      ),
      headline3: theme.textTheme.displaySmall?.copyWith(
        fontWeight: isBoldText ? FontWeight.bold : FontWeight.normal,
        fontSize: (theme.textTheme.displaySmall?.fontSize ?? 24) * textScaleFactor,
      ),
      body1: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: isBoldText ? FontWeight.w600 : FontWeight.normal,
        fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) * textScaleFactor,
      ),
      body2: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: isBoldText ? FontWeight.w600 : FontWeight.normal,
        fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * textScaleFactor,
      ),
      button: theme.textTheme.labelLarge?.copyWith(
        fontWeight: isBoldText ? FontWeight.bold : FontWeight.w600,
        fontSize: (theme.textTheme.labelLarge?.fontSize ?? 14) * textScaleFactor,
      ),
    );
  }

  /// Create accessible button with proper semantics
  static Widget createAccessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    required String semanticLabel,
    String? semanticHint,
    bool isEnabled = true,
    ButtonStyle? style,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: isEnabled,
      child: ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }

  /// Create accessible text field with proper semantics
  static Widget createAccessibleTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    String? semanticLabel,
    String? errorText,
    bool obscureText = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Semantics(
      label: semanticLabel ?? labelText,
      textField: true,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          errorText: errorText,
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
      ),
    );
  }

  /// Create accessible icon with semantic label
  static Widget createAccessibleIcon({
    required IconData icon,
    required String semanticLabel,
    Color? color,
    double? size,
  }) {
    return Semantics(
      label: semanticLabel,
      child: Icon(
        icon,
        color: color,
        size: size,
      ),
    );
  }

  /// Create accessible progress indicator
  static Widget createAccessibleProgressIndicator({
    required double? value,
    required String semanticLabel,
    String? semanticValue,
  }) {
    return Semantics(
      label: semanticLabel,
      value: semanticValue ?? (value != null ? '${(value * 100).round()}%' : null),
      child: LinearProgressIndicator(value: value),
    );
  }

  /// Create accessible list tile
  static Widget createAccessibleListTile({
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    required VoidCallback? onTap,
    required String semanticLabel,
    String? semanticHint,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      child: ListTile(
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  /// Get minimum touch target size for accessibility
  static double getMinimumTouchTargetSize() {
    return 48.0; // Material Design minimum touch target
  }

  /// Check if touch target meets accessibility requirements
  static bool isTouchTargetAccessible(Size size) {
    final minSize = getMinimumTouchTargetSize();
    return size.width >= minSize && size.height >= minSize;
  }

  /// Create accessible gesture detector with proper touch target size
  static Widget createAccessibleGestureDetector({
    required Widget child,
    required VoidCallback? onTap,
    required String semanticLabel,
    String? semanticHint,
    Size? minimumSize,
  }) {
    final minSize = minimumSize ?? Size.square(getMinimumTouchTargetSize());
    
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(
            minWidth: minSize.width,
            minHeight: minSize.height,
          ),
          child: child,
        ),
      ),
    );
  }

  /// Get platform-specific accessibility settings
  static Future<PlatformAccessibilitySettings> getPlatformAccessibilitySettings() async {
    try {
      if (Platform.isIOS) {
        final result = await _channel.invokeMethod<Map>('getIOSAccessibilitySettings');
        return PlatformAccessibilitySettings.fromMap(result ?? {});
      } else if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<Map>('getAndroidAccessibilitySettings');
        return PlatformAccessibilitySettings.fromMap(result ?? {});
      }
    } catch (e) {
      // Return default settings if platform channel fails
    }
    
    return PlatformAccessibilitySettings();
  }

  /// Create accessible theme based on system settings
  static ThemeData createAccessibleTheme({
    required BuildContext context,
    required ThemeData baseTheme,
  }) {
    final isHighContrast = isHighContrastEnabled(context);
    final isBoldText = isBoldTextEnabled(context);
    final textScaleFactor = getTextScaleFactor(context);
    
    if (isHighContrast) {
      return baseTheme.copyWith(
        colorScheme: const ColorScheme.highContrast(),
        textTheme: baseTheme.textTheme.apply(
          fontWeightDelta: isBoldText ? 2 : 0,
          fontSizeFactor: textScaleFactor,
        ),
      );
    } else {
      return baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(
          fontWeightDelta: isBoldText ? 1 : 0,
          fontSizeFactor: textScaleFactor,
        ),
      );
    }
  }
}

class AccessibilityColors {
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color surface;
  final Color onSurface;
  final Color background;
  final Color onBackground;
  final Color error;
  final Color onError;

  const AccessibilityColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.surface,
    required this.onSurface,
    required this.background,
    required this.onBackground,
    required this.error,
    required this.onError,
  });
}

class AccessibilityTextStyles {
  final TextStyle? headline1;
  final TextStyle? headline2;
  final TextStyle? headline3;
  final TextStyle? body1;
  final TextStyle? body2;
  final TextStyle? button;

  const AccessibilityTextStyles({
    this.headline1,
    this.headline2,
    this.headline3,
    this.body1,
    this.body2,
    this.button,
  });
}

class PlatformAccessibilitySettings {
  final bool isScreenReaderEnabled;
  final bool isHighContrastEnabled;
  final bool isBoldTextEnabled;
  final bool isReduceMotionEnabled;
  final double textScaleFactor;

  const PlatformAccessibilitySettings({
    this.isScreenReaderEnabled = false,
    this.isHighContrastEnabled = false,
    this.isBoldTextEnabled = false,
    this.isReduceMotionEnabled = false,
    this.textScaleFactor = 1.0,
  });

  factory PlatformAccessibilitySettings.fromMap(Map<dynamic, dynamic> map) {
    return PlatformAccessibilitySettings(
      isScreenReaderEnabled: map['isScreenReaderEnabled'] ?? false,
      isHighContrastEnabled: map['isHighContrastEnabled'] ?? false,
      isBoldTextEnabled: map['isBoldTextEnabled'] ?? false,
      isReduceMotionEnabled: map['isReduceMotionEnabled'] ?? false,
      textScaleFactor: (map['textScaleFactor'] ?? 1.0).toDouble(),
    );
  }
}