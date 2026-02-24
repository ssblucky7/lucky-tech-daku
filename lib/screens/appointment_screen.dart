import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finalapp/services/appointment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  String? selectedPatient;
  final TextEditingController symptomsController = TextEditingController();
  String? selectedSpecification;
  String? selectedDoctor;
  DateTime selectedDate = DateTime.now();
  DateTime currentMonth = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
  
  final List<String> patients = ['John Doe', 'Jane Smith', 'Robert Johnson'];
  final List<String> specifications = ['General', 'Cardiology', 'Neurology', 'Orthopedics'];
  final List<String> doctors = ['Dr. Smith', 'Dr. Johnson', 'Dr. Williams', 'Dr. Brown'];

  @override
  void dispose() {
    symptomsController.dispose();
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
        title: const Text(''),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Create Appointments',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildDropdown(
                value: selectedPatient,
                hint: 'Patient',
                items: patients,
                onChanged: (value) {
                  setState(() {
                    selectedPatient = value;
                  });
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: symptomsController,
                hintText: 'Symptoms',
              ),
              const SizedBox(height: 15),
              _buildDropdown(
                value: selectedSpecification,
                hint: 'Specification',
                items: specifications,
                onChanged: (value) {
                  setState(() {
                    selectedSpecification = value;
                  });
                },
              ),
              const SizedBox(height: 15),
              _buildDropdown(
                value: selectedDoctor,
                hint: 'Doctor',
                items: doctors,
                onChanged: (value) {
                  setState(() {
                    selectedDoctor = value;
                  });
                },
              ),
              const SizedBox(height: 30),
              _buildSelectiveCalendar(),
              const SizedBox(height: 20),
              _buildTimeSelector(),
              const SizedBox(height: 15),
              _buildSelectedDate(),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
        ),
        initialValue: value,
        onChanged: onChanged,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSelectiveCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildCalendarHeader(),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                _buildWeekdayRow(),
                const SizedBox(height: 10),
                _buildSelectableCalendarGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
              });
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            DateFormat('MMMM yyyy').format(currentMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
              });
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayRow() {
    final weekdays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        final isWeekend = day == 'SA' || day == 'SU';
        return Text(
          day,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isWeekend ? (day == 'SA' ? Colors.pink : Colors.red) : Colors.black,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectableCalendarGrid() {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    List<Widget> weeks = [];
    List<Widget> currentWeek = [];
    
    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      currentWeek.add(const SizedBox(width: 35, height: 35));
    }
    
    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      final isSelected = selectedDate.year == date.year && 
                        selectedDate.month == date.month && 
                        selectedDate.day == date.day;
      final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
      
      currentWeek.add(
        GestureDetector(
          onTap: isPast ? null : () {
            setState(() {
              selectedDate = date;
            });
          },
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.blue : Colors.transparent,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.transparent,
              ),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : isPast
                          ? Colors.grey
                          : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
      
      if (currentWeek.length == 7) {
        weeks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: currentWeek,
            ),
          ),
        );
        currentWeek = [];
      }
    }
    
    // Add remaining empty cells if needed
    while (currentWeek.length < 7 && currentWeek.isNotEmpty) {
      currentWeek.add(const SizedBox(width: 35, height: 35));
    }
    
    if (currentWeek.isNotEmpty) {
      weeks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: currentWeek,
          ),
        ),
      );
    }
    
    return Column(children: weeks);
  }

  Widget _buildTimeSelector() {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: selectedTime,
        );
        if (picked != null && picked != selectedTime) {
          setState(() {
            selectedTime = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time,
              color: Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 15),
            Text(
              'Time: ${selectedTime.format(context)}',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDate() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              'Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)} at ${selectedTime.format(context)}',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () async {
            // Validate inputs
            if (selectedPatient == null || 
                symptomsController.text.isEmpty ||
                selectedSpecification == null ||
                selectedDoctor == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please fill in all fields'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
            
            try {
              // Prepare appointment data
              final appointmentData = {
                'doctor': selectedDoctor!,
                'specialty': selectedSpecification!,
                'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                'time': '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                'symptoms': symptomsController.text,
                'status': 'pending',
              };
              
              try {
                // Save to Firebase
                await AppointmentService.createAppointment(
                  patientName: selectedPatient!,
                  doctorName: selectedDoctor!,
                  specialty: selectedSpecification!,
                  date: selectedDate,
                  time: '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                  symptoms: symptomsController.text,
                );
              } catch (apiError) {
                // Fallback: Save locally if Firebase fails
                await _saveAppointmentLocally(appointmentData);
              }
              
              if (mounted) {
                // Close loading dialog
                Navigator.pop(context);
                
                // Return to previous screen
                Navigator.pop(context, true);
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appointment scheduled successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                // Close loading dialog
                Navigator.pop(context);
                
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to schedule appointment: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Add'),
        ),
        const SizedBox(width: 15),
        ElevatedButton(
          onPressed: () {
            // Handle cancel
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[400],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _saveAppointmentLocally(Map<String, dynamic> appointmentData) async {
    final prefs = await SharedPreferences.getInstance();
    final appointments = prefs.getStringList('local_appointments') ?? [];
    
    final appointmentWithId = {
      ...appointmentData,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'patient': 'Current User',
      'notes': '',
    };
    
    appointments.add(jsonEncode(appointmentWithId));
    await prefs.setStringList('local_appointments', appointments);
  }
}
