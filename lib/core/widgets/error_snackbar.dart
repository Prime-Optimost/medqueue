// Error Snackbar Widget
// Consistent error notification component across the entire application
// Provides uniform error messaging with proper styling and accessibility

import 'package:flutter/material.dart';
import '../app_theme.dart';

class ErrorSnackbar {
  static void show(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 24,
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        duration: duration ?? const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        margin: const EdgeInsets.all(AppTheme.spacingM),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Convenience method for network errors
  static void showNetworkError(BuildContext context) {
    show(context, 'Network connection error. Please check your internet connection.');
  }

  // Convenience method for server errors
  static void showServerError(BuildContext context) {
    show(context, 'Server error. Please try again later.');
  }

  // Convenience method for validation errors
  static void showValidationError(BuildContext context, String message) {
    show(context, message);
  }

  // Convenience method for unauthorized access
  static void showUnauthorizedError(BuildContext context) {
    show(context, 'Session expired. Please login again.');
  }
}

// Comments for academic documentation:
// - ErrorSnackbar provides consistent error notifications
// - Icon and text layout for clear visual hierarchy
// - Floating behavior with rounded corners for modern UI
// - Dismiss action for user control
// - Convenience methods for common error types
// - Customizable duration for different error severities