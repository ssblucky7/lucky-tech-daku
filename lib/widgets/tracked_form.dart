import 'package:flutter/material.dart';
import 'package:finalapp/services/activity_tracking_service.dart';

/// A form that tracks user submissions with Firebase Analytics
class TrackedForm extends StatefulWidget {
  final String formName;
  final String? screenName;
  final Widget child;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;
  final bool trackFieldChanges;
  final Map<String, dynamic>? metadata;

  const TrackedForm({
    super.key,
    required this.formName,
    this.screenName,
    required this.child,
    required this.formKey,
    required this.onSubmit,
    this.trackFieldChanges = false,
    this.metadata,
  });

  @override
  State<TrackedForm> createState() => _TrackedFormState();
}

class _TrackedFormState extends State<TrackedForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: widget.child,
    );
  }

  void trackFormSubmission(Map<String, dynamic> formData) async {
    try {
      // Sanitize form data to remove sensitive information
      final sanitizedData = ActivityTrackingService.sanitizeFormData(formData);

      final formMetadata = <String, dynamic>{
        'form_name': widget.formName,
        if (widget.screenName != null) 'screen_name': widget.screenName,
      };

      // Add any additional metadata
      if (widget.metadata != null) {
        formMetadata.addAll(widget.metadata!);
      }

      await ActivityTrackingService.trackFormSubmit(
        widget.formName,
        formData: sanitizedData,
        screenName: widget.screenName,
      );
    } catch (e) {
      // Silently handle tracking errors
      debugPrint('Error tracking form submission: $e');
    }
  }
}

/// A tracked form field that reports changes to Firebase Analytics
class TrackedFormField extends StatefulWidget {
  final String fieldName;
  final String formName;
  final String? screenName;
  final Widget child;
  final bool trackChanges;
  final Map<String, dynamic>? metadata;

  const TrackedFormField({
    super.key,
    required this.fieldName,
    required this.formName,
    this.screenName,
    required this.child,
    this.trackChanges = false,
    this.metadata,
  });

  @override
  State<TrackedFormField> createState() => _TrackedFormFieldState();
}

class _TrackedFormFieldState extends State<TrackedFormField> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void trackFieldChange(String value) async {
    if (!widget.trackChanges) return;

    try {
      final fieldMetadata = <String, dynamic>{
        'field_name': widget.fieldName,
        'form_name': widget.formName,
        if (widget.screenName != null) 'screen_name': widget.screenName,
      };

      // Add any additional metadata
      if (widget.metadata != null) {
        fieldMetadata.addAll(widget.metadata!);
      }

      // Don't track the actual value for privacy reasons
      await ActivityTrackingService.trackFormFieldChange(
        widget.fieldName,
        widget.formName,
        screenName: widget.screenName,
      );
    } catch (e) {
      // Silently handle tracking errors
      debugPrint('Error tracking field change: $e');
    }
  }
}

/// A tracked submit button for forms
class TrackedSubmitButton extends StatelessWidget {
  final String buttonName;
  final String formName;
  final String? screenName;
  final GlobalKey<FormState> formKey;
  final Function(Map<String, dynamic>) onValidSubmit;
  final Widget child;
  final ButtonStyle? style;
  final bool isLoading;
  final Map<String, dynamic>? formData;
  final Map<String, dynamic>? metadata;

  const TrackedSubmitButton({
    super.key,
    required this.buttonName,
    required this.formName,
    this.screenName,
    required this.formKey,
    required this.onValidSubmit,
    required this.child,
    this.style,
    this.isLoading = false,
    this.formData,
    this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: style,
      onPressed: isLoading
          ? null
          : () {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                
                // Track the form submission
                _trackFormSubmission();
                
                // Execute the provided callback
                onValidSubmit(formData ?? {});
              }
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

  void _trackFormSubmission() async {
    try {
      // Sanitize form data to remove sensitive information
      final sanitizedData = ActivityTrackingService.sanitizeFormData(formData ?? {});

      final submitMetadata = <String, dynamic>{
        'button_name': buttonName,
        'form_name': formName,
        if (screenName != null) 'screen_name': screenName,
      };

      // Add any additional metadata
      if (metadata != null) {
        submitMetadata.addAll(metadata!);
      }

      await ActivityTrackingService.trackFormSubmit(
        formName,
        formData: sanitizedData,
        screenName: screenName,
      );
    } catch (e) {
      // Silently handle tracking errors
      debugPrint('Error tracking form submission: $e');
    }
  }
}