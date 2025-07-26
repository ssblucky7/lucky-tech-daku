import 'package:flutter/material.dart';
import 'package:finalapp/services/activity_tracking_service.dart';

/// A widget that automatically tracks screen views in Firebase Analytics
class TrackedScreen extends StatefulWidget {
  final String screenName;
  final Widget child;
  final Map<String, dynamic>? screenParameters;

  const TrackedScreen({
    super.key,
    required this.screenName,
    required this.child,
    this.screenParameters,
  });

  @override
  State<TrackedScreen> createState() => _TrackedScreenState();
}

class _TrackedScreenState extends State<TrackedScreen> with RouteAware {
  @override
  void initState() {
    super.initState();
    _trackScreenView();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // You can also register with a RouteObserver here if needed
  }

  @override
  void dispose() {
    // Unregister from RouteObserver if needed
    super.dispose();
  }

  void _trackScreenView() async {
    try {
      await ActivityTrackingService.trackScreenView(widget.screenName);
    } catch (e) {
      // Silently handle tracking errors
      debugPrint('Error tracking screen view: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension method to wrap a widget with screen tracking
extension TrackableWidget on Widget {
  Widget withScreenTracking(String screenName, {Map<String, dynamic>? parameters}) {
    return TrackedScreen(
      screenName: screenName,
      screenParameters: parameters,
      child: this,
    );
  }
}