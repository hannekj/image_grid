import 'package:flutter/services.dart';

/// Light haptics for editor craft.
class AppFeedback {
  static Future<void> selection() => HapticFeedback.selectionClick();

  static Future<void> light() => HapticFeedback.lightImpact();

  static Future<void> medium() => HapticFeedback.mediumImpact();

  static Future<void> success() => HapticFeedback.mediumImpact();
}
