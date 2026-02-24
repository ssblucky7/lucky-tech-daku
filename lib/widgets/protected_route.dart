import 'package:flutter/material.dart';
import 'package:finalapp/modules/feature_access_module.dart';

class ProtectedRoute extends StatelessWidget {
  final String featureName;
  final Widget child;
  final Widget? fallback;

  const ProtectedRoute({
    super.key,
    required this.featureName,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: FeatureAccessModule.canAccessFeature(featureName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == true) {
          return child;
        }

        return fallback ??
            Scaffold(
              appBar: AppBar(title: const Text('Access Denied')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Access Denied',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You don\'t have permission to access this feature',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
      },
    );
  }
}
