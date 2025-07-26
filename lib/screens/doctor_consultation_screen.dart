import 'package:flutter/material.dart';

class DoctorConsultationScreen extends StatefulWidget {
  const DoctorConsultationScreen({super.key});

  @override
  State<DoctorConsultationScreen> createState() => _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState extends State<DoctorConsultationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  List<Consultation> _upcomingConsultations = [];
  List<Consultation> _pastConsultations = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMockData();
    _filteredDoctors = _doctors;
    
    _searchController.addListener(() {
      _filterDoctors(_searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadMockData() {
    // Mock doctors data
    _doctors = [
      Doctor(
        id: '1',
        name: 'Dr. Sarah Johnson',
        specialty: 'Cardiologist',
        hospital: 'City Heart Hospital',
        rating: 4.8,
        experience: 12,
        consultationFee: 150,
        availability: ['Mon', 'Wed', 'Fri'],
        imageUrl: 'assets/images/doctor1.jpg',
        about: 'Dr. Sarah Johnson is a board-certified cardiologist with over 12 years of experience in treating heart conditions. She specializes in preventive cardiology and heart failure management.',
      ),
      Doctor(
        id: '2',
        name: 'Dr. Michael Chen',
        specialty: 'Neurologist',
        hospital: 'Central Neurology Center',
        rating: 4.7,
        experience: 15,
        consultationFee: 180,
        availability: ['Tue', 'Thu', 'Sat'],
        imageUrl: 'assets/images/doctor2.jpg',
        about: 'Dr. Michael Chen is a neurologist specializing in stroke prevention and treatment. He has conducted extensive research in neurological disorders and is committed to providing personalized care.',
      ),
      Doctor(
        id: '3',
        name: 'Dr. Emily Rodriguez',
        specialty: 'Pediatrician',
        hospital: 'Children\'s Wellness Center',
        rating: 4.9,
        experience: 10,
        consultationFee: 120,
        availability: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        imageUrl: 'assets/images/doctor3.jpg',
        about: 'Dr. Emily Rodriguez is a compassionate pediatrician dedicated to children\'s health. She focuses on developmental pediatrics and preventive care for children of all ages.',
      ),
      Doctor(
        id: '4',
        name: 'Dr. James Wilson',
        specialty: 'Orthopedic Surgeon',
        hospital: 'Advanced Orthopedic Institute',
        rating: 4.6,
        experience: 18,
        consultationFee: 200,
        availability: ['Mon', 'Wed', 'Fri'],
        imageUrl: 'assets/images/doctor4.jpg',
        about: 'Dr. James Wilson is an orthopedic surgeon specializing in sports medicine and joint replacement. He has worked with professional athletes and uses the latest minimally invasive techniques.',
      ),
      Doctor(
        id: '5',
        name: 'Dr. Aisha Patel',
        specialty: 'Dermatologist',
        hospital: 'Skin & Wellness Clinic',
        rating: 4.7,
        experience: 8,
        consultationFee: 160,
        availability: ['Tue', 'Thu', 'Sat'],
        imageUrl: 'assets/images/doctor5.jpg',
        about: 'Dr. Aisha Patel is a dermatologist specializing in medical and cosmetic dermatology. She is known for her expertise in treating complex skin conditions and her holistic approach to skin health.',
      ),
      Doctor(
        id: '6',
        name: 'Dr. Robert Kim',
        specialty: 'Psychiatrist',
        hospital: 'Mental Wellness Center',
        rating: 4.8,
        experience: 14,
        consultationFee: 170,
        availability: ['Mon', 'Wed', 'Fri'],
        imageUrl: 'assets/images/doctor6.jpg',
        about: 'Dr. Robert Kim is a psychiatrist with expertise in mood disorders and anxiety. He combines medication management with therapeutic approaches to provide comprehensive mental health care.',
      ),
    ];

    // Mock consultations data
    _upcomingConsultations = [
      Consultation(
        id: '101',
        doctor: _doctors[0],
        dateTime: DateTime.now().add(const Duration(days: 2, hours: 10)),
        type: ConsultationType.video,
        status: ConsultationStatus.confirmed,
        symptoms: ['Chest pain', 'Shortness of breath'],
        notes: 'Follow-up appointment after medication change',
      ),
      Consultation(
        id: '102',
        doctor: _doctors[2],
        dateTime: DateTime.now().add(const Duration(days: 5, hours: 14)),
        type: ConsultationType.inPerson,
        status: ConsultationStatus.pending,
        symptoms: ['Fever', 'Cough'],
        notes: 'Annual check-up',
      ),
    ];

    _pastConsultations = [
      Consultation(
        id: '103',
        doctor: _doctors[1],
        dateTime: DateTime.now().subtract(const Duration(days: 10, hours: 11)),
        type: ConsultationType.video,
        status: ConsultationStatus.completed,
        symptoms: ['Headache', 'Dizziness'],
        notes: 'Prescribed medication for migraines',
        prescription: 'Sumatriptan 50mg, take as needed for migraine',
        followUpDate: DateTime.now().add(const Duration(days: 30)),
      ),
      Consultation(
        id: '104',
        doctor: _doctors[3],
        dateTime: DateTime.now().subtract(const Duration(days: 30, hours: 15)),
        type: ConsultationType.inPerson,
        status: ConsultationStatus.completed,
        symptoms: ['Knee pain', 'Swelling'],
        notes: 'MRI recommended for left knee',
        prescription: 'Ibuprofen 600mg, twice daily for 7 days',
        followUpDate: DateTime.now().add(const Duration(days: 14)),
      ),
      Consultation(
        id: '105',
        doctor: _doctors[4],
        dateTime: DateTime.now().subtract(const Duration(days: 45, hours: 9)),
        type: ConsultationType.video,
        status: ConsultationStatus.completed,
        symptoms: ['Rash', 'Itching'],
        notes: 'Allergic reaction to new soap',
        prescription: 'Hydrocortisone cream 1%, apply twice daily',
        followUpDate: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }

  void _filterDoctors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDoctors = _doctors;
      } else {
        _filteredDoctors = _doctors
            .where((doctor) =>
                doctor.name.toLowerCase().contains(query.toLowerCase()) ||
                doctor.specialty.toLowerCase().contains(query.toLowerCase()) ||
                doctor.hospital.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showDoctorDetails(Doctor doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DoctorDetailsSheet(doctor: doctor),
    );
  }

  void _showConsultationDetails(Consultation consultation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ConsultationDetailsSheet(consultation: consultation),
    );
  }

  void _showBookConsultationForm(Doctor doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BookConsultationForm(doctor: doctor),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterOptionsSheet(
        onApplyFilters: (String? specialty, double? minRating, int? minExperience) {
          setState(() {
            _filteredDoctors = _doctors.where((doctor) {
              bool specialtyMatch = specialty == null || doctor.specialty == specialty;
              bool ratingMatch = minRating == null || doctor.rating >= minRating;
              bool experienceMatch = minExperience == null || doctor.experience >= minExperience;
              return specialtyMatch && ratingMatch && experienceMatch;
            }).toList();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search doctors...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                autofocus: true,
              )
            : const Text('Doctor Consultation'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredDoctors = _doctors;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Find Doctors'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDoctorsList(),
          _buildConsultationsList(_upcomingConsultations),
          _buildConsultationsList(_pastConsultations),
        ],
      ),
    );
  }

  Widget _buildDoctorsList() {
    if (_filteredDoctors.isEmpty) {
      return const Center(
        child: Text('No doctors found matching your criteria'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredDoctors.length,
      itemBuilder: (context, index) {
        final doctor = _filteredDoctors[index];
        return DoctorCard(
          doctor: doctor,
          onTap: () => _showDoctorDetails(doctor),
          onBookAppointment: () => _showBookConsultationForm(doctor),
        );
      },
    );
  }

  Widget _buildConsultationsList(List<Consultation> consultations) {
    if (consultations.isEmpty) {
      return const Center(
        child: Text('No consultations found'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: consultations.length,
      itemBuilder: (context, index) {
        final consultation = consultations[index];
        return ConsultationCard(
          consultation: consultation,
          onTap: () => _showConsultationDetails(consultation),
          onReschedule: () => setState(() {}),
        );
      },
    );
  }
}

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;
  final VoidCallback onBookAppointment;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
    required this.onBookAppointment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      doctor.name.substring(0, 2),
                      style: TextStyle(color: Colors.blue.shade800),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor.specialty,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor.hospital,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              doctor.rating.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.work, color: Colors.blue, size: 16),
                            const SizedBox(width: 4),
                            Text('${doctor.experience} years'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${doctor.consultationFee} per visit',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: onBookAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Book Appointment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConsultationCard extends StatelessWidget {
  final Consultation consultation;
  final VoidCallback onTap;
  final VoidCallback? onReschedule;

  const ConsultationCard({
    super.key,
    required this.consultation,
    required this.onTap,
    this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      consultation.doctor.name.substring(0, 2),
                      style: TextStyle(color: Colors.blue.shade800),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          consultation.doctor.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          consultation.doctor.specialty,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(consultation.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    consultation.type == ConsultationType.video
                        ? Icons.videocam
                        : Icons.person,
                    color: Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    consultation.type == ConsultationType.video
                        ? 'Video Consultation'
                        : 'In-Person Visit',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, color: Colors.blue, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(consultation.dateTime),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (consultation.symptoms.isNotEmpty) ...[  
                const Text(
                  'Symptoms:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: consultation.symptoms.map((symptom) {
                    return Chip(
                      label: Text(symptom, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.grey[200],
                      padding: const EdgeInsets.all(0),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
              if (consultation.status == ConsultationStatus.confirmed) ...[  
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Cancel appointment logic
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _showRescheduleDialog(context, consultation, onReschedule);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reschedule'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ConsultationStatus status) {
    Color chipColor;
    String label;
    
    switch (status) {
      case ConsultationStatus.confirmed:
        chipColor = Colors.green;
        label = 'Confirmed';
        break;
      case ConsultationStatus.pending:
        chipColor = Colors.orange;
        label = 'Pending';
        break;
      case ConsultationStatus.completed:
        chipColor = Colors.blue;
        label = 'Completed';
        break;
      case ConsultationStatus.cancelled:
        chipColor = Colors.red;
        label = 'Cancelled';
        break;
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

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    
    return '$day/$month/$year, $hour:$minute $period';
  }

  void _showRescheduleDialog(BuildContext context, Consultation consultation, VoidCallback? onReschedule) {
    DateTime selectedDate = consultation.dateTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(consultation.dateTime);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reschedule Consultation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Date'),
                subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('Time'),
                subtitle: Text(selectedTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedTime = picked;
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
                // Update the consultation date and time
                consultation.dateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                
                Navigator.pop(context);
                onReschedule?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Consultation rescheduled successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Reschedule'),
            ),
          ],
        ),
      ),
    );
  }
}

void _showRescheduleDialog(BuildContext context, Consultation consultation, [VoidCallback? onReschedule]) {
  DateTime selectedDate = consultation.dateTime;
  TimeOfDay selectedTime = TimeOfDay.fromDateTime(consultation.dateTime);

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Reschedule Consultation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Date'),
              subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
            ),
            ListTile(
              title: const Text('Time'),
              subtitle: Text(selectedTime.format(context)),
              trailing: const Icon(Icons.access_time),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Update the consultation date and time
              consultation.dateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );
              
              Navigator.pop(context);
              onReschedule?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Consultation rescheduled successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Reschedule'),
          ),
        ],
      ),
    ),
  );
}

class DoctorDetailsSheet extends StatelessWidget {
  final Doctor doctor;

  const DoctorDetailsSheet({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  doctor.name.substring(0, 2),
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 24),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialty,
                      style: TextStyle(color: Colors.grey[700], fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.hospital,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor.rating} Rating',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoSection('Experience', '${doctor.experience} years of practice'),
          _buildInfoSection('Consultation Fee', '\$${doctor.consultationFee} per session'),
          _buildInfoSection('Availability', doctor.availability.join(', ')),
          _buildInfoSection('About', doctor.about),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => BookConsultationForm(doctor: doctor),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Book Consultation', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class ConsultationDetailsSheet extends StatelessWidget {
  final Consultation consultation;

  const ConsultationDetailsSheet({super.key, required this.consultation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consultation Details',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Doctor', consultation.doctor.name),
          _buildInfoRow('Specialty', consultation.doctor.specialty),
          _buildInfoRow('Hospital', consultation.doctor.hospital),
          _buildInfoRow('Date & Time', _formatDateTime(consultation.dateTime)),
          _buildInfoRow('Type', consultation.type == ConsultationType.video ? 'Video Consultation' : 'In-Person Visit'),
          _buildInfoRow('Status', _getStatusString(consultation.status)),
          if (consultation.symptoms.isNotEmpty)
            _buildInfoRow('Symptoms', consultation.symptoms.join(', ')),
          if (consultation.notes.isNotEmpty)
            _buildInfoRow('Notes', consultation.notes),
          if (consultation.prescription != null && consultation.prescription!.isNotEmpty)
            _buildInfoRow('Prescription', consultation.prescription!),
          if (consultation.followUpDate != null)
            _buildInfoRow('Follow-up Date', _formatDate(consultation.followUpDate!)),
          const SizedBox(height: 24),
          if (consultation.status == ConsultationStatus.confirmed) ...[  
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Cancel logic
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showRescheduleDialog(context, consultation, null);
                  },
                  icon: const Icon(Icons.schedule),
                  label: const Text('Reschedule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ] else if (consultation.status == ConsultationStatus.completed) ...[  
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Book follow-up logic
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Book Follow-up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusString(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.confirmed:
        return 'Confirmed';
      case ConsultationStatus.pending:
        return 'Pending';
      case ConsultationStatus.completed:
        return 'Completed';
      case ConsultationStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    
    return '$day/$month/$year, $hour:$minute $period';
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    
    return '$day/$month/$year';
  }
}

class BookConsultationForm extends StatefulWidget {
  final Doctor doctor;

  const BookConsultationForm({super.key, required this.doctor});

  @override
  BookConsultationFormState createState() => BookConsultationFormState();
}

class BookConsultationFormState extends State<BookConsultationForm> {
  final _formKey = GlobalKey<FormState>();
  ConsultationType _consultationType = ConsultationType.video;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _symptomsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book Consultation with ${widget.doctor.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text('Consultation Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<ConsultationType>(
                      title: const Text('Video'),
                      value: ConsultationType.video,
                      groupValue: _consultationType,
                      onChanged: (ConsultationType? value) {
                        if (value != null) {
                          setState(() {
                            _consultationType = value;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<ConsultationType>(
                      title: const Text('In-Person'),
                      value: ConsultationType.inPerson,
                      groupValue: _consultationType,
                      onChanged: (ConsultationType? value) {
                        if (value != null) {
                          setState(() {
                            _consultationType = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Date'),
                      subtitle: Text(_formatDate(_selectedDate)),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null && picked != _selectedDate) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Time'),
                      subtitle: Text(_formatTime(_selectedTime)),
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null && picked != _selectedTime) {
                          setState(() {
                            _selectedTime = picked;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _symptomsController,
                decoration: const InputDecoration(
                  labelText: 'Symptoms (comma separated)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your symptoms';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consultation Fee: \$${widget.doctor.consultationFee}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Available on: ${widget.doctor.availability.join(', ')}',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Book consultation logic would go here
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Consultation request submitted!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Confirm Booking', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    
    return '$day/$month/$year';
  }

  String _formatTime(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    
    return '$hour:$minute $period';
  }
}

class FilterOptionsSheet extends StatefulWidget {
  final Function(String? specialty, double? minRating, int? minExperience) onApplyFilters;

  const FilterOptionsSheet({super.key, required this.onApplyFilters});

  @override
  FilterOptionsSheetState createState() => FilterOptionsSheetState();
}

class FilterOptionsSheetState extends State<FilterOptionsSheet> {
  String? _selectedSpecialty;
  double? _minRating;
  int? _minExperience;

  final List<String> _specialties = [
    'Cardiologist',
    'Neurologist',
    'Pediatrician',
    'Orthopedic Surgeon',
    'Dermatologist',
    'Psychiatrist',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Doctors',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text('Specialty', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedSpecialty == null,
                onSelected: (selected) {
                  setState(() {
                    _selectedSpecialty = null;
                  });
                },
              ),
              ..._specialties.map((specialty) {
                return FilterChip(
                  label: Text(specialty),
                  selected: _selectedSpecialty == specialty,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSpecialty = selected ? specialty : null;
                    });
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Any'),
                selected: _minRating == null,
                onSelected: (selected) {
                  setState(() {
                    _minRating = null;
                  });
                },
              ),
              FilterChip(
                label: const Text('4.0+'),
                selected: _minRating == 4.0,
                onSelected: (selected) {
                  setState(() {
                    _minRating = selected ? 4.0 : null;
                  });
                },
              ),
              FilterChip(
                label: const Text('4.5+'),
                selected: _minRating == 4.5,
                onSelected: (selected) {
                  setState(() {
                    _minRating = selected ? 4.5 : null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Minimum Experience', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Any'),
                selected: _minExperience == null,
                onSelected: (selected) {
                  setState(() {
                    _minExperience = null;
                  });
                },
              ),
              FilterChip(
                label: const Text('5+ years'),
                selected: _minExperience == 5,
                onSelected: (selected) {
                  setState(() {
                    _minExperience = selected ? 5 : null;
                  });
                },
              ),
              FilterChip(
                label: const Text('10+ years'),
                selected: _minExperience == 10,
                onSelected: (selected) {
                  setState(() {
                    _minExperience = selected ? 10 : null;
                  });
                },
              ),
              FilterChip(
                label: const Text('15+ years'),
                selected: _minExperience == 15,
                onSelected: (selected) {
                  setState(() {
                    _minExperience = selected ? 15 : null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  widget.onApplyFilters(_selectedSpecialty, _minRating, _minExperience);
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum ConsultationType {
  video,
  inPerson,
}

enum ConsultationStatus {
  confirmed,
  pending,
  completed,
  cancelled,
}

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String hospital;
  final double rating;
  final int experience;
  final int consultationFee;
  final List<String> availability;
  final String imageUrl;
  final String about;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.rating,
    required this.experience,
    required this.consultationFee,
    required this.availability,
    required this.imageUrl,
    required this.about,
  });
}

class Consultation {
  final String id;
  final Doctor doctor;
  DateTime dateTime;
  final ConsultationType type;
  final ConsultationStatus status;
  final List<String> symptoms;
  final String notes;
  final String? prescription;
  final DateTime? followUpDate;

  Consultation({
    required this.id,
    required this.doctor,
    required this.dateTime,
    required this.type,
    required this.status,
    required this.symptoms,
    required this.notes,
    this.prescription,
    this.followUpDate,
  });
}
