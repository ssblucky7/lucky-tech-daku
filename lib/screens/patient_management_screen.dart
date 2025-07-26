import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_client.dart';
import '../widgets/tracked_screen.dart';
import '../widgets/api_status_widget.dart';

class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({super.key});

  @override
  State<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return TrackedScreen(
      screenName: 'patient_management',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Patient Management'),
          actions: [
            IconButton(
              icon: const Icon(Icons.health_and_safety),
              onPressed: () => _showApiStatus(context),
              tooltip: 'System Status',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showPatientForm(context),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: ApiClient.getPatientsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No patients found'),
                    Text('Tap + to add a patient'),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        data['name']?.toString().substring(0, 1).toUpperCase() ?? 'P',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(data['name'] ?? 'Unknown Patient'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${data['patientId'] ?? 'N/A'}'),
                        Text('Age: ${data['age'] ?? 'N/A'}'),
                        Text('Condition: ${data['condition'] ?? 'N/A'}'),
                        if (data['fileUrl'] != null)
                          const Text('📎 File attached', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showPatientForm(context, doc.id, data);
                        } else if (value == 'delete') {
                          _deletePatient(doc.id, data);
                        }
                      },
                    ),
                    onTap: () => _showPatientDetails(context, data),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showPatientForm(BuildContext context, [String? docId, Map<String, dynamic>? data]) {
    showDialog(
      context: context,
      builder: (context) => PatientFormDialog(
        documentId: docId,
        initialData: data,
      ),
    );
  }
  
  void _showApiStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ApiStatusWidget(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPatientDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['name'] ?? 'Patient Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Patient ID: ${data['patientId'] ?? 'N/A'}'),
              Text('Age: ${data['age'] ?? 'N/A'}'),
              Text('Condition: ${data['condition'] ?? 'N/A'}'),
              if (data['fileUrl'] != null) ...[
                const SizedBox(height: 16),
                const Text('Medical File:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (data['fileUrl'].toString().contains(RegExp(r'\.(jpg|jpeg|png|gif)')))
                  Image.network(
                    data['fileUrl'],
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.error, size: 50),
                  )
                else
                  const Icon(Icons.insert_drive_file, size: 50),
              ],
              if (data['ocrData'] != null) ...[
                const SizedBox(height: 16),
                const Text('Extracted Text:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(data['ocrData']['raw_text'] ?? 'No text extracted'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deletePatient(String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text('Are you sure you want to delete ${data['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiClient.deletePatient(docId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success'] ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class PatientFormDialog extends StatefulWidget {
  final String? documentId;
  final Map<String, dynamic>? initialData;

  const PatientFormDialog({super.key, this.documentId, this.initialData});

  @override
  State<PatientFormDialog> createState() => _PatientFormDialogState();
}

class _PatientFormDialogState extends State<PatientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _conditionController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  bool get _isEditing => widget.documentId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.initialData != null) {
      _nameController.text = widget.initialData!['name'] ?? '';
      _ageController.text = widget.initialData!['age']?.toString() ?? '';
      _conditionController.text = widget.initialData!['condition'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final age = int.parse(_ageController.text.trim());
      final condition = _conditionController.text.trim();

      Map<String, dynamic> result;
      
      if (_isEditing) {
        result = await ApiClient.updatePatient(
          documentId: widget.documentId!,
          name: name,
          age: age,
          condition: condition,
          newFile: _selectedFile,
          existingFileUrl: widget.initialData?['fileUrl'],
          existingPublicId: widget.initialData?['publicId'],
        );
      } else {
        result = await ApiClient.createPatient(
          name: name,
          age: age,
          condition: condition,
          file: _selectedFile,
        );
      }
      
      if (!result['success']) {
        throw Exception(result['message']);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patient ${_isEditing ? 'updated' : 'created'} successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Patient' : 'Add Patient'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value?.isEmpty == true ? 'Enter name' : null,
            ),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty == true ? 'Enter age' : null,
            ),
            TextFormField(
              controller: _conditionController,
              decoration: const InputDecoration(labelText: 'Condition'),
              validator: (value) => value?.isEmpty == true ? 'Enter condition' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Pick File'),
                ),
                if (_selectedFile != null)
                  Expanded(
                    child: Text(
                      ' ${_selectedFile!.name}',
                      style: const TextStyle(color: Colors.green),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
          onPressed: _isLoading ? null : _savePatient,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}