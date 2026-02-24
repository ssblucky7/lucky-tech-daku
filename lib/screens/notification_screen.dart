import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finalapp/services/notification_service.dart';
import 'package:finalapp/widgets/tracked_screen.dart';
import 'package:finalapp/widgets/tracked_button.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final results = await Future.wait([
        NotificationService.getUserNotifications(),
        NotificationService.getRecentMessages(),
      ]);

      setState(() {
        _notifications = results[0];
        _messages = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TrackedScreen(
      screenName: 'notification_screen',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications & Messages'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Notifications (${_notifications.length})'),
              Tab(text: 'Messages (${_messages.length})'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreateMessageDialog,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildNotificationsTab(),
                  _buildMessagesTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return _notifications.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No notifications'),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              return _buildNotificationCard(notification);
            },
          );
  }

  Widget _buildMessagesTab() {
    return _messages.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No messages'),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildMessageCard(message);
            },
          );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final timestamp = notification['created_at'] as dynamic;
    final timeStr = timestamp != null 
        ? DateFormat('MMM dd, HH:mm').format(timestamp.toDate())
        : 'Unknown time';

    return Card(
      margin: const EdgeInsets.all(8),
      color: notification['is_read'] == false ? Colors.blue.shade50 : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification['is_read'] == false ? Colors.blue : Colors.grey,
          child: Icon(
            _getNotificationIcon(notification['type']),
            color: Colors.white,
          ),
        ),
        title: Text(
          notification['title'] ?? 'No Title',
          style: TextStyle(
            fontWeight: notification['is_read'] == false ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message'] ?? ''),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleNotificationAction(value, notification),
          itemBuilder: (context) => [
            if (notification['is_read'] == false)
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read, size: 16),
                    SizedBox(width: 8),
                    Text('Mark as Read'),
                  ],
                ),
              ),
            if (notification['attachment_url'] != null)
              const PopupMenuItem(
                value: 'view_attachment',
                child: Row(
                  children: [
                    Icon(Icons.attach_file, size: 16),
                    SizedBox(width: 8),
                    Text('View Attachment'),
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
        onTap: () async {
          if (notification['is_read'] == false) {
            await NotificationService.markAsRead(notification['id']);
            _loadData();
          }
        },
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final timestamp = message['created_at'] as dynamic;
    final timeStr = timestamp != null 
        ? DateFormat('MMM dd, HH:mm').format(timestamp.toDate())
        : 'Unknown time';

    return Card(
      margin: const EdgeInsets.all(8),
      color: message['is_read'] == false ? Colors.green.shade50 : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: message['is_read'] == false ? Colors.green : Colors.grey,
          child: const Icon(Icons.message, color: Colors.white),
        ),
        title: Text(
          message['subject'] ?? 'No Subject',
          style: TextStyle(
            fontWeight: message['is_read'] == false ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['content'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'From: ${message['from_user']} • $timeStr',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMessageAction(value, message),
          itemBuilder: (context) => [
            if (message['is_read'] == false)
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read, size: 16),
                    SizedBox(width: 8),
                    Text('Mark as Read'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 16),
                  SizedBox(width: 8),
                  Text('View Full Message'),
                ],
              ),
            ),
            if (message['attachment_url'] != null)
              const PopupMenuItem(
                value: 'view_attachment',
                child: Row(
                  children: [
                    Icon(Icons.attach_file, size: 16),
                    SizedBox(width: 8),
                    Text('View Attachment'),
                  ],
                ),
              ),
          ],
        ),
        onTap: () async {
          if (message['is_read'] == false) {
            await NotificationService.markMessageAsRead(message['id']);
            _loadData();
          }
          _showMessageDetails(message);
        },
      ),
    );
  }

  void _showCreateMessageDialog() {
    final subjectController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'general';
    PlatformFile? attachment;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Message'),
          content: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'general', child: Text('General')),
                      DropdownMenuItem(value: 'appointment', child: Text('Appointment')),
                      DropdownMenuItem(value: 'medication', child: Text('Medication')),
                      DropdownMenuItem(value: 'report', child: Text('Report')),
                    ],
                    onChanged: (value) => setDialogState(() => category = value!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'Message Content',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
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
              buttonName: 'send_message',
              screenName: 'create_message_dialog',
              onPressed: () async {
                if (subjectController.text.isNotEmpty && contentController.text.isNotEmpty) {
                  try {
                    await NotificationService.createMessage(
                      subject: subjectController.text,
                      content: contentController.text,
                      fromUser: 'System',
                      category: category,
                      attachment: attachment,
                    );
                    
                    _loadData();
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message sent successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to send message: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageDetails(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message['subject'] ?? 'Message'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('From: ${message['from_user']}'),
              const SizedBox(height: 8),
              Text('Category: ${message['category']}'),
              const SizedBox(height: 16),
              Text(message['content'] ?? ''),
              if (message['attachment_url'] != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAttachment(message),
                  icon: const Icon(Icons.attach_file),
                  label: const Text('View Attachment'),
                ),
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

  void _showAttachment(Map<String, dynamic> item) {
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
                      'Attachment - ${item['attachment_name'] ?? 'File'}',
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
                    item['attachment_url'],
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

  Future<void> _handleNotificationAction(String action, Map<String, dynamic> notification) async {
    switch (action) {
      case 'mark_read':
        await NotificationService.markAsRead(notification['id']);
        _loadData();
        break;
      case 'view_attachment':
        if (notification['attachment_url'] != null) {
          _showAttachment(notification);
        }
        break;
      case 'delete':
        await NotificationService.deleteNotification(notification['id']);
        _loadData();
        break;
    }
  }

  Future<void> _handleMessageAction(String action, Map<String, dynamic> message) async {
    switch (action) {
      case 'mark_read':
        await NotificationService.markMessageAsRead(message['id']);
        _loadData();
        break;
      case 'view':
        _showMessageDetails(message);
        break;
      case 'view_attachment':
        if (message['attachment_url'] != null) {
          _showAttachment(message);
        }
        break;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today;
      case 'medication':
        return Icons.medication;
      case 'report':
        return Icons.description;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }
}