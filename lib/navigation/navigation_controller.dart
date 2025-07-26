import 'package:flutter/material.dart';
import 'package:finalapp/screens/home_screen.dart';
import 'package:finalapp/screens/hospitals_screen.dart';
import 'package:finalapp/screens/multi_options_screen.dart';
import 'package:finalapp/screens/calendar_screen.dart';
import 'package:finalapp/screens/analytics_dashboard_screen.dart';
import 'package:finalapp/screens/profile_screen.dart';
import 'package:finalapp/screens/patient_management_screen.dart';
import 'package:finalapp/services/firebase_service.dart';
import 'package:finalapp/widgets/custom_bottom_navbar.dart';
import 'package:finalapp/widgets/tracked_button.dart';
import 'package:finalapp/widgets/tracked_screen.dart';
import 'package:finalapp/services/activity_tracking_service.dart';

class NavigationController extends StatefulWidget {
  final int initialIndex;

  const NavigationController({super.key, this.initialIndex = 0});

  @override
  State<NavigationController> createState() => _NavigationControllerState();
}

class _NavigationControllerState extends State<NavigationController> {
  late int _currentIndex;
  
  final List<Widget> _screens = [
    const HomeContent(),
    const HospitalsScreen(),
    const MultiOptionsScreen(),
    const CalendarScreen(),
    const AnalyticsDashboardScreen(),
    const ProfileScreen(),
    const PatientManagementScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return TrackedScreen(
      screenName: 'navigation_controller',
      child: Scaffold(
      appBar: _currentIndex == 5 ? AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TrackedIconButton(
            buttonName: 'logout',
            screenName: 'profile_screen',
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ) : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Track navigation change
          _trackNavigation(index);
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    ),
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TrackedTextButton(
            buttonName: 'cancel_logout',
            screenName: 'logout_dialog',
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TrackedButton(
            buttonName: 'confirm_logout',
            screenName: 'logout_dialog',
            onPressed: () async {
              Navigator.pop(context);
              // Track logout action
              await ActivityTrackingService.trackUserAction(
                'user_logout',
                {'method': 'manual_logout'},
              );
              await FirebaseService.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
  
  void _trackNavigation(int index) async {
    final screenNames = [
      'home_screen',
      'hospitals_screen',
      'multi_options_screen',
      'calendar_screen',
      'analytics_dashboard',
      'profile_screen',
    ];
    
    if (index >= 0 && index < screenNames.length) {
      await ActivityTrackingService.trackScreenView(screenNames[index]);
      await ActivityTrackingService.trackNavigation(
        'bottom_nav',
        screenNames[index],
        {'from_screen': screenNames[_currentIndex]},
      );
    }
  }
}
