import 'package:flutter/material.dart';

/// Extension on BuildContext to provide responsive helpers
extension ContextExtensions on BuildContext {
  /// Check if the current device is a mobile device (width < 600)
  bool get isMobile => MediaQuery.of(this).size.width < 600;

  /// Check if the current device is a tablet (600 <= width < 1200)
  bool get isTablet =>
      MediaQuery.of(this).size.width >= 600 &&
      MediaQuery.of(this).size.width < 1200;

  /// Check if the current device is a desktop (width >= 1200)
  bool get isDesktop => MediaQuery.of(this).size.width >= 1200;

  /// Get horizontal padding based on screen size
  double get paddingHorizontal {
    if (isMobile) return 16.0;
    if (isTablet) return 24.0;
    return 32.0;
  }

  /// Get vertical padding based on screen size
  double get paddingVertical {
    if (isMobile) return 12.0;
    if (isTablet) return 16.0;
    return 24.0;
  }

  /// Get the screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get the screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get the device pixel ratio
  double get devicePixelRatio => MediaQuery.of(this).devicePixelRatio;

  /// Check if the device is in landscape mode
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;

  /// Check if the device is in portrait mode
  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;
}
