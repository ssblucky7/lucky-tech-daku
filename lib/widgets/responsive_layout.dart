import 'package:flutter/material.dart';
import 'package:finalapp/utils/platform_utils.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200 && desktop != null) {
          return desktop!;
        } else if (constraints.maxWidth >= 600 && tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: builder);
  }
}

class AdaptiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? bottomNavigationBar;
  final FloatingActionButton? floatingActionButton;
  final List<Widget>? actions;

  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isTablet(context)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: actions,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: body,
        ),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
