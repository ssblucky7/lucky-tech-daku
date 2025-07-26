import 'package:flutter/material.dart';

class MedicationTrackerScreen extends StatefulWidget {
  const MedicationTrackerScreen({super.key});

  @override
  State<MedicationTrackerScreen> createState() => _MedicationTrackerScreenState();
}

class _MedicationTrackerScreenState extends State<MedicationTrackerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Medication> _medications = [];
  List<Medication> _filteredMedications = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMockData();
    _filteredMedications = _medications;
    
    _searchController.addListener(() {
      _filterMedications(_searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadMockData() {
    _medications = [
      Medication(
        name: 'Amoxicillin',
        dosage: '500mg',
        frequency: 'Every 8 hours',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        instructions: 'Take with food',
        type: MedicationType.antibiotic,
        remainingPills: 15,
        totalPills: 21,
        nextDose: DateTime.now().add(const Duration(hours: 3)),
        isActive: true,
      ),
      Medication(
        name: 'Lisinopril',
        dosage: '10mg',
        frequency: 'Once daily',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 330)),
        instructions: 'Take in the morning',
        type: MedicationType.bloodPressure,
        remainingPills: 25,
        totalPills: 30,
        nextDose: DateTime.now().add(const Duration(hours: 20)),
        isActive: true,
      ),
    ];
  }

  void _filterMedications(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMedications = _medications;
      } else {
        _filteredMedications = _medications
            .where((medication) =>
                medication.name.toLowerCase().contains(query.toLowerCase()) ||
                medication.type.toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search medications...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                autofocus: true,
              )
            : const Text('Medication Tracker'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredMedications = _medications;
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'History'),
            Tab(text: 'Schedule'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrentMedicationsList(),
          _buildMedicationHistoryList(),
          _buildMedicationSchedule(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedicationDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCurrentMedicationsList() {
    final activeMedications = _filteredMedications.where((med) => med.isActive).toList();
    
    if (activeMedications.isEmpty) {
      return const Center(
        child: Text('No active medications found'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeMedications.length,
      itemBuilder: (context, index) {
        final medication = activeMedications[index];
        return MedicationCard(medication: medication);
      },
    );
  }

  Widget _buildMedicationHistoryList() {
    final inactiveMedications = _filteredMedications.where((med) => !med.isActive).toList();
    
    if (inactiveMedications.isEmpty) {
      return const Center(
        child: Text('No medication history found'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inactiveMedications.length,
      itemBuilder: (context, index) {
        final medication = inactiveMedications[index];
        return MedicationCard(medication: medication);
      },
    );
  }

  Widget _buildMedicationSchedule() {
    return const Center(
      child: Text('Schedule view'),
    );
  }

  void _showAddMedicationDialog() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final instructionsController = TextEditingController();
    String selectedFrequency = 'Once daily';
    MedicationType selectedType = MedicationType.antibiotic;
    int totalPills = 30;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Medication'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medication Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage (e.g., 500mg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Once daily', 'Twice daily', 'Every 8 hours', 'Every 6 hours', 'As needed']
                      .map((freq) => DropdownMenuItem(value: freq, child: Text(freq)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedFrequency = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MedicationType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: MedicationType.values
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(_getTypeLabel(type)),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Instructions',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Total Pills: '),
                    Expanded(
                      child: Slider(
                        value: totalPills.toDouble(),
                        min: 1,
                        max: 100,
                        divisions: 99,
                        label: totalPills.toString(),
                        onChanged: (value) => setState(() => totalPills = value.round()),
                      ),
                    ),
                    Text(totalPills.toString()),
                  ],
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
              onPressed: () {
                if (nameController.text.isNotEmpty && dosageController.text.isNotEmpty) {
                  _addMedication(
                    nameController.text,
                    dosageController.text,
                    selectedFrequency,
                    selectedType,
                    instructionsController.text,
                    totalPills,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(MedicationType type) {
    switch (type) {
      case MedicationType.antibiotic:
        return 'Antibiotic';
      case MedicationType.bloodPressure:
        return 'Blood Pressure';
      case MedicationType.cholesterol:
        return 'Cholesterol';
      case MedicationType.painRelief:
        return 'Pain Relief';
      case MedicationType.diabetes:
        return 'Diabetes';
      case MedicationType.allergy:
        return 'Allergy';
    }
  }

  void _addMedication(
    String name,
    String dosage,
    String frequency,
    MedicationType type,
    String instructions,
    int totalPills,
  ) {
    final newMedication = Medication(
      name: name,
      dosage: dosage,
      frequency: frequency,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      instructions: instructions,
      type: type,
      remainingPills: totalPills,
      totalPills: totalPills,
      nextDose: DateTime.now().add(const Duration(hours: 8)),
      isActive: true,
    );

    setState(() {
      _medications.add(newMedication);
      _filteredMedications = _medications;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medication added successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class MedicationCard extends StatelessWidget {
  final Medication medication;

  const MedicationCard({super.key, required this.medication});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    medication.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildTypeChip(medication.type),
              ],
            ),
            const SizedBox(height: 8),
            Text('${medication.dosage} - ${medication.frequency}'),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: medication.remainingPills / medication.totalPills,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                medication.remainingPills / medication.totalPills > 0.2
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${medication.remainingPills} of ${medication.totalPills} pills remaining',
              style: TextStyle(
                fontSize: 12,
                color: medication.remainingPills / medication.totalPills > 0.2
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(MedicationType type) {
    Color chipColor;
    String label;
    
    switch (type) {
      case MedicationType.antibiotic:
        chipColor = Colors.blue;
        label = 'Antibiotic';
      case MedicationType.bloodPressure:
        chipColor = Colors.red;
        label = 'Blood Pressure';
      case MedicationType.cholesterol:
        chipColor = Colors.purple;
        label = 'Cholesterol';
      case MedicationType.painRelief:
        chipColor = Colors.orange;
        label = 'Pain Relief';
      case MedicationType.diabetes:
        chipColor = Colors.green;
        label = 'Diabetes';
      case MedicationType.allergy:
        chipColor = Colors.teal;
        label = 'Allergy';
    }
    
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.all(0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

enum MedicationType {
  antibiotic,
  bloodPressure,
  cholesterol,
  painRelief,
  diabetes,
  allergy,
}

class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime endDate;
  final String instructions;
  final MedicationType type;
  final int remainingPills;
  final int totalPills;
  final DateTime? nextDose;
  final bool isActive;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.instructions,
    required this.type,
    required this.remainingPills,
    required this.totalPills,
    required this.nextDose,
    required this.isActive,
  });
}
