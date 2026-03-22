// Loading Button Widget
// Reusable button component that shows loading spinner during async operations
// Prevents double-taps and provides consistent loading UI across the app

import 'package:flutter/material.dart';
import '../app_theme.dart';

class LoadingButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const LoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.elevation,
    this.padding,
    this.borderRadius,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: widget.isLoading ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor ?? theme.primaryColor,
        foregroundColor: widget.textColor ?? Colors.white,
        elevation: widget.elevation ?? AppTheme.defaultElevation,
        padding: widget.padding ?? const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? AppTheme.radiusM,
          ),
        ),
        disabledBackgroundColor: (widget.backgroundColor ?? theme.primaryColor).withOpacity(0.6),
      ),
      child: widget.isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.textColor ?? Colors.white,
                ),
              ),
            )
          : Text(
              widget.text,
              style: theme.textTheme.labelLarge?.copyWith(
                color: widget.textColor ?? Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

// Comments for academic documentation:
// - LoadingButton prevents double-taps during async operations
// - Consistent loading spinner across all buttons in the app
// - Customizable colors and styling while maintaining theme consistency
// - Disabled state prevents user interaction during loading
// - Compact spinner design fits within button bounds