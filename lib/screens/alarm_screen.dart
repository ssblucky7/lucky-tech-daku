import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finalapp/services/medication_service.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<Map<String, dynamic>> medications = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(''),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: MedicationService.getMedicationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          medications = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medicine Time',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: medications.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.medication, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No medications added'),
                              Text('Tap + to add your first medication'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: medications.length,
                          itemBuilder: (context, index) {
                            return _buildMedicationCard(medications[index]);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new alarm
          _showAddAlarmDialog();
        },
        backgroundColor: Colors.white,
        child: const Icon(
          Icons.add,
          color: Colors.green,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication['medicationName'] ?? 'Unknown Medicine',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Time: ${medication['time']}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${medication['frequency']} | ${medication['dosage']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: medication['isActive'] ?? false,
                  onChanged: (value) async {
                    try {
                      await MedicationService.toggleMedicationStatus(
                        medication['id'],
                        value,
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  activeThumbColor: Colors.blue,
                ),
              ],
            ),
            if (medication['notes']?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Notes: ${medication['notes']}',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditMedicationDialog(medication),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                ),
                TextButton.icon(
                  onPressed: () => _deleteMedication(medication['id']),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  void _showAddAlarmDialog() {
    _showMedicationDialog();
  }

  void _showMedicationDialog([Map<String, dynamic>? existingMedication]) {
    final nameController = TextEditingController(
      text: existingMedication?['medicationName'] ?? '',
    );
    final dosageController = TextEditingController(
      text: existingMedication?['dosage'] ?? '',
    );
    final notesController = TextEditingController(
      text: existingMedication?['notes'] ?? '',
    );
    
    TimeOfDay selectedTime = existingMedication != null
        ? _parseTime(existingMedication['time'])
        : TimeOfDay.now();
    String frequency = existingMedication?['frequency'] ?? 'Daily';
    String type = existingMedication?['type'] ?? 'Tablet';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existingMedication != null ? 'Edit Medication' : 'Add Medication'),
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
                    ListTile(
                      title: const Text('Time'),
                      trailing: Text(
                        selectedTime.format(context),
                        style: const TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('Frequency'),
                      trailing: DropdownButton<String>(
                        value: frequency,
                        onChanged: (String? newValue) {
                          setState(() {
                            frequency = newValue!;
                          });
                        },
                        items: ['Daily', 'Twice Daily', 'Weekly', 'As Needed']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    ListTile(
                      title: const Text('Type'),
                      trailing: DropdownButton<String>(
                        value: type,
                        onChanged: (String? newValue) {
                          setState(() {
                            type = newValue!;
                          });
                        },
                        items: ['Tablet', 'Capsule', 'Liquid', 'Injection']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
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
                    if (nameController.text.isEmpty || dosageController.text.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in required fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }

                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final timeString = selectedTime.format(context);
                    
                    try {
                      if (existingMedication != null) {
                        await MedicationService.updateMedication(
                          documentId: existingMedication['id'],
                          medicationName: nameController.text,
                          dosage: dosageController.text,
                          frequency: frequency,
                          time: timeString,
                          type: type,
                          notes: notesController.text,
                        );
                      } else {
                        await MedicationService.createMedication(
                          medicationName: nameController.text,
                          dosage: dosageController.text,
                          frequency: frequency,
                          time: timeString,
                          type: type,
                          notes: notesController.text,
                        );
                      }

                      navigator.pop();
                      if (context.mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              existingMedication != null
                                  ? 'Medication updated successfully'
                                  : 'Medication added successfully',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(existingMedication != null ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditMedicationDialog(Map<String, dynamic> medication) {
    _showMedicationDialog(medication);
  }

  Future<void> _deleteMedication(String medicationId) async {
    final messenger = ScaffoldMessenger.of(context);
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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await MedicationService.deleteMedication(medicationId);
        if (context.mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Medication deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      if (parts.length > 1 && parts[1].toLowerCase() == 'pm' && hour != 12) {
        hour += 12;
      } else if (parts.length > 1 && parts[1].toLowerCase() == 'am' && hour == 12) {
        hour = 0;
      }
      
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return TimeOfDay.now();
    }
  }
}


