import 'package:flutter/material.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  final Map<String, dynamic>? existingMember;
  final Function(Map<String, dynamic>) onSave;

  const AddFamilyMemberScreen({
    super.key,
    this.existingMember,
    required this.onSave,
  });

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  
  String? _selectedRelation;
  String? _selectedBloodGroup;
  String? _selectedGender;
  bool _isEmergencyContact = false;

  final List<String> _relations = [
    'Self',
    'Spouse',
    'Son',
    'Daughter',
    'Father',
    'Mother',
    'Brother',
    'Sister',
    'Grandfather',
    'Grandmother',
    'Other'
  ];

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.existingMember != null) {
      _nameController.text = widget.existingMember!['name'];
      _ageController.text = widget.existingMember!['age'].toString();
      _selectedRelation = widget.existingMember!['relation'];
      _selectedBloodGroup = widget.existingMember!['bloodGroup'];
      _selectedGender = widget.existingMember!['gender'] ?? 'Male';
      _isEmergencyContact = widget.existingMember!['isEmergencyContact'] ?? false;
      
      // Optional fields
      if (widget.existingMember!.containsKey('height')) {
        _heightController.text = widget.existingMember!['height'].toString();
      }
      if (widget.existingMember!.containsKey('weight')) {
        _weightController.text = widget.existingMember!['weight'].toString();
      }
      if (widget.existingMember!.containsKey('medicalConditions')) {
        _medicalConditionsController.text = widget.existingMember!['medicalConditions'];
      }
      if (widget.existingMember!.containsKey('allergies')) {
        _allergiesController.text = widget.existingMember!['allergies'];
      }
      if (widget.existingMember!.containsKey('medications')) {
        _medicationsController.text = widget.existingMember!['medications'];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _medicalConditionsController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
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
        title: Text(
          widget.existingMember == null
              ? 'Add Family Member'
              : 'Edit Family Member',
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Basic Information'),
                const SizedBox(height: 16),
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildSectionTitle('Health Information'),
                const SizedBox(height: 16),
                _buildHealthInfoSection(),
                const SizedBox(height: 24),
                _buildSectionTitle('Medical History'),
                const SizedBox(height: 16),
                _buildMedicalHistorySection(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            title == 'Basic Information'
                ? Icons.person
                : title == 'Health Information'
                    ? Icons.favorite
                    : Icons.medical_services,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Relation',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.family_restroom),
                ),
                initialValue: _selectedRelation,
                onChanged: (value) {
                  setState(() {
                    _selectedRelation = value;
                  });
                },
                items: _relations.map((relation) {
                  return DropdownMenuItem<String>(
                    value: relation,
                    child: Text(relation),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a relation';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter age';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc),
                ),
                initialValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                items: _genders.map((gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a gender';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Emergency Contact'),
          subtitle: const Text('Mark as emergency contact for this person'),
          value: _isEmergencyContact,
          activeThumbColor: Colors.blue,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          onChanged: (bool value) {
            setState(() {
              _isEmergencyContact = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildHealthInfoSection() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Blood Group',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.bloodtype),
          ),
          initialValue: _selectedBloodGroup,
          onChanged: (value) {
            setState(() {
              _selectedBloodGroup = value;
            });
          },
          items: _bloodGroups.map((group) {
            return DropdownMenuItem<String>(
              value: group,
              child: Text(group),
            );
          }).toList(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a blood group';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.height),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicalHistorySection() {
    return Column(
      children: [
        TextFormField(
          controller: _medicalConditionsController,
          decoration: const InputDecoration(
            labelText: 'Medical Conditions',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.medical_information),
            hintText: 'E.g., Diabetes, Hypertension',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _allergiesController,
          decoration: const InputDecoration(
            labelText: 'Allergies',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.warning_amber),
            hintText: 'E.g., Peanuts, Penicillin',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _medicationsController,
          decoration: const InputDecoration(
            labelText: 'Current Medications',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.medication),
            hintText: 'E.g., Insulin, Aspirin',
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          widget.existingMember == null ? 'Add Member' : 'Update Member',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final memberData = {
        'name': _nameController.text,
        'relation': _selectedRelation!,
        'age': int.parse(_ageController.text),
        'bloodGroup': _selectedBloodGroup!,
        'gender': _selectedGender!,
        'isEmergencyContact': _isEmergencyContact,
        'image': widget.existingMember?['image'] ?? 'assets/images/avatar1.png',
      };

      // Add optional fields if they have values
      if (_heightController.text.isNotEmpty) {
        memberData['height'] = double.parse(_heightController.text);
      }
      if (_weightController.text.isNotEmpty) {
        memberData['weight'] = double.parse(_weightController.text);
      }
      if (_medicalConditionsController.text.isNotEmpty) {
        memberData['medicalConditions'] = _medicalConditionsController.text;
      }
      if (_allergiesController.text.isNotEmpty) {
        memberData['allergies'] = _allergiesController.text;
      }
      if (_medicationsController.text.isNotEmpty) {
        memberData['medications'] = _medicationsController.text;
      }

      widget.onSave(memberData);
      Navigator.pop(context);
    }
  }
}
