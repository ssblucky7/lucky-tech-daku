import 'package:flutter/material.dart';
import 'package:finalapp/utils/platform_helper.dart';

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? web;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.web,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformHelper.isWeb && web != null) {
      return web!;
    }
    
    if (PlatformHelper.isDesktopScreen(context) && desktop != null) {
      return desktop!;
    }
    
    if (PlatformHelper.isTablet(context) && tablet != null) {
      return tablet!;
    }
    
    return mobile;
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
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? bottomNavigationBar;

  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.drawer,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformHelper.isDesktop) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: actions,
          elevation: 1,
        ),
        body: Row(
          children: [
            if (drawer != null)
              SizedBox(
                width: 250,
                child: drawer!,
              ),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      drawer: drawer,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}