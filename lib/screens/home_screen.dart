import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:finalapp/screens/appointments_management_screen.dart';
import 'package:finalapp/screens/alarm_screen.dart';
import 'package:finalapp/screens/family_records_screen.dart';
import 'package:finalapp/screens/reports_screen.dart';
import 'package:finalapp/screens/health_info_screen.dart';
import 'package:finalapp/screens/medication_tracker_screen.dart';
import 'package:finalapp/screens/doctor_consultation_screen.dart';
import 'package:finalapp/navigation/navigation_controller.dart';
import 'package:finalapp/widgets/tracked_button.dart';
import 'package:finalapp/widgets/tracked_screen.dart';
import 'package:finalapp/services/activity_tracking_service.dart';
import 'package:finalapp/services/profile_service.dart';
import 'package:finalapp/services/notification_service.dart';
import 'package:finalapp/screens/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return const HomeContent();
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _userName = 'User';
  bool _isLoading = true;

  List<Map<String, dynamic>> _recentMessages = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadNotifications();
  }

  Future<void> _loadUserName() async {
    try {
      final userData = await ProfileService.getUserProfile();
      setState(() {
        _userName = userData?['name'] ?? 'User';
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading user name: $e');
      setState(() {
        _userName = 'User';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final results = await Future.wait([
        NotificationService.getRecentMessages(limit: 5),
        NotificationService.getUnreadCount(),
      ]);
      
      setState(() {
        _recentMessages = results[0] as List<Map<String, dynamic>>;
        _unreadCount = results[1] as int;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Track screen view when the home screen is displayed
    return TrackedScreen(
      screenName: 'home_screen',
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              Stack(
                children: [
                  TrackedIconButton(
                    buttonName: 'notifications',
                    screenName: 'home_screen',
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(context),
                    const SizedBox(height: 20),
                    _buildNotificationSection(),
                    const SizedBox(height: 20),
                    _buildApplicationsSection(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoading ? 'Welcome Back...' : 'Welcome Back, $_userName!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your health is our priority.\nLet\'s get started.',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    TrackedButton(
                      buttonName: 'view_profile',
                      screenName: 'home_screen',
                      onPressed: () {
                        // Navigate to profile tab using Navigator replacement
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NavigationController(initialIndex: 6),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('View Profile'),
                    ),
                    const SizedBox(width: 10),
                    TrackedButton(
                      buttonName: 'health_info',
                      screenName: 'home_screen',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HealthInfoScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Health Info'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.layers,
            size: 40,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Messages',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount new',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _recentMessages.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'No recent messages',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : Column(
                children: _recentMessages.take(3).map((message) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: message['is_read'] == false
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['subject'] ?? 'No Subject',
                          style: TextStyle(
                            fontWeight: message['is_read'] == false
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message['content'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
        if (_recentMessages.isNotEmpty)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                'View all messages →',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }





  Widget _buildApplicationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Applications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildAppCard(
              title: 'Appointments',
              icon: Icons.calendar_today,
              color: Colors.pink[100]!,
              iconColor: Colors.pink,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppointmentsManagementScreen(),
                  ),
                );
              },
            ),
            _buildAppCard(
              title: 'Medicine Time',
              icon: Icons.access_time,
              color: Colors.blue[100]!,
              iconColor: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AlarmScreen(),
                  ),
                );
              },
            ),
            _buildAppCard(
              title: 'Family Records',
              icon: Icons.family_restroom,
              color: Colors.amber[100]!,
              iconColor: Colors.amber,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FamilyRecordsScreen(),
                  ),
                );
              },
            ),
            _buildAppCard(
              title: 'Reports',
              icon: Icons.description,
              color: Colors.green[100]!,
              iconColor: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsScreen(),
                  ),
                );
              },
            ),
            _buildAppCard(
              title: 'Medication Tracker',
              icon: Icons.medication,
              color: Colors.teal[100]!,
              iconColor: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MedicationTrackerScreen(),
                  ),
                );
              },
            ),
            _buildAppCard(
              title: 'Doctor Consultation',
              icon: Icons.medical_services,
              color: Colors.indigo[100]!,
              iconColor: Colors.indigo,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorConsultationScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        // Track app card click
        ActivityTrackingService.trackButtonClick(
          'app_card_${title.toLowerCase().replaceAll(' ', '_')}',
          screenName: 'home_screen',
        );
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 30,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
