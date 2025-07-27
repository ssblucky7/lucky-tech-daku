import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finalapp/services/medication_tracker_service.dart';
import 'package:finalapp/widgets/tracked_screen.dart';
import 'package:finalapp/widgets/tracked_button.dart';

class MedicationTrackerScreen extends StatefulWidget {
  const MedicationTrackerScreen({super.key});

  @override
  State<MedicationTrackerScreen> createState() => _MedicationTrackerScreenState();
}

class _MedicationTrackerScreenState extends State<MedicationTrackerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _filteredMedications = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMedications();
    
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

  Future<void> _loadMedications() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final medications = await MedicationTrackerService.getMedications();
      
      setState(() {
        _medications = medications;
        _filteredMedications = medications;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading medications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterMedications(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMedications = _medications;
      } else {
        _filteredMedications = _medications
            .where((medication) =>
                medication['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
                medication['type'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TrackedScreen(
      screenName: 'medication_tracker_screen',
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search medications...',
                    border: InputBorder.none,
                  ),
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  RefreshIndicator(
                    onRefresh: _loadMedications,
                    child: _buildCurrentMedicationsList(),
                  ),
                  RefreshIndicator(
                    onRefresh: _loadMedications,
                    child: _buildMedicationHistoryList(),
                  ),
                  RefreshIndicator(
                    onRefresh: _loadMedications,
                    child: _buildMedicationSchedule(),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddMedicationDialog,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildCurrentMedicationsList() {
    final activeMedications = _filteredMedications.where((med) => med['is_active'] == true).toList();
    
    if (activeMedications.isEmpty) {
      return _buildEmptyState('No active medications found', Icons.medication);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeMedications.length,
      itemBuilder: (context, index) {
        final medication = activeMedications[index];
        return _buildMedicationCard(medication);
      },
    );
  }

  Widget _buildMedicationHistoryList() {
    final inactiveMedications = _filteredMedications.where((med) => med['is_active'] == false).toList();
    
    if (inactiveMedications.isEmpty) {
      return _buildEmptyState('No medication history found', Icons.history);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inactiveMedications.length,
      itemBuilder: (context, index) {
        final medication = inactiveMedications[index];
        return _buildMedicationCard(medication);
      },
    );
  }

  Widget _buildMedicationSchedule() {
    final activeMedications = _filteredMedications.where((med) => med['is_active'] == true).toList();
    
    if (activeMedications.isEmpty) {
      return _buildEmptyState('No scheduled medications', Icons.schedule);
    }

    // Sort by next dose time
    activeMedications.sort((a, b) {
      final aTime = (a['next_dose'] as Timestamp).toDate();
      final bTime = (b['next_dose'] as Timestamp).toDate();
      return aTime.compareTo(bTime);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeMedications.length,
      itemBuilder: (context, index) {
        final medication = activeMedications[index];
        return _buildScheduleCard(medication);
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TrackedButton(
            buttonName: 'add_first_medication',
            screenName: 'medication_tracker_screen',
            onPressed: _showAddMedicationDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add),
                SizedBox(width: 8),
                Text('Add Medication'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    final remainingPills = medication['remaining_pills'] as int;
    final totalPills = medication['total_pills'] as int;
    final progress = remainingPills / totalPills;

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
                    medication['name'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildTypeChip(medication['type']),
              ],
            ),
            const SizedBox(height: 8),
            Text('${medication['dosage']} - ${medication['frequency']}'),
            const SizedBox(height: 8),
            if (medication['instructions'].isNotEmpty)
              Text(
                'Instructions: ${medication['instructions']}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.2 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$remainingPills of $totalPills pills remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: progress > 0.2 ? Colors.green : Colors.red,
                  ),
                ),
                if (medication['prescription_image_url'] != null)
                  TextButton.icon(
                    onPressed: () => _showPrescriptionImage(medication),
                    icon: const Icon(Icons.image, size: 16),
                    label: const Text('View Prescription'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (medication['is_active'] == true) ...[
                  Expanded(
                    child: TrackedButton(
                      buttonName: 'take_dose',
                      screenName: 'medication_tracker_screen',
                      onPressed: () => _takeDose(medication['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Take Dose'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TrackedButton(
                      buttonName: 'miss_dose',
                      screenName: 'medication_tracker_screen',
                      onPressed: () => _missDose(medication['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Miss Dose'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteMedication(medication['id']),
                  color: Colors.red,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> medication) {
    final nextDose = (medication['next_dose'] as Timestamp).toDate();
    final isOverdue = nextDose.isBefore(DateTime.now());

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isOverdue ? Colors.red.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.medication,
                color: isOverdue ? Colors.red : Colors.blue,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication['name'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text('${medication['dosage']} - ${medication['frequency']}'),
                  const SizedBox(height: 4),
                  Text(
                    'Next dose: ${DateFormat('MMM dd, HH:mm').format(nextDose)}',
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (isOverdue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'OVERDUE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    Color chipColor;
    
    switch (type.toLowerCase()) {
      case 'antibiotic':
        chipColor = Colors.blue;
        break;
      case 'blood pressure':
        chipColor = Colors.red;
        break;
      case 'cholesterol':
        chipColor = Colors.purple;
        break;
      case 'pain relief':
        chipColor = Colors.orange;
        break;
      case 'diabetes':
        chipColor = Colors.green;
        break;
      case 'allergy':
        chipColor = Colors.teal;
        break;
      default:
        chipColor = Colors.grey;
    }
    
    return Chip(
      label: Text(
        type,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.all(0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showAddMedicationDialog() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final instructionsController = TextEditingController();
    String selectedFrequency = 'Once daily';
    String selectedType = 'Antibiotic';
    int totalPills = 30;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));
    PlatformFile? prescriptionImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                  onChanged: (value) => setDialogState(() => selectedFrequency = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Antibiotic', 'Blood Pressure', 'Cholesterol', 'Pain Relief', 'Diabetes', 'Allergy']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => selectedType = value!),
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
                        onChanged: (value) => setDialogState(() => totalPills = value.round()),
                      ),
                    ),
                    Text(totalPills.toString()),
                  ],
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
                        prescriptionImage != null ? Icons.check_circle : Icons.camera_alt,
                        size: 48,
                        color: prescriptionImage != null ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        prescriptionImage != null 
                            ? 'Prescription Image: ${prescriptionImage!.name}'
                            : 'No prescription image',
                        style: TextStyle(
                          color: prescriptionImage != null ? Colors.green : Colors.grey[600],
                          fontWeight: prescriptionImage != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              allowMultiple: false,
                            );
                            
                            if (result != null && result.files.isNotEmpty) {
                              setDialogState(() {
                                prescriptionImage = result.files.first;
                              });
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error selecting image: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Add Prescription Image'),
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
            TrackedButton(
              buttonName: 'add_medication',
              screenName: 'add_medication_dialog',
              onPressed: () async {
                if (nameController.text.isNotEmpty && dosageController.text.isNotEmpty) {
                  if (!mounted) return;
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                  
                  try {
                    await MedicationTrackerService.createMedication(
                      name: nameController.text,
                      dosage: dosageController.text,
                      frequency: selectedFrequency,
                      instructions: instructionsController.text,
                      type: selectedType,
                      totalPills: totalPills,
                      startDate: startDate,
                      endDate: endDate,
                      prescriptionImage: prescriptionImage,
                    );
                    
                    await _loadMedications();
                    
                    if (mounted) {
                      navigator.pop(); // Close loading
                      navigator.pop(); // Close dialog
                      
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Medication added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      navigator.pop(); // Close loading
                      
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to add medication: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrescriptionImage(Map<String, dynamic> medication) {
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
                      'Prescription - ${medication['name']}',
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
                child: Center(
                  child: Image.network(
                    medication['prescription_image_url'],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const CircularProgressIndicator();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Failed to load prescription image'),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takeDose(String medicationId) async {
    try {
      await MedicationTrackerService.takeDose(medicationId);
      await _loadMedications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dose recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording dose: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _missDose(String medicationId) async {
    try {
      await MedicationTrackerService.missDose(medicationId);
      await _loadMedications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missed dose recorded'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording missed dose: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMedication(String medicationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: const Text('Are you sure you want to delete this medication?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TrackedButton(
            buttonName: 'confirm_delete',
            screenName: 'delete_dialog',
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      
      try {
        await MedicationTrackerService.deleteMedication(medicationId);
        await _loadMedications();
        
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Medication deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error deleting medication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}