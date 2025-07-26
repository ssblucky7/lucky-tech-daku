import 'package:flutter/material.dart';
import 'package:finalapp/services/activity_tracking_service.dart';
import 'package:finalapp/services/firebase_service.dart';
import 'package:finalapp/widgets/tracked_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _activityData = [];
  bool _isLoading = true;
  String _selectedTimeRange = 'Last 7 days';
  final List<String> _timeRanges = ['Last 7 days', 'Last 30 days', 'Last 90 days', 'All time'];
  
  // Activity type counts
  Map<String, int> _activityTypeCounts = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadActivityData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadActivityData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = FirebaseService.auth.currentUser?.uid;
      if (userId == null) {
        if (kDebugMode) debugPrint('Cannot load activity data: User not authenticated');
        setState(() {
          _isLoading = false;
          _activityData = [];
        });
        return;
      }
      
      // Get activity history
      final activityData = await ActivityTrackingService.getUserActivityHistory(userId, limit: 100);
      
      // Process activity data
      _processActivityData(activityData);
      
      setState(() {
        _activityData = activityData;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading activity data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _processActivityData(List<Map<String, dynamic>> data) {
    // Reset counts
    _activityTypeCounts = {};
    
    // Count activities by type
    for (final activity in data) {
      final type = activity['activity_type'] as String;
      _activityTypeCounts[type] = (_activityTypeCounts[type] ?? 0) + 1;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return TrackedScreen(
      screenName: 'analytics_dashboard',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity Analytics'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Activity Log'),
              Tab(text: 'Insights'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadActivityData,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) {
                setState(() {
                  _selectedTimeRange = value;
                });
                _loadActivityData();
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildActivityLogTab(),
                  _buildInsightsTab(),
                ],
              ),
      ),
    );
  }
  
  Widget _buildOverviewTab() {
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
                  Text('Total Activities: ${_activityData.length}'),
                  const SizedBox(height: 16),
                  const Text('Activity Breakdown:'),
                  const SizedBox(height: 8),
                  ..._activityTypeCounts.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(_formatActivityType(entry.key)),
                          ),
                          Text('${entry.value}'),
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
                    'Recent Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _activityData.isEmpty
                      ? const Text('No recent activity')
                      : Column(
                          children: _activityData.take(5).map((activity) {
                            return ListTile(
                              title: Text(activity['description'] ?? 'Unknown activity'),
                              subtitle: Text(
                                _formatTimestamp(activity['timestamp']),
                                style: const TextStyle(fontSize: 12),
                              ),
                              leading: Icon(_getActivityIcon(activity['activity_type'])),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityLogTab() {
    return _activityData.isEmpty
        ? const Center(child: Text('No activity data available'))
        : ListView.builder(
            itemCount: _activityData.length,
            itemBuilder: (context, index) {
              final activity = _activityData[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(activity['description'] ?? 'Unknown activity'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTimestamp(activity['timestamp']),
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Type: ${_formatActivityType(activity['activity_type'])}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(_getActivityIcon(activity['activity_type']), color: Colors.blue),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showActivityDetails(activity),
                  ),
                ),
              );
            },
          );
  }
  
  Widget _buildInsightsTab() {
    // This would typically contain charts and visualizations
    // For simplicity, we'll just show some basic stats
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
                    'Usage Patterns',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Most Active Screens:'),
                  const SizedBox(height: 8),
                  _buildMostActiveScreens(),
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
                    'Activity Trends',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This section would typically contain charts showing activity trends over time.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMostActiveScreens() {
    // Count screen views
    final screenCounts = <String, int>{};
    for (final activity in _activityData) {
      if (activity['activity_type'] == ActivityTrackingService.screenView) {
        final metadata = activity['metadata'] as Map<String, dynamic>?;
        if (metadata != null && metadata.containsKey('screen_name')) {
          final screenName = metadata['screen_name'] as String;
          screenCounts[screenName] = (screenCounts[screenName] ?? 0) + 1;
        }
      }
    }
    
    // Sort screens by count
    final sortedScreens = screenCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedScreens.isEmpty
        ? const Text('No screen view data available')
        : Column(
            children: sortedScreens.take(5).map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(entry.key),
                    ),
                    Text('${entry.value} views'),
                  ],
                ),
              );
            }).toList(),
          );
  }
  
  void _showActivityDetails(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activity Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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