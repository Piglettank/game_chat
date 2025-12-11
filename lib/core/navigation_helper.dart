import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Conditional import for web vs non-web
import 'navigation_helper_stub.dart'
    if (dart.library.html) 'navigation_helper_web.dart'
    as platform;

/// Update URL on web (exported for direct use)
void updateUrlWeb(String path) {
  if (kIsWeb) {
    try {
      platform.updateUrlWeb(path);
    } catch (e) {
      debugPrint('Failed to update URL: $e');
    }
  }
}

/// Helper function to navigate and force URL update on web
void navigateWithUrlUpdate(BuildContext context, String path) {
  // Force URL update on web FIRST, then navigate
  // This ensures the URL is updated immediately
  if (kIsWeb) {
    try {
      platform.updateUrlWeb(path);
    } catch (e) {
      debugPrint('Failed to update URL: $e');
    }
  }
  
  // Navigate using go_router (maintains navigation stack)
  context.push(path);
}
