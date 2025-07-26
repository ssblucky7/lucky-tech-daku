import 'package:flutter/material.dart';
import 'package:finalapp/services/activity_tracking_service.dart';

/// A button that tracks user interactions with Firebase Analytics
class TrackedButton extends StatelessWidget {
  final String buttonName;
  final String? screenName;
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool isLoading;
  final Map<String, dynamic>? metadata;

  const TrackedButton({
    super.key,
    required this.buttonName,
    this.screenName,
    required this.onPressed,
    required this.child,
    this.style,
    this.isLoading = false,
    this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: style,
      onPressed: isLoading
          ? null
          : () {
              // Track the button click
              _trackButtonClick();
              // Execute the provided callback
              onPressed();
            },
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : child,
    );
  }

  void _trackButtonClick() async {
    try {
      final buttonMetadata = <String, dynamic>{
        'button_name': buttonName,
        if (screenName != null) 'screen_name': screenName,
      };

      // Add any additional metadata
      if (metadata != null) {
        buttonMetadata.addAll(metadata!);
      }

      await ActivityTrackingService.trackButtonClick(
        buttonName,
        screenName: screenName,
      );
    } catch (e) {
      // Silently handle tracking errors
      debugPrint('Error tracking button click: $e');
    }
  }
}

/// A text button that tracks user interactions with Firebase Analytics
class TrackedTextButton extends StatelessWidget {
  final String buttonName;
  final String? screenName;
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool isLoading;
  final Map<String, dynamic>? metadata;

  const TrackedTextButton({
    super.key,
    required this.buttonName,
    this.screenName,
    required this.onPressed,
    required this.child,
    this.style,
    this.isLoading = false,
    this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: style,
      onPressed: isLoading
          ? null
          : () {
              // Track the button click
              _trackButtonClick();
              // Execute the provided callback
              onPressed();
            },
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : child,
    );
  }

  void _trackButtonClick() async {
    try {
      final buttonMetadata = <String, dynamic>{
        'button_name': buttonName,
        'button_type': 'text',
        if (screenName != null) 'screen_name': screenName,
      };

      // Add any additional metadata
      if (metadata != null) {
        buttonMetadata.addAll(metadata!);
      }

      await ActivityTrackingService.trackButtonClick(
        buttonName,
        screenName: screenName,
      );
    } catch (e) {
      // Silently handle tracking errors
      debugPrint('Error tracking button click: $e');
    }
  }
}

/// An icon button that tracks user interactions with Firebase Analytics
class TrackedIconButton extends StatelessWidget {
  final String buttonName;
  final String? screenName;
  final VoidCallback onPressed;
  final Icon icon;
  final Color? color;
  final bool isLoading;
  final Map<String, dynamic>? metadata;

  const TrackedIconButton({
    super.key,
    required this.buttonName,
    this.screenName,
    required this.onPressed,
    required this.icon,
    this.color,
    this.isLoading = false,
    this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : icon,
      color: color,
      onPressed: isLoading
          ? null
          : () {
              // Track the button click
              _trackButtonClick();
              // Execute the provided callback
              onPressed();
            },
    );
  }

  void _trackButtonClick() async {
    try {
      final buttonMetadata = <String, dynamic>{
        'button_name': buttonName,
        'button_type': 'icon',
        if (screenName != null) 'screen_name': screenName,
      };

      // Add any additional metadata
      if (metadata != null) {
        buttonMetadata.addAll(metadata!);
      }

      await ActivityTrackingService.trackButtonClick(
        buttonName,
        screenName: screenName,
      );
    } catch (e) {
      // Silently handle tracking errors
      debugPrint('Error tracking button click: $e');
    }
  }
}