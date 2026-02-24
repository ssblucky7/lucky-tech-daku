import 'package:flutter/material.dart';
import 'package:finalapp/services/activity_tracking_service.dart';
import 'package:finalapp/services/firebase_service.dart';
import 'package:finalapp/widgets/tracked_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allUserActivities = [];
  List<Map<String, dynamic>> _filteredActivities = [];
  bool _isLoading = true;
  String _selectedTimeRange = 'Last 7 days';
  final List<String> _timeRanges = ['Last 7 days', 'Last 30 days', 'Last 90 days', 'All time'];
  String _searchQuery = '';
  String? _selectedUser;
  List<String> _userIds = [];
  Map<String, String> _userNames = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllUserActivities();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAllUserActivities() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check if current user is admin
      final currentUser = FirebaseService.auth.currentUser;
      if (currentUser == null) {
        if (kDebugMode) debugPrint('Cannot load activity data: User not authenticated');
        setState(() {
          _isLoading = false;
          _allUserActivities = [];
        });
        return;
      }
      
      // In a real app, you would check admin status here
      // For now, we'll assume the current user is an admin
      
      // Get all user activities from Firestore
      final activitiesRef = FirebaseFirestore.instance.collection('caresync_user_activities');
      final querySnapshot = await activitiesRef.orderBy('timestamp', descending: true).limit(500).get();
      
      final activities = querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Firestore Timestamp to DateTime
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
        }
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Extract unique user IDs
      final userIds = activities.map((activity) => activity['user_id'] as String).toSet().toList();
      _userIds = userIds;
      
      // Get user names for each user ID
      await _fetchUserNames(userIds);
      
      setState(() {
        _allUserActivities = activities.cast<Map<String, dynamic>>();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading all user activities: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _fetchUserNames(List<String> userIds) async {
    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      final Map<String, String> userNames = {};
      
      for (final userId in userIds) {
        final userDoc = await usersRef.doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            final String name = userData['name'] ?? userData['email'] ?? 'Unknown User';
            userNames[userId] = name;
          } else {
            userNames[userId] = 'Unknown User';
          }
        } else {
          userNames[userId] = 'Unknown User';
        }
      }
      
      setState(() {
        _userNames = userNames;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching user names: $e');
    }
  }
  
  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allUserActivities);
    
    // Apply user filter
    if (_selectedUser != null) {
      filtered = filtered.where((activity) => activity['user_id'] == _selectedUser).toList();
    }
    
    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((activity) {
        final description = activity['description']?.toString().toLowerCase() ?? '';
        final activityType = activity['activity_type']?.toString().toLowerCase() ?? '';
        final searchLower = _searchQuery.toLowerCase();
        return description.contains(searchLower) || activityType.contains(searchLower);
      }).toList();
    }
    
    // Apply time range filter
    final now = DateTime.now();
    DateTime cutoffDate;
    
    switch (_selectedTimeRange) {
      case 'Last 7 days':
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case 'Last 30 days':
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      case 'Last 90 days':
        cutoffDate = now.subtract(const Duration(days: 90));
        break;
      case 'All time':
      default:
        cutoffDate = DateTime(2000); // Very old date
        break;
    }
    
    filtered = filtered.where((activity) {
      final timestamp = activity['timestamp'];
      if (timestamp is DateTime) {
        return timestamp.isAfter(cutoffDate);
      }
      return true; // Include if timestamp is not a DateTime
    }).toList();
    
    setState(() {
      _filteredActivities = filtered;
    });
  }
  
  Future<void> _deleteActivity(String activityId) async {
    try {
      await FirebaseFirestore.instance
          .collection('caresync_user_activities')
          .doc(activityId)
          .delete();
      
      setState(() {
        _allUserActivities.removeWhere((activity) => activity['id'] == activityId);
        _applyFilters();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity deleted successfully')),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting activity: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete activity: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return TrackedScreen(
      screenName: 'admin_panel',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'User Activities'),
              Tab(text: 'Analytics'),
              Tab(text: 'Management'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAllUserActivities,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildFilterBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildUserActivitiesTab(),
                        _buildAnalyticsTab(),
                        _buildManagementTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search activities...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (value) {
                  setState(() {
                    _selectedTimeRange = value;
                  });
                  _applyFilters();
                },
                itemBuilder: (context) {
                  return _timeRanges.map((range) {
                    return PopupMenuItem<String>(
                      value: range,
                      child: Text(range),
                    );
                  }).toList();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            decoration: const InputDecoration(
              labelText: 'Filter by User',
              border: OutlineInputBorder(),
            ),
            initialValue: _selectedUser,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Users'),
              ),
              ..._userIds.map((userId) {
                return DropdownMenuItem<String?>(
                  value: userId,
                  child: Text(_userNames[userId] ?? userId),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedUser = value;
              });
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserActivitiesTab() {
    if (_filteredActivities.isEmpty) {
      return const Center(child: Text('No activities found'));
    }
    
    return ListView.builder(
      itemCount: _filteredActivities.length,
      itemBuilder: (context, index) {
        final activity = _filteredActivities[index];
        final userId = activity['user_id'] as String?;
        final userName = userId != null ? (_userNames[userId] ?? userId) : 'Unknown User';
        
        return Dismissible(
          key: Key(activity['id']),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirm Deletion'),
                content: const Text('Are you sure you want to delete this activity?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            _deleteActivity(activity['id']);
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(activity['description'] ?? 'Unknown activity'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User: $userName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Type: ${_formatActivityType(activity['activity_type'])}',
                  ),
                  Text(
                    'Time: ${_formatTimestamp(activity['timestamp'])}',
                  ),
                ],
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(_getActivityIcon(activity['activity_type']), color: Colors.blue),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showActivityDetails(activity, userName),
              ),
              isThreeLine: true,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAnalyticsTab() {
    // Count activities by type
    final activityTypeCounts = <String, int>{};
    for (final activity in _filteredActivities) {
      final type = activity['activity_type'] as String? ?? 'unknown';
      activityTypeCounts[type] = (activityTypeCounts[type] ?? 0) + 1;
    }
    
    // Count activities by user
    final userActivityCounts = <String, int>{};
    for (final activity in _filteredActivities) {
      final userId = activity['user_id'] as String? ?? 'unknown';
      userActivityCounts[userId] = (userActivityCounts[userId] ?? 0) + 1;
    }
    
    // Sort by count
    final sortedActivityTypes = activityTypeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final sortedUserActivities = userActivityCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('Time Range: $_selectedTimeRange'),
                  const SizedBox(height: 8),
                  Text('Total Activities: ${_filteredActivities.length}'),
                  const SizedBox(height: 16),
                  const Text('Activity Type Breakdown:'),
                  const SizedBox(height: 8),
                  ...sortedActivityTypes.map((entry) {
                    final percentage = (entry.value / _filteredActivities.length * 100).toStringAsFixed(1);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(_formatActivityType(entry.key)),
                              ),
                              Text('${entry.value} ($percentage%)'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: entry.value / _filteredActivities.length,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Most Active Users',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...sortedUserActivities.take(5).map((entry) {
                    final userName = _userNames[entry.key] ?? entry.key;
                    final percentage = (entry.value / _filteredActivities.length * 100).toStringAsFixed(1);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(userName),
                              ),
                              Text('${entry.value} ($percentage%)'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: entry.value / _filteredActivities.length,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildManagementTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.settings, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'User Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'This section will allow administrators to manage users and permissions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Clear Old Activity Data'),
            onPressed: () {
              _showClearDataDialog();
            },
          ),
        ],
      ),
    );
  }
  
  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Old Activity Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select how old the data should be to be deleted:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Delete data older than',
                border: OutlineInputBorder(),
              ),
              initialValue: 30,
              items: [
                const DropdownMenuItem<int>(value: 7, child: Text('7 days')),
                const DropdownMenuItem<int>(value: 30, child: Text('30 days')),
                const DropdownMenuItem<int>(value: 90, child: Text('90 days')),
                const DropdownMenuItem<int>(value: 365, child: Text('1 year')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // In a real app, this would delete old data
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data clearing functionality will be implemented in a future update')),
              );
            },
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }
  
  void _showActivityDetails(Map<String, dynamic> activity, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activity Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('User: $userName'),
              const SizedBox(height: 8),
              Text('Type: ${_formatActivityType(activity['activity_type'])}'),
              const SizedBox(height: 8),
              Text('Description: ${activity['description']}'),
              const SizedBox(height: 8),
              Text('Time: ${_formatTimestamp(activity['timestamp'])}'),
              const SizedBox(height: 8),
              Text('Platform: ${activity['platform']}'),
              const SizedBox(height: 16),
              const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildMetadataView(activity['metadata']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteActivity(activity['id']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetadataView(dynamic metadata) {
    if (metadata == null) {
      return const Text('No metadata available');
    }
    
    if (metadata is Map<String, dynamic>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: metadata.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text('${entry.key}: ${entry.value}'),
          );
        }).toList(),
      );
    }
    
    return Text(metadata.toString());
  }
  
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    if (timestamp is DateTime) {
      return DateFormat('MMM d, yyyy h:mm a').format(timestamp);
    }
    
    return timestamp.toString();
  }
  
  String _formatActivityType(String? type) {
    if (type == null) return 'Unknown';
    
    // Convert snake_case to Title Case
    return type.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  IconData _getActivityIcon(String? activityType) {
    if (activityType == null) return Icons.help_outline;
    
    switch (activityType) {
      case ActivityTrackingService.screenView:
        return Icons.visibility;
      case ActivityTrackingService.buttonClick:
        return Icons.touch_app;
      case ActivityTrackingService.formSubmit:
        return Icons.send;
      case ActivityTrackingService.fileUpload:
        return Icons.upload_file;
      case ActivityTrackingService.dataUpdate:
        return Icons.update;
      case ActivityTrackingService.search:
        return Icons.search;
      case ActivityTrackingService.error:
        return Icons.error_outline;
      case ActivityTrackingService.navigation:
        return Icons.navigation;
      case ActivityTrackingService.login:
        return Icons.login;
      case ActivityTrackingService.logout:
        return Icons.logout;
      case ActivityTrackingService.userAction:
        return Icons.person_outline;
      case ActivityTrackingService.appStart:
        return Icons.play_arrow;
      default:
        return Icons.help_outline;
    }
  }
}