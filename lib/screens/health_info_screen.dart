import 'package:flutter/material.dart';

class HealthInfoScreen extends StatefulWidget {
  const HealthInfoScreen({super.key});

  @override
  State<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends State<HealthInfoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Mock data for health metrics
  final Map<String, dynamic> _healthMetrics = {
    'height': '175 cm',
    'weight': '70 kg',
    'bmi': '22.9',
    'bloodPressure': '120/80 mmHg',
    'heartRate': '72 bpm',
    'bloodSugar': '90 mg/dL',
    'cholesterol': {
      'total': '180 mg/dL',
      'hdl': '50 mg/dL',
      'ldl': '110 mg/dL',
    },
    'allergies': ['Peanuts', 'Penicillin'],
    'medications': [
      {
        'name': 'Lisinopril',
        'dosage': '10mg',
        'frequency': 'Once daily',
        'purpose': 'Blood pressure',
      },
      {
        'name': 'Metformin',
        'dosage': '500mg',
        'frequency': 'Twice daily',
        'purpose': 'Blood sugar',
      },
    ],
  };

  // Mock data for health records
  final List<Map<String, dynamic>> _healthRecords = [
    {
      'date': '2023-05-15',
      'type': 'Blood Test',
      'doctor': 'Dr. Smith',
      'hospital': 'City Hospital',
      'results': [
        {'name': 'Hemoglobin', 'value': '14.5 g/dL', 'status': 'normal'},
        {'name': 'White Blood Cells', 'value': '7,500 /μL', 'status': 'normal'},
        {'name': 'Platelets', 'value': '250,000 /μL', 'status': 'normal'},
        {'name': 'Glucose', 'value': '95 mg/dL', 'status': 'normal'},
      ],
    },
    {
      'date': '2023-04-10',
      'type': 'X-Ray',
      'doctor': 'Dr. Johnson',
      'hospital': 'Memorial Hospital',
      'results': [
        {'name': 'Chest X-Ray', 'value': 'Clear', 'status': 'normal'},
      ],
    },
    {
      'date': '2023-03-22',
      'type': 'Physical Examination',
      'doctor': 'Dr. Williams',
      'hospital': 'Community Clinic',
      'results': [
        {'name': 'Blood Pressure', 'value': '118/78 mmHg', 'status': 'normal'},
        {'name': 'Heart Rate', 'value': '68 bpm', 'status': 'normal'},
        {'name': 'Respiratory Rate', 'value': '16 /min', 'status': 'normal'},
        {'name': 'Temperature', 'value': '98.6°F', 'status': 'normal'},
      ],
    },
  ];

  // Mock data for health goals
  final List<Map<String, dynamic>> _healthGoals = [
    {
      'title': 'Daily Steps',
      'target': '10,000 steps',
      'current': '7,500 steps',
      'progress': 0.75,
      'icon': Icons.directions_walk,
      'color': Colors.blue,
    },
    {
      'title': 'Weight Goal',
      'target': '65 kg',
      'current': '70 kg',
      'progress': 0.5,
      'icon': Icons.monitor_weight,
      'color': Colors.green,
    },
    {
      'title': 'Water Intake',
      'target': '8 glasses',
      'current': '5 glasses',
      'progress': 0.625,
      'icon': Icons.water_drop,
      'color': Colors.cyan,
    },
    {
      'title': 'Sleep',
      'target': '8 hours',
      'current': '6.5 hours',
      'progress': 0.8125,
      'icon': Icons.bedtime,
      'color': Colors.indigo,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
        title: const Text('Health Information'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Records'),
            Tab(text: 'Goals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildRecordsTab(),
          _buildGoalsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHealthSummaryCard(),
          const SizedBox(height: 20),
          _buildSectionTitle('Vital Statistics'),
          _buildVitalStatsGrid(),
          const SizedBox(height: 20),
          _buildSectionTitle('Allergies'),
          _buildAllergiesList(),
          const SizedBox(height: 20),
          _buildSectionTitle('Current Medications'),
          _buildMedicationsList(),
        ],
      ),
    );
  }

  Widget _buildHealthSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Score',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '85/100',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Your health is in good condition. Continue maintaining your healthy lifestyle.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHealthMetricItem('BMI', _healthMetrics['bmi'], Icons.monitor_weight),
              _buildHealthMetricItem('BP', _healthMetrics['bloodPressure'], Icons.favorite),
              _buildHealthMetricItem('Heart', _healthMetrics['heartRate'], Icons.favorite_border),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVitalStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildVitalStatCard('Height', _healthMetrics['height'], Icons.height, Colors.blue),
        _buildVitalStatCard('Weight', _healthMetrics['weight'], Icons.monitor_weight, Colors.green),
        _buildVitalStatCard('Blood Sugar', _healthMetrics['bloodSugar'], Icons.water_drop, Colors.orange),
        _buildVitalStatCard('Cholesterol', _healthMetrics['cholesterol']['total'], Icons.favorite, Colors.red),
      ],
    );
  }

  Widget _buildVitalStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 30,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergiesList() {
    final allergies = _healthMetrics['allergies'] as List<dynamic>;
    
    return allergies.isEmpty
        ? const Text('No known allergies')
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergies.map<Widget>((allergy) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      allergy,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
  }

  Widget _buildMedicationsList() {
    final medications = _healthMetrics['medications'] as List<dynamic>;
    
    return medications.isEmpty
        ? const Text('No current medications')
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final medication = medications[index] as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.medication,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
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
                          const SizedBox(height: 4),
                          Text(
                            '${medication['dosage']} - ${medication['frequency']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'For: ${medication['purpose']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
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

  Widget _buildRecordsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search records',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _healthRecords.length,
            itemBuilder: (context, index) {
              final record = _healthRecords[index];
              return _buildRecordCard(record);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getRecordTypeIcon(record['type']),
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['type'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${record['date']}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // Show options menu
                  },
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
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      record['doctor'],
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.local_hospital,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record['hospital'],
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Results:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ..._buildResultsList(record['results']),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Full Report'),
                      onPressed: () {
                        // View full report
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                      onPressed: () {
                        // Download report
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResultsList(List<dynamic> results) {
    return results.map<Widget>((result) {
      final Map<String, dynamic> resultMap = result as Map<String, dynamic>;
      final String status = resultMap['status'];
      
      Color statusColor;
      switch (status.toLowerCase()) {
        case 'normal':
          statusColor = Colors.green;
          break;
        case 'abnormal':
          statusColor = Colors.red;
          break;
        case 'borderline':
          statusColor = Colors.orange;
          break;
        default:
          statusColor = Colors.grey;
      }
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              resultMap['name'],
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
              ),
            ),
            Row(
              children: [
                Text(
                  resultMap['value'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  IconData _getRecordTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'blood test':
        return Icons.opacity;
      case 'x-ray':
        return Icons.image;
      case 'physical examination':
        return Icons.person;
      case 'vaccination':
        return Icons.vaccines;
      case 'surgery':
        return Icons.medical_services;
      default:
        return Icons.description;
    }
  }

  Widget _buildGoalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Your Health Goals'),
          ..._healthGoals.map((goal) => _buildGoalCard(goal)),
          const SizedBox(height: 20),
          _buildAddGoalButton(),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (goal['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  goal['icon'] as IconData,
                  color: goal['color'] as Color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target: ${goal['target']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Show options menu
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current: ${goal['current']}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              Text(
                '${(goal['progress'] * 100).toInt()}%',
                style: TextStyle(
                  color: goal['color'] as Color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: goal['progress'] as double,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(goal['color'] as Color),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildAddGoalButton() {
    return GestureDetector(
      onTap: () {
        // Show add goal dialog
        _showAddGoalDialog();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blue, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Colors.blue,
            ),
            SizedBox(width: 8),
            Text(
              'Add New Health Goal',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Add New Health Goal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Goal Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Target Value',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Current Value',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Add new goal logic
                      Navigator.pop(context);
                    },
                    child: const Text('Add Goal'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
