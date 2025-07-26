import 'package:flutter/material.dart';
import 'package:finalapp/services/permission_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:finalapp/utils/platform_utils.dart';

class HospitalsScreen extends StatefulWidget {
  const HospitalsScreen({super.key});

  @override
  State<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends State<HospitalsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterOption = 'All';
  bool _showFilterOptions = false;
  List<Map<String, dynamic>> _hospitals = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _defaultHospitals = [
    {
      'id': 'H001',
      'name': 'City General Hospital',
      'location': 'Downtown',
      'distance': '0.8 km',
      'rating': 4.6,
      'isRegistered': true,
      'specialties': ['Emergency', 'Cardiology', 'ICU'],
      'contact': '+1-555-0101',
      'email': 'info@citygeneral.com',
      'website': 'www.citygeneral.com',
      'openHours': '24/7',
      'patientCount': 1250,
    },
    {
      'id': 'H002',
      'name': 'Metro Medical Center',
      'location': 'Midtown',
      'distance': '1.2 km',
      'rating': 4.3,
      'isRegistered': true,
      'specialties': ['Pediatrics', 'Orthopedics', 'Radiology'],
      'contact': '+1-555-0102',
      'email': 'info@metromedical.com',
      'website': 'www.metromedical.com',
      'openHours': '6:00 AM - 10:00 PM',
      'patientCount': 890,
    },
    {
      'id': 'H003',
      'name': 'Regional Health Institute',
      'location': 'Uptown',
      'distance': '2.1 km',
      'rating': 4.8,
      'isRegistered': false,
      'specialties': ['Oncology', 'Neurology', 'Surgery'],
      'contact': '+1-555-0103',
      'email': 'info@regionalhealth.com',
      'website': 'www.regionalhealth.com',
      'openHours': '24/7',
      'patientCount': 0,
    },
    {
      'id': 'H004',
      'name': 'Community Care Hospital',
      'location': 'Suburbs',
      'distance': '3.5 km',
      'rating': 4.1,
      'isRegistered': false,
      'specialties': ['Family Medicine', 'Dermatology', 'Dental'],
      'contact': '+1-555-0104',
      'email': 'info@communitycare.com',
      'website': 'www.communitycare.com',
      'openHours': '7:00 AM - 9:00 PM',
      'patientCount': 0,
    },
    {
      'id': 'H005',
      'name': 'Sunrise Medical Plaza',
      'location': 'East Side',
      'distance': '4.2 km',
      'rating': 4.4,
      'isRegistered': true,
      'specialties': ['Gynecology', 'Psychiatry', 'Physiotherapy'],
      'contact': '+1-555-0105',
      'email': 'info@sunrisemedical.com',
      'website': 'www.sunrisemedical.com',
      'openHours': '8:00 AM - 8:00 PM',
      'patientCount': 675,
    },
    {
      'id': 'H006',
      'name': 'Westside Clinic',
      'location': 'West End',
      'distance': '5.1 km',
      'rating': 3.9,
      'isRegistered': false,
      'specialties': ['General Practice', 'Urgent Care'],
      'contact': '+1-555-0106',
      'email': 'info@westsideclinic.com',
      'website': 'www.westsideclinic.com',
      'openHours': '9:00 AM - 7:00 PM',
      'patientCount': 0,
    },
  ];

  List<Map<String, dynamic>> get _filteredHospitals {
    List<Map<String, dynamic>> result = List.from(_hospitals);
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      result = result.where((hospital) {
        return hospital['name'].toLowerCase().contains(query) ||
            hospital['location'].toLowerCase().contains(query);
      }).toList();
    }
    
    // Apply registration filter
    if (_filterOption == 'Registered') {
      result = result.where((hospital) => hospital['isRegistered']).toList();
    } else if (_filterOption == 'Unregistered') {
      result = result.where((hospital) => !hospital['isRegistered']).toList();
    }
    
    return result;
  }

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadHospitals() async {
    setState(() {
      _hospitals = _defaultHospitals;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('Hospitals'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () async {
                await _requestLocationAndRefresh();
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ],
        ),
        Expanded(
          child: Column(
        children: [
          _buildSearchAndFilter(),
          if (_showFilterOptions) _buildFilterOptions(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Nearby Hospitals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_filteredHospitals.length} hospitals',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHospitals.isEmpty
                    ? _buildEmptyState()
                    : _buildHospitalsList(),
          ),
        ],
      ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                setState(() {
                  _showFilterOptions = !_showFilterOptions;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Hospitals',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose filter to view specific hospital categories',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('All', 'Show all hospitals'),
              _buildFilterChip('Registered', 'Hospitals where you are registered'),
              _buildFilterChip('Unregistered', 'Hospitals where you are not registered'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String description) {
    final isSelected = _filterOption == label;
    final count = _getFilterCount(label);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterOption = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: Colors.blue.shade300) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getFilterCount(String filter) {
    switch (filter) {
      case 'All':
        return _hospitals.length;
      case 'Registered':
        return _hospitals.where((h) => h['isRegistered']).length;
      case 'Unregistered':
        return _hospitals.where((h) => !h['isRegistered']).length;
      default:
        return 0;
    }
  }

  Widget _buildHospitalsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredHospitals.length,
      itemBuilder: (context, index) {
        final hospital = _filteredHospitals[index];
        return _buildHospitalCard(hospital);
      },
    );
  }

  Widget _buildHospitalCard(Map<String, dynamic> hospital) {
    return GestureDetector(
      onTap: () {
        _showHospitalDetails(hospital);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  size: 40,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            hospital['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: hospital['isRegistered'] ? Colors.green.shade100 : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            hospital['isRegistered'] ? 'Registered' : 'Unregistered',
                            style: TextStyle(
                              color: hospital['isRegistered'] ? Colors.green.shade700 : Colors.orange.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${hospital['location']} • ${hospital['distance']}'),
                        const Spacer(),
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${hospital['rating']}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (hospital['isRegistered'])
                      Text(
                        'Patients: ${hospital['patientCount']}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Specialties: ${(hospital['specialties'] as List).take(2).join(', ')}${(hospital['specialties'] as List).length > 2 ? '...' : ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () {
                  _showHospitalDetails(hospital);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHospitalDetails(Map<String, dynamic> hospital) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          size: 50,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hospital['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 5),
                                Text(hospital['location']),
                                const SizedBox(width: 10),
                                Text(
                                  '(${hospital['distance']})',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 5),
                                Text(
                                  '${hospital['rating']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoSection('Specialties', hospital['specialties'].join(', ')),
                  _buildInfoSection('Contact', hospital['contact']),
                  _buildInfoSection('Email', hospital['email']),
                  _buildInfoSection('Website', hospital['website']),
                  _buildInfoSection('Open Hours', hospital['openHours']),
                  if (hospital['isRegistered'])
                    _buildInfoSection('Registered Patients', '${hospital['patientCount']} patients'),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to appointment booking
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Book Appointment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Open Google Maps
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text('Get Directions'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!hospital['isRegistered']) ...[  
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          hospital['isRegistered'] = true;
                          hospital['patientCount'] = (hospital['patientCount'] ?? 0) + 1;
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Successfully registered to ${hospital['name']}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_circle),
                      label: const Text('Register to This Hospital'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(content),
        ],
      ),
    );
  }

  Future<void> _requestLocationAndRefresh() async {
    if (PlatformUtils.isWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using default location for web platform'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      return;
    }
    
    final hasPermission = await PermissionService.requestLocationPermission();
    if (hasPermission) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location services are disabled'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        
        await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          setState(() {
            // Simulate updating distances
          });
        }
        
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get location. Using default location.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        PermissionService.showPermissionDialog(
          context,
          'Location',
          () => _requestLocationAndRefresh(),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_hospital,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No hospitals found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
