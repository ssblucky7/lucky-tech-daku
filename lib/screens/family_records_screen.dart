import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finalapp/screens/add_family_member_screen.dart';
import 'package:finalapp/screens/family_member_details_screen.dart';
import 'package:finalapp/services/family_service.dart';

class FamilyRecordsScreen extends StatefulWidget {
  const FamilyRecordsScreen({super.key});

  @override
  State<FamilyRecordsScreen> createState() => _FamilyRecordsScreenState();
}

class _FamilyRecordsScreenState extends State<FamilyRecordsScreen> {
  List<Map<String, dynamic>> familyMembers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Family Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FamilyService.getFamilyMembersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          familyMembers = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();

          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildFamilyMembersList(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddFamilyMemberScreen(
                onSave: (memberData) async {
                  try {
                    await FamilyService.createFamilyMember(
                      name: memberData['name'],
                      relation: memberData['relation'],
                      age: memberData['age'],
                      bloodGroup: memberData['bloodGroup'],
                      phone: memberData['phone'],
                      email: memberData['email'],
                      address: memberData['address'],
                      emergencyContact: memberData['emergencyContact'],
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Family member added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Family Health Records',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Manage health records for ${familyMembers.length} family members',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMembersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: familyMembers.length,
      itemBuilder: (context, index) {
        final member = familyMembers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${member['relation']} • ${member['age']} years',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Blood: ${member['bloodGroup']}',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddFamilyMemberScreen(
                              existingMember: familyMembers[index],
                              onSave: (memberData) async {
                                try {
                                  await FamilyService.updateFamilyMember(
                                    documentId: familyMembers[index]['id'],
                                    name: memberData['name'],
                                    relation: memberData['relation'],
                                    age: memberData['age'],
                                    bloodGroup: memberData['bloodGroup'],
                                    phone: memberData['phone'],
                                    email: memberData['email'],
                                    address: memberData['address'],
                                    emergencyContact: memberData['emergencyContact'],
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Family member updated successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.medical_services_outlined),
                      color: Colors.blue,
                      onPressed: () {
                        _showHealthRecordsDialog(context, index);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  void _showHealthRecordsDialog(BuildContext context, int index) {
    final member = familyMembers[index];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${member['name']}\'s Health Records'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHealthRecordItem(
                'Last Checkup',
                member['healthRecords']?['lastCheckup'] ?? 'Not recorded',
                Icons.calendar_today,
              ),
              _buildHealthRecordItem(
                'Blood Pressure',
                member['healthRecords']?['bloodPressure'] ?? 'Not recorded',
                Icons.favorite,
              ),
              _buildHealthRecordItem(
                'Blood Sugar',
                member['healthRecords']?['bloodSugar'] ?? 'Not recorded',
                Icons.water_drop,
              ),
              _buildHealthRecordItem(
                'Allergies',
                member['healthRecords']?['allergies'] ?? 'None',
                Icons.warning,
              ),
              _buildHealthRecordItem(
                'Medications',
                member['healthRecords']?['medications'] ?? 'None',
                Icons.medication,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FamilyMemberDetailsScreen(
                    member: member,
                  ),
                ),
              );
            },
            child: const Text('View Full Records'),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRecordItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
