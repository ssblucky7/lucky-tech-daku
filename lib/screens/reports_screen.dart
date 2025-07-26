import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:finalapp/services/api_service.dart';
import 'package:finalapp/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _medicalReports = [];
  List<Map<String, dynamic>> _prescriptions = [];
  List<Map<String, dynamic>> _certificates = [];
  bool _isLoading = true;
  
  final List<Map<String, dynamic>> _mockMedicalReports = [
    {
      'id': 'R001',
      'title': 'Annual Health Checkup',
      'patient': 'John Doe',
      'doctor': 'Dr. Smith',
      'date': DateTime.now().subtract(const Duration(days: 45)),
      'category': 'General',
      'status': 'Completed',
      'summary': 'Overall health is good. Blood pressure and cholesterol levels are normal.',
      'recommendations': 'Continue regular exercise and balanced diet.',
      'attachments': 2,
    },
    {
      'id': 'R002',
      'title': 'Blood Test Results',
      'patient': 'Jane Smith',
      'doctor': 'Dr. Johnson',
      'date': DateTime.now().subtract(const Duration(days: 30)),
      'category': 'Laboratory',
      'status': 'Completed',
      'summary': 'All blood parameters are within normal range.',
      'recommendations': 'No specific recommendations.',
      'attachments': 1,
    },
    {
      'id': 'R003',
      'title': 'X-Ray Report',
      'patient': 'Mike Doe',
      'doctor': 'Dr. Williams',
      'date': DateTime.now().subtract(const Duration(days: 15)),
      'category': 'Radiology',
      'status': 'Completed',
      'summary': 'No abnormalities detected in chest X-ray.',
      'recommendations': 'Follow up in 6 months.',
      'attachments': 3,
    },
  ];

  final List<Map<String, dynamic>> _mockPrescriptions = [
    {
      'id': 'P001',
      'patient': 'John Doe',
      'doctor': 'Dr. Smith',
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'medications': [
        {
          'name': 'Amoxicillin',
          'dosage': '500mg',
          'frequency': 'Twice daily',
          'duration': '7 days',
          'instructions': 'Take with food',
        },
        {
          'name': 'Ibuprofen',
          'dosage': '400mg',
          'frequency': 'As needed',
          'duration': '5 days',
          'instructions': 'Take for pain',
        },
      ],
      'diagnosis': 'Bacterial infection',
      'notes': 'Complete the full course of antibiotics.',
    },
    {
      'id': 'P002',
      'patient': 'Jane Smith',
      'doctor': 'Dr. Johnson',
      'date': DateTime.now().subtract(const Duration(days: 20)),
      'medications': [
        {
          'name': 'Loratadine',
          'dosage': '10mg',
          'frequency': 'Once daily',
          'duration': '30 days',
          'instructions': 'Take in the morning',
        },
      ],
      'diagnosis': 'Seasonal allergies',
      'notes': 'Avoid known allergens.',
    },
  ];

  final List<Map<String, dynamic>> _mockCertificates = [
    {
      'id': 'C001',
      'title': 'Medical Certificate',
      'patient': 'John Doe',
      'doctor': 'Dr. Smith',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'purpose': 'Sick Leave',
      'duration': '3 days',
      'diagnosis': 'Acute viral infection',
      'recommendations': 'Rest and hydration',
      'status': 'Valid',
    },
    {
      'id': 'C002',
      'title': 'Fitness Certificate',
      'patient': 'Mike Doe',
      'doctor': 'Dr. Williams',
      'date': DateTime.now().subtract(const Duration(days: 25)),
      'purpose': 'Sports Participation',
      'duration': '1 year',
      'diagnosis': 'N/A',
      'recommendations': 'Fit for all physical activities',
      'status': 'Valid',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportsData();
  }

  Future<void> _loadReportsData() async {
    try {
      // Test Firebase connection first
      final isConnected = await ApiService.testConnection();
      if (!isConnected) {
        if (kDebugMode) debugPrint('Firebase not connected, using mock data');
        setState(() {
          _medicalReports = _mockMedicalReports;
          _prescriptions = _mockPrescriptions;
          _certificates = _mockCertificates;
          _isLoading = false;
        });
        return;
      }
      
      // Check if user is authenticated
      if (FirebaseService.currentUser == null) {
        if (kDebugMode) debugPrint('User not authenticated, using mock data');
        setState(() {
          _medicalReports = _mockMedicalReports;
          _prescriptions = _mockPrescriptions;
          _certificates = _mockCertificates;
          _isLoading = false;
        });
        return;
      }
      
      List<Map<String, dynamic>> reports = [];
      List<Map<String, dynamic>> prescriptions = [];
      List<Map<String, dynamic>> certificates = [];
      
      try {
        if (kDebugMode) debugPrint('Loading data from Firebase...');
        // Load from Firebase
        final results = await Future.wait([
          ApiService.getReports(),
          ApiService.getPrescriptions(),
          ApiService.getCertificates(),
        ]);
        
        reports = results[0];
        prescriptions = results[1];
        certificates = results[2];
        
        if (kDebugMode) debugPrint('Loaded ${reports.length} reports, ${prescriptions.length} prescriptions, ${certificates.length} certificates');
      } catch (firebaseError) {
        if (kDebugMode) debugPrint('Firebase error: $firebaseError');
        // Fallback to local storage
        reports = await _loadLocalReports();
        prescriptions = await _loadLocalPrescriptions();
        certificates = await _loadLocalCertificates();
        if (kDebugMode) debugPrint('Using local data instead');
      }
      
      // Use mock data if all sources are empty
      if (reports.isEmpty) reports = _mockMedicalReports;
      if (prescriptions.isEmpty) prescriptions = _mockPrescriptions;
      if (certificates.isEmpty) certificates = _mockCertificates;
      
      setState(() {
        _medicalReports = reports;
        _prescriptions = prescriptions;
        _certificates = certificates;
        _isLoading = false;
      });
    } catch (e) {
      // Final fallback to mock data
      setState(() {
        _medicalReports = _mockMedicalReports;
        _prescriptions = _mockPrescriptions;
        _certificates = _mockCertificates;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveReportLocally(Map<String, dynamic> reportData) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = prefs.getStringList('local_reports') ?? [];
    
    reports.add(jsonEncode(reportData));
    await prefs.setStringList('local_reports', reports);
  }

  Future<List<Map<String, dynamic>>> _loadLocalReports() async {
    final prefs = await SharedPreferences.getInstance();
    final reportStrings = prefs.getStringList('local_reports') ?? [];
    
    return reportStrings.map((reportString) {
      final data = Map<String, dynamic>.from(jsonDecode(reportString));
      // Convert date string back to DateTime
      if (data['date'] is String) {
        data['date'] = DateTime.parse(data['date']);
      }
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _loadLocalPrescriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final prescriptionStrings = prefs.getStringList('local_prescriptions') ?? [];
    
    return prescriptionStrings.map((prescriptionString) {
      final data = Map<String, dynamic>.from(jsonDecode(prescriptionString));
      if (data['date'] is String) {
        data['date'] = DateTime.parse(data['date']);
      }
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _loadLocalCertificates() async {
    final prefs = await SharedPreferences.getInstance();
    final certificateStrings = prefs.getStringList('local_certificates') ?? [];
    
    return certificateStrings.map((certificateString) {
      final data = Map<String, dynamic>.from(jsonDecode(certificateString));
      if (data['date'] is String) {
        data['date'] = DateTime.parse(data['date']);
      }
      return data;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Medical Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Reports'),
            Tab(text: 'Prescriptions'),
            Tab(text: 'Certificates'),
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
                RefreshIndicator(
                  onRefresh: _loadReportsData,
                  child: _buildReportsList(_medicalReports),
                ),
                RefreshIndicator(
                  onRefresh: _loadReportsData,
                  child: _buildPrescriptionsList(_prescriptions),
                ),
                RefreshIndicator(
                  onRefresh: _loadReportsData,
                  child: _buildCertificatesList(_certificates),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showUploadReportDialog(context);
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReportsList(List<Map<String, dynamic>> reports) {
    if (reports.isEmpty) {
      return _buildEmptyState('No medical reports available', Icons.description);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        final formattedDate = DateFormat('MMM dd, yyyy').format(report['date'] as DateTime);

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
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        report['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        report['category'],
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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
                          report['patient'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.medical_services,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(report['doctor']),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(formattedDate),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Summary:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(report['summary']),
                    const SizedBox(height: 12),
                    Text(
                      'Recommendations:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(report['recommendations']),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: report['attachments'] > 0 && report['file_url'] != null
                          ? () => _showDocumentViewer(context, report)
                          : null,
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: Text('${report['attachments']} Attachments'),
                      style: TextButton.styleFrom(
                        foregroundColor: report['attachments'] > 0 && report['file_url'] != null
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {},
                          color: Colors.blue,
                          tooltip: 'Share',
                        ),
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () {},
                          color: Colors.blue,
                          tooltip: 'Download',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrescriptionsList(List<Map<String, dynamic>> prescriptions) {
    if (prescriptions.isEmpty) {
      return _buildEmptyState('No prescriptions available', Icons.medication);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prescriptions.length,
      itemBuilder: (context, index) {
        final prescription = prescriptions[index];
        final formattedDate = DateFormat('MMM dd, yyyy').format(prescription['date'] as DateTime);

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
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prescription #${prescription['id']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
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
                          prescription['patient'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.medical_services,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(prescription['doctor']),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.sick,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text('Diagnosis: ${prescription['diagnosis']}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Medications:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._buildMedicationsList(prescription['medications']),
                    if (prescription['notes'].isNotEmpty) ...[  
                      const SizedBox(height: 16),
                      const Text(
                        'Notes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(prescription['notes']),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {},
                      color: Colors.blue,
                      tooltip: 'Share',
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {},
                      color: Colors.blue,
                      tooltip: 'Download',
                    ),
                    IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: () {},
                      color: Colors.blue,
                      tooltip: 'Print',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildMedicationsList(List<dynamic> medications) {
    return medications.map<Widget>((medication) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              medication['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMedicationDetail('Dosage', medication['dosage']),
                _buildMedicationDetail('Frequency', medication['frequency']),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMedicationDetail('Duration', medication['duration']),
                Expanded(
                  child: Text(
                    medication['instructions'],
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildMedicationDetail(String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificatesList(List<Map<String, dynamic>> certificates) {
    if (certificates.isEmpty) {
      return _buildEmptyState('No certificates available', Icons.verified);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: certificates.length,
      itemBuilder: (context, index) {
        final certificate = certificates[index];
        final formattedDate = DateFormat('MMM dd, yyyy').format(certificate['date'] as DateTime);

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
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      certificate['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        certificate['status'],
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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
                          certificate['patient'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.medical_services,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(certificate['doctor']),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text('Issued on: $formattedDate'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text('Duration: ${certificate['duration']}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Purpose:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(certificate['purpose']),
                    const SizedBox(height: 12),
                    if (certificate['diagnosis'] != 'N/A') ...[  
                      Text(
                        'Diagnosis:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(certificate['diagnosis']),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'Recommendations:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(certificate['recommendations']),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {},
                      color: Colors.blue,
                      tooltip: 'Share',
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {},
                      color: Colors.blue,
                      tooltip: 'Download',
                    ),
                    IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: () {},
                      color: Colors.blue,
                      tooltip: 'Print',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showUploadReportDialog(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Upload Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('Date Range'),
            _buildFilterOption('Category'),
            _buildFilterOption('Patient'),
            _buildFilterOption('Doctor'),
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

  void _showUploadReportDialog(BuildContext context) {
    final titleController = TextEditingController();
    final summaryController = TextEditingController();
    final recommendationsController = TextEditingController();
    String? selectedPatient;
    String? selectedDocumentType = 'report';
    String? selectedCategory = 'General';
    PlatformFile? selectedFile;
    
    final List<String> patients = ['John Doe', 'Jane Smith', 'Mike Doe', 'Sarah Doe'];
    final List<String> categories = ['General', 'Laboratory', 'Radiology', 'Cardiology', 'Neurology'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        title: const Text('Upload Medical Document'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Document Type',
                  border: OutlineInputBorder(),
                ),
                value: selectedDocumentType,
                onChanged: (value) {
                  selectedDocumentType = value;
                },
                items: const [
                  DropdownMenuItem(value: 'report', child: Text('Medical Report')),
                  DropdownMenuItem(value: 'prescription', child: Text('Prescription')),
                  DropdownMenuItem(value: 'certificate', child: Text('Certificate')),
                  DropdownMenuItem(value: 'lab', child: Text('Lab Result')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title/Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Patient',
                  border: OutlineInputBorder(),
                ),
                value: selectedPatient,
                onChanged: (value) {
                  selectedPatient = value;
                },
                items: patients.map((patient) {
                  return DropdownMenuItem<String>(
                    value: patient,
                    child: Text(patient),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                value: selectedCategory,
                onChanged: (value) {
                  selectedCategory = value;
                },
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: summaryController,
                decoration: const InputDecoration(
                  labelText: 'Summary',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: recommendationsController,
                decoration: const InputDecoration(
                  labelText: 'Recommendations',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      selectedFile != null ? Icons.check_circle : Icons.upload_file,
                      size: 48,
                      color: selectedFile != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedFile != null 
                          ? 'File Selected: ${selectedFile!.name}'
                          : 'No file selected',
                      style: TextStyle(
                        color: selectedFile != null ? Colors.green : Colors.grey[600],
                        fontWeight: selectedFile != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                            allowMultiple: false,
                          );
                          
                          if (result != null && result.files.isNotEmpty) {
                            setDialogState(() {
                              selectedFile = result.files.first;
                            });
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error selecting file: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Select File (PDF/Image)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && 
                  selectedPatient != null && 
                  summaryController.text.isNotEmpty) {
                
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                try {
                  String? fileUrl;
                  String? fileId;
                  String? publicId;
                  
                  // Upload file if selected
                  if (selectedFile != null) {
                    final uploadResult = await ApiService.uploadFile(selectedFile!);
                    
                    if (uploadResult['success'] == true) {
                      fileUrl = uploadResult['url'];
                      fileId = uploadResult['file_id'];
                      publicId = uploadResult['public_id'];
                    } else {
                      // Show error but continue
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('File upload failed: ${uploadResult['error']}'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  }
                  
                  // Prepare document data
                  final documentData = {
                    'title': titleController.text,
                    'patient': selectedPatient!,
                    'doctor': 'Current Doctor',
                    'date': DateTime.now(),
                    'category': selectedCategory ?? 'General',
                    'status': 'Completed',
                    'summary': summaryController.text,
                    'recommendations': recommendationsController.text.isEmpty 
                        ? 'No specific recommendations' 
                        : recommendationsController.text,
                    'attachments': selectedFile != null ? 1 : 0,
                    'type': selectedDocumentType ?? 'report',
                    'file_url': fileUrl,
                    'file_name': selectedFile?.name,
                    'file_id': fileId,
                    'public_id': publicId,
                  };
                  
                  // Save to Firebase
                  try {
                    final result = await ApiService.createReport(documentData);
                    
                    if (result['success'] == true) {
                      // Success - refresh data
                      await _loadReportsData();
                    } else {
                      throw Exception('Failed to save report');
                    }
                  } catch (firebaseError) {
                    // Fallback to local storage
                    await _saveReportLocally(documentData);
                    await _loadReportsData();
                  }
                  
                  // Refresh data
                  await _loadReportsData();
                  
                  if (context.mounted) {
                    // Close loading dialog
                    Navigator.pop(context);
                    // Close upload dialog
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Document uploaded successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    // Close loading dialog
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to upload document: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Upload'),
          ),
        ],
        ),
      ),
    );
  }

  void _showDocumentViewer(BuildContext context, Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report['file_name'] ?? 'Document',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _buildDocumentPreview(report),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentPreview(Map<String, dynamic> report) {
    final fileUrl = report['file_url'] as String?;
    final fileName = report['file_name'] as String?;
    
    if (fileUrl == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Document not available'),
          ],
        ),
      );
    }
    
    final isImage = fileName != null && 
        (fileName.toLowerCase().endsWith('.jpg') ||
         fileName.toLowerCase().endsWith('.jpeg') ||
         fileName.toLowerCase().endsWith('.png'));
    
    if (isImage) {
      return Center(
        child: Image.network(
          fileUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Failed to load image'),
              ],
            );
          },
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              fileName ?? 'PDF Document',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'PDF Preview not available',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showDocumentUrl(context, fileUrl),
              icon: const Icon(Icons.open_in_new),
              label: const Text('View Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showDocumentUrl(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document URL'),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
