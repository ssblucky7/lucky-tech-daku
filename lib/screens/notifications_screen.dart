import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 'N001',
      'title': 'Appointment Reminder',
      'message': 'You have an appointment with Dr. Smith tomorrow at 10:00 AM.',
      'time': '2 hours ago',
      'isRead': false,
      'type': 'appointment',
      'date': '2023-06-15',
    },
    {
      'id': 'N002',
      'title': 'Medication Reminder',
      'message': 'Time to take your Amoxicillin medication.',
      'time': '5 hours ago',
      'isRead': true,
      'type': 'medication',
      'date': '2023-06-15',
    },
    {
      'id': 'N003',
      'title': 'Lab Results Available',
      'message': 'Your recent lab results are now available. Check the Reports section to view them.',
      'time': '1 day ago',
      'isRead': false,
      'type': 'report',
      'date': '2023-06-14',
    },
    {
      'id': 'N004',
      'title': 'New Message from Dr. Johnson',
      'message': 'Dr. Johnson has sent you a message regarding your treatment plan.',
      'time': '2 days ago',
      'isRead': true,
      'type': 'message',
      'date': '2023-06-13',
    },
    {
      'id': 'N005',
      'title': 'Health Tip of the Day',
      'message': 'Staying hydrated is crucial for maintaining good health. Aim to drink at least 8 glasses of water daily.',
      'time': '3 days ago',
      'isRead': true,
      'type': 'tip',
      'date': '2023-06-12',
    },
    {
      'id': 'N006',
      'title': 'Appointment Cancelled',
      'message': 'Your appointment with Dr. Williams on June 20 has been cancelled. Please reschedule.',
      'time': '4 days ago',
      'isRead': true,
      'type': 'appointment',
      'date': '2023-06-11',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;
    
    return Column(
      children: [
        AppBar(
          title: const Text('Notifications'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                _showOptionsMenu(context);
              },
            ),
          ],
        ),
        Expanded(
          child: Column(
            children: [
              _buildNotificationHeader(unreadCount),
              Expanded(
                child: _notifications.isEmpty
                    ? _buildEmptyState()
                    : _buildNotificationsList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationHeader(int unreadCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            unreadCount > 0 ? '$unreadCount Unread Notifications' : 'All Caught Up!',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var notification in _notifications) {
                    notification['isRead'] = true;
                  }
                });
              },
              child: const Text('Mark All as Read'),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        final bool isRead = notification['isRead'];
        final String type = notification['type'];
        
        // Group notifications by date
        final bool showDateHeader = index == 0 || 
            notification['date'] != _notifications[index - 1]['date'];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDateHeader)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text(
                  _formatDate(notification['date']),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            InkWell(
              onTap: () {
                _markAsRead(notification['id']);
                _showNotificationDetails(notification);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isRead ? null : Colors.blue.withValues(alpha: 0.05),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNotificationIcon(type, isRead),
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
                                  notification['title'],
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                notification['time'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification['message'],
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),
          ],
        );
      },
    );
  }

  Widget _buildNotificationIcon(String type, bool isRead) {
    IconData iconData;
    Color iconColor;
    
    switch (type) {
      case 'appointment':
        iconData = Icons.calendar_today;
        iconColor = Colors.blue;
        break;
      case 'medication':
        iconData = Icons.medication;
        iconColor = Colors.orange;
        break;
      case 'report':
        iconData = Icons.description;
        iconColor = Colors.green;
        break;
      case 'message':
        iconData = Icons.message;
        iconColor = Colors.purple;
        break;
      case 'tip':
        iconData = Icons.lightbulb;
        iconColor = Colors.amber;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.blue;
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(iconData, color: iconColor, size: 20),
          if (!isRead)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
      }
    });
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                _buildNotificationIcon(notification['type'], true),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    notification['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              notification['message'],
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Received: ${notification['time']}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButton(notification),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> notification) {
    String buttonText;
    IconData iconData;
    VoidCallback onPressed;
    
    switch (notification['type']) {
      case 'appointment':
        buttonText = 'View Appointment';
        iconData = Icons.calendar_today;
        onPressed = () {
          Navigator.pop(context);
          // Navigate to appointment details
        };
        break;
      case 'medication':
        buttonText = 'View Medication';
        iconData = Icons.medication;
        onPressed = () {
          Navigator.pop(context);
          // Navigate to medication details
        };
        break;
      case 'report':
        buttonText = 'View Report';
        iconData = Icons.description;
        onPressed = () {
          Navigator.pop(context);
          // Navigate to report details
        };
        break;
      case 'message':
        buttonText = 'Reply to Message';
        iconData = Icons.reply;
        onPressed = () {
          Navigator.pop(context);
          // Navigate to messaging screen
        };
        break;
      default:
        buttonText = 'Dismiss';
        iconData = Icons.close;
        onPressed = () {
          Navigator.pop(context);
        };
    }
    
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(iconData),
      label: Text(buttonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 45),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionItem(
              icon: Icons.check_circle_outline,
              title: 'Mark all as read',
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  for (var notification in _notifications) {
                    notification['isRead'] = true;
                  }
                });
              },
            ),
            _buildOptionItem(
              icon: Icons.delete_outline,
              title: 'Clear all notifications',
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _notifications.clear();
                });
              },
            ),
            _buildOptionItem(
              icon: Icons.settings_outlined,
              title: 'Notification settings',
              onTap: () {
                Navigator.pop(context);
                // Navigate to notification settings
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    // This is a simple implementation. In a real app, you'd use a proper date formatting library
    final DateTime now = DateTime.now();
    final DateTime date = DateTime.parse(dateStr);
    
    if (date.year == now.year && date.month == now.month) {
      if (date.day == now.day) {
        return 'Today';
      } else if (date.day == now.day - 1) {
        return 'Yesterday';
      }
    }
    
    return dateStr; // Return the original string for simplicity
  }
}
