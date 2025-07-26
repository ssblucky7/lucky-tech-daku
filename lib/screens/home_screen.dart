import 'package:flutter/material.dart';
import 'package:finalapp/screens/appointments_management_screen.dart';
import 'package:finalapp/screens/alarm_screen.dart';
import 'package:finalapp/screens/family_records_screen.dart';
import 'package:finalapp/screens/reports_screen.dart';
import 'package:finalapp/screens/profile_screen.dart';
import 'package:finalapp/screens/health_info_screen.dart';
import 'package:finalapp/screens/medication_tracker_screen.dart';
import 'package:finalapp/screens/doctor_consultation_screen.dart';
import 'package:finalapp/screens/patient_management_screen.dart';
import 'package:finalapp/widgets/tracked_button.dart';
import 'package:finalapp/widgets/tracked_screen.dart';
import 'package:finalapp/services/activity_tracking_service.dart';

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

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

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
              TrackedIconButton(
                buttonName: 'notifications',
                screenName: 'home_screen',
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
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
                const Text(
                  'Welcome Back, [User\'s Name]',
                  style: TextStyle(
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
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
        const Text(
          'Notification',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text('Recent Messages'),
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
            // Hospital option removed as requested
            _buildAppCard(
              title: 'Medical Certificates',
              icon: Icons.shield,
              color: Colors.orange[100]!,
              iconColor: Colors.orange,
              onTap: () {},
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
            _buildAppCard(
              title: 'Patient Management',
              icon: Icons.people,
              color: Colors.purple[100]!,
              iconColor: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatientManagementScreen(),
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
