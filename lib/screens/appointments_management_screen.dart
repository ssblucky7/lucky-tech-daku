import 'package:flutter/material.dart';
import 'package:finalapp/screens/appointment_screen.dart';
import 'package:finalapp/services/appointment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class AppointmentsManagementScreen extends StatefulWidget {
  const AppointmentsManagementScreen({super.key});

  @override
  State<AppointmentsManagementScreen> createState() =>
      _AppointmentsManagementScreenState();
}

class _AppointmentsManagementScreenState
    extends State<AppointmentsManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _upcomingAppointments = [];
  List<Map<String, dynamic>> _pastAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      List<Map<String, dynamic>> appointments = [];
      
      try {
        // Load from Firebase
        appointments = await AppointmentService.getAppointments();
      } catch (apiError) {
        // Fallback to local storage
        appointments = await _loadLocalAppointments();
      }
      
      final now = DateTime.now();
      
      setState(() {
        _upcomingAppointments = appointments.where((appointment) {
          final appointmentDate = DateTime.parse(appointment['date']);
          return appointmentDate.isAfter(now.subtract(const Duration(days: 1)));
        }).map((appointment) {
          return {
            'id': appointment['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            'patient': appointment['patient'] ?? 'Current User',
            'doctor': appointment['doctor'] ?? 'Unknown Doctor',
            'specialty': appointment['specialty'] ?? 'General',
            'date': DateTime.parse(appointment['date']),
            'time': appointment['time'] ?? '09:00',
            'status': appointment['status'] ?? 'pending',
            'symptoms': appointment['symptoms'] ?? '',
            'notes': appointment['notes'] ?? '',
          };
        }).toList();
        
        _pastAppointments = appointments.where((appointment) {
          final appointmentDate = DateTime.parse(appointment['date']);
          return appointmentDate.isBefore(now.subtract(const Duration(days: 1)));
        }).map((appointment) {
          return {
            'id': appointment['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            'patient': appointment['patient'] ?? 'Current User',
            'doctor': appointment['doctor'] ?? 'Unknown Doctor',
            'specialty': appointment['specialty'] ?? 'General',
            'date': DateTime.parse(appointment['date']),
            'time': appointment['time'] ?? '09:00',
            'status': appointment['status'] ?? 'completed',
            'symptoms': appointment['symptoms'] ?? '',
            'notes': appointment['notes'] ?? '',
            'diagnosis': appointment['diagnosis'] ?? '',
            'prescription': appointment['prescription'] ?? '',
          };
        }).toList();
        
        // Sort appointments by date
        _upcomingAppointments.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
        _pastAppointments.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadLocalAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final appointmentStrings = prefs.getStringList('local_appointments') ?? [];
    
    return appointmentStrings.map((appointmentString) {
      return Map<String, dynamic>.from(jsonDecode(appointmentString));
    }).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList(_upcomingAppointments, isUpcoming: true),
                _buildAppointmentsList(_pastAppointments, isUpcoming: false),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AppointmentScreen(),
            ),
          ).then((value) {
            // Refresh appointments if needed
            if (value != null && value == true) {
              _loadAppointments();
            }
          });
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppointmentsList(
      List<Map<String, dynamic>> appointments, {required bool isUpcoming}) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_available : Icons.history,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming
                  ? 'No upcoming appointments'
                  : 'No past appointments',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (isUpcoming)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppointmentScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Schedule Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        final formattedDate = DateFormat('MMM dd, yyyy')
            .format(appointment['date'] as DateTime);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment['status']).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(appointment['status']),
                          color: _getStatusColor(appointment['status']),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          appointment['status'],
                          style: TextStyle(
                            color: _getStatusColor(appointment['status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'ID: ${appointment['id']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          appointment['patient'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.medical_services,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  appointment['doctor'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_hospital,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  appointment['specialty'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formattedDate,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                appointment['time'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (appointment['symptoms'].isNotEmpty) ...[  
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.sick,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Symptoms: ${appointment['symptoms']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!isUpcoming &&
                        appointment.containsKey('diagnosis') &&
                        appointment['diagnosis'].isNotEmpty) ...[  
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.description,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Diagnosis: ${appointment['diagnosis']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (appointment['notes'].isNotEmpty) ...[  
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.note,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Notes: ${appointment['notes']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isUpcoming) ...[  
                      TextButton.icon(
                        onPressed: () {
                          _showRescheduleDialog(context, appointment);
                        },
                        icon: const Icon(Icons.schedule, size: 18),
                        label: const Text('Reschedule'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _showCancelDialog(context, appointment);
                        },
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancel'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ] else ...[  
                      TextButton.icon(
                        onPressed: () {
                          _showAppointmentDetailsDialog(context, appointment);
                        },
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View Details'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.task_alt;
      default:
        return Icons.circle;
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Appointments'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('Doctor'),
            _buildFilterOption('Specialty'),
            _buildFilterOption('Status'),
            _buildFilterOption('Date Range'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Apply filters
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String title) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // Show specific filter options
      },
    );
  }

  void _showRescheduleDialog(BuildContext context, Map<String, dynamic> appointment) {
    DateTime selectedDate = appointment['date'] as DateTime;
    String selectedTime = appointment['time'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: ${DateFormat('MMM dd, yyyy').format(selectedDate)} at ${appointment['time']}'),
            const SizedBox(height: 16),
            ListTile(
              title: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null && picked != selectedDate) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
            ),
            ListTile(
              title: Text(selectedTime),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: int.parse(selectedTime.split(':')[0]),
                    minute: int.parse(selectedTime.split(':')[1].split(' ')[0]),
                  ),
                );
                if (picked != null) {
                  setState(() {
                    selectedTime = '${picked.hour}:${picked.minute.toString().padLeft(2, '0')} ${picked.hour >= 12 ? 'PM' : 'AM'}';
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Update appointment date and time
              setState(() {
                final index = _upcomingAppointments.indexWhere(
                    (a) => a['id'] == appointment['id']);
                if (index != -1) {
                  _upcomingAppointments[index]['date'] = selectedDate;
                  _upcomingAppointments[index]['time'] = selectedTime;
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appointment rescheduled successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
            'Are you sure you want to cancel this appointment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () {
              // Cancel appointment
              setState(() {
                final index = _upcomingAppointments.indexWhere(
                    (a) => a['id'] == appointment['id']);
                if (index != -1) {
                  _upcomingAppointments[index]['status'] = 'Cancelled';
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appointment cancelled successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetailsDialog(BuildContext context, Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Appointment Details - ${appointment['id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Patient', appointment['patient'], Icons.person),
              _buildDetailItem('Doctor', appointment['doctor'], Icons.medical_services),
              _buildDetailItem('Specialty', appointment['specialty'], Icons.local_hospital),
              _buildDetailItem(
                  'Date',
                  DateFormat('MMM dd, yyyy').format(appointment['date'] as DateTime),
                  Icons.calendar_today),
              _buildDetailItem('Time', appointment['time'], Icons.access_time),
              _buildDetailItem('Status', appointment['status'], _getStatusIcon(appointment['status'])),
              _buildDetailItem('Symptoms', appointment['symptoms'], Icons.sick),
              if (appointment.containsKey('diagnosis'))
                _buildDetailItem('Diagnosis', appointment['diagnosis'], Icons.description),
              if (appointment.containsKey('prescription'))
                _buildDetailItem('Prescription', appointment['prescription'], Icons.medication),
              _buildDetailItem('Notes', appointment['notes'].isEmpty ? 'None' : appointment['notes'], Icons.note),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
