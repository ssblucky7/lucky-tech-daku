import 'package:flutter/material.dart';
import 'package:finalapp/services/analytics_service.dart';
import 'package:finalapp/widgets/tracked_screen.dart';
import 'package:finalapp/widgets/tracked_button.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _activityData = [];
  List<Map<String, dynamic>> _reports = [];
  Map<String, dynamic> _summary = {};

  bool _isLoading = true;
  String _selectedTimeRange = 'Last 7 days';
  final List<String> _timeRanges = ['Last 7 days', 'Last 30 days', 'Last 90 days', 'All time'];
  
  // Activity type counts
  Map<String, int> _activityTypeCounts = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final endDate = DateTime.now();
      final startDate = _getStartDateForRange(_selectedTimeRange, endDate);
      
      final results = await Future.wait([
        AnalyticsService.getUserAnalytics(limit: 100, startDate: startDate, endDate: endDate),
        AnalyticsService.getAnalyticsSummary(startDate: startDate, endDate: endDate),
        AnalyticsService.getReports(),
        // AnalyticsService.getActivityTrends(startDate: startDate, endDate: endDate),
      ]);
      
      setState(() {
        _activityData = results[0] as List<Map<String, dynamic>>;
        _summary = results[1] as Map<String, dynamic>;
        _reports = results[2] as List<Map<String, dynamic>>;
        // _trends = results[3] as Map<String, List<Map<String, dynamic>>>;
        _isLoading = false;
      });
      
      _processActivityData(_activityData);
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  DateTime _getStartDateForRange(String range, DateTime endDate) {
    switch (range) {
      case 'Last 7 days':
        return endDate.subtract(const Duration(days: 7));
      case 'Last 30 days':
        return endDate.subtract(const Duration(days: 30));
      case 'Last 90 days':
        return endDate.subtract(const Duration(days: 90));
      case 'All time':
        return DateTime(2020, 1, 1);
      default:
        return endDate.subtract(const Duration(days: 7));
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
              Tab(text: 'Reports'),
              Tab(text: 'Insights'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAllData,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) {
                setState(() {
                  _selectedTimeRange = value;
                });
                _loadAllData();
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
                  _buildReportsTab(),
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
                  Text('Total Activities: ${_summary['total_activities'] ?? 0}'),
                  const SizedBox(height: 16),
                  const Text('Activity Breakdown:'),
                  const SizedBox(height: 8),
                  ...(_summary['activity_types'] as Map<String, dynamic>? ?? {}).entries.map((entry) {
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
                              trailing: IconButton(
                                icon: const Icon(Icons.info_outline),
                                onPressed: () => _showActivityDetails(activity),
                              ),
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
  
  Widget _buildReportsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Analytics Reports (${_reports.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              TrackedButton(
                buttonName: 'generate_report',
                screenName: 'analytics_dashboard',
                onPressed: _showGenerateReportDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Generate Report'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _reports.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No reports generated yet'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    return _buildReportCard(report);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildReportCard(Map<String, dynamic> report) {
    final startDate = (report['start_date'] as dynamic);
    final endDate = (report['end_date'] as dynamic);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(report['title'] ?? 'Analytics Report'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${report['report_type']}'),
            Text('Period: ${_formatTimestamp(startDate)} - ${_formatTimestamp(endDate)}'),
            Text('Records: ${report['total_records'] ?? 0}'),
          ],
        ),
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.analytics, color: Colors.white),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleReportAction(value, report),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 16),
                  SizedBox(width: 8),
                  Text('View'),
                ],
              ),
            ),
            if (report['attachment_url'] != null)
              const PopupMenuItem(
                value: 'attachment',
                child: Row(
                  children: [
                    Icon(Icons.attach_file, size: 16),
                    SizedBox(width: 8),
                    Text('View Attachment'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, size: 16),
                  SizedBox(width: 8),
                  Text('Export'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
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
      if (activity['activity_type'] == 'screen_view') {
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
      case 'screen_view':
        return Icons.visibility;
      case 'button_click':
        return Icons.touch_app;
      case 'form_submit':
        return Icons.send;
      case 'file_upload':
        return Icons.upload_file;
      case 'data_update':
        return Icons.update;
      case 'search':
        return Icons.search;
      case 'error':
        return Icons.error_outline;
      case 'navigation':
        return Icons.navigation;
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'user_action':
        return Icons.person_outline;
      case 'app_start':
        return Icons.play_arrow;
      default:
        return Icons.help_outline;
    }
  }
  
  void _showGenerateReportDialog() {
    final titleController = TextEditingController();
    String reportType = 'activity_summary';
    DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime endDate = DateTime.now();
    PlatformFile? attachment;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Generate Analytics Report'),
          content: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Report Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: reportType,
                    decoration: const InputDecoration(
                      labelText: 'Report Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'activity_summary', child: Text('Activity Summary')),
                      DropdownMenuItem(value: 'usage_patterns', child: Text('Usage Patterns')),
                      DropdownMenuItem(value: 'performance_metrics', child: Text('Performance Metrics')),
                      DropdownMenuItem(value: 'custom', child: Text('Custom Report')),
                    ],
                    onChanged: (value) => setDialogState(() => reportType = value!),
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
                          attachment != null ? Icons.check_circle : Icons.attach_file,
                          size: 48,
                          color: attachment != null ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          attachment != null 
                              ? 'Attachment: ${attachment!.name}'
                              : 'No attachment',
                          style: TextStyle(
                            color: attachment != null ? Colors.green : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              FilePickerResult? result = await FilePicker.platform.pickFiles(
                                type: FileType.any,
                                allowMultiple: false,
                              );
                              
                              if (result != null && result.files.isNotEmpty) {
                                setDialogState(() {
                                  attachment = result.files.first;
                                });
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error selecting file: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Add Attachment'),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TrackedButton(
              buttonName: 'generate_report_confirm',
              screenName: 'generate_report_dialog',
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  if (!mounted) return;
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  
                  try {
                    await AnalyticsService.generateReport(
                      reportType: reportType,
                      title: titleController.text,
                      startDate: startDate,
                      endDate: endDate,
                      attachment: attachment,
                    );
                    
                    await _loadAllData();
                    
                    navigator.pop();
                    
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Report generated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to generate report: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _handleReportAction(String action, Map<String, dynamic> report) async {
    switch (action) {
      case 'view':
        _showReportDetails(report);
        break;
      case 'attachment':
        if (report['attachment_url'] != null) {
          _showReportAttachment(report);
        }
        break;
      case 'export':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export functionality coming soon')),
        );
        break;
      case 'delete':
        await _deleteReport(report['id']);
        break;
    }
  }
  
  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report['title'] ?? 'Report Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${report['report_type']}'),
              const SizedBox(height: 8),
              Text('Total Records: ${report['total_records'] ?? 0}'),
              const SizedBox(height: 8),
              Text('Status: ${report['status']}'),
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
  
  void _showReportAttachment(Map<String, dynamic> report) {
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
                      'Attachment - ${report['title']}',
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
                    report['attachment_url'],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Failed to load attachment'),
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
  
  Future<void> _deleteReport(String reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TrackedButton(
            buttonName: 'confirm_delete_report',
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
      try {
        await AnalyticsService.deleteReport(reportId);
        await _loadAllData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting report: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}