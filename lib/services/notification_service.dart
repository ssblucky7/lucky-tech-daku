import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finalapp/services/cloudinary_service.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _notificationsCollection = 'caresync_notifications';
  static const String _messagesCollection = 'caresync_messages';

  // Create notification
  static Future<String> createNotification({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
    PlatformFile? attachment,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final docRef = _firestore.collection(_notificationsCollection).doc();
      
      String? attachmentUrl;
      String? attachmentName;
      String? publicId;
      
      if (attachment != null) {
        final uploadResult = await CloudinaryService.uploadFile(attachment);
        
        if (uploadResult.containsKey('success') && uploadResult['success'].toString() == 'true') {
          attachmentUrl = uploadResult['url'];
          attachmentName = attachment.name;
          publicId = uploadResult['public_id'];
        }
      }

      final notificationData = {
        'id': docRef.id,
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data ?? {},
        'attachment_url': attachmentUrl,
        'attachment_name': attachmentName,
        'public_id': publicId,
        'is_read': false,
        'is_important': false,
        'created_at': FieldValue.serverTimestamp(),
        'read_at': null,
      };

      await docRef.set(notificationData);
      
      if (kDebugMode) {
        debugPrint('Notification created: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating notification: $e');
      }
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get user notifications
  static Future<List<Map<String, dynamic>>> getUserNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      Query query = _firestore
          .collection(_notificationsCollection)
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true);

      if (unreadOnly) {
        query = query.where('is_read', isEqualTo: false);
      }

      final snapshot = await query.limit(limit).get();

      if (kDebugMode) {
        debugPrint('Found ${snapshot.docs.length} notifications');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting notifications: $e');
      }
      return [];
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_notificationsCollection).doc(notificationId).update({
        'is_read': true,
        'read_at': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        debugPrint('Notification marked as read: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking notification as read: $e');
      }
    }
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final doc = await _firestore.collection(_notificationsCollection).doc(notificationId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final publicId = data?['public_id'] as String?;
        
        if (publicId != null) {
          await CloudinaryService.deleteFile(publicId);
        }
        
        await _firestore.collection(_notificationsCollection).doc(notificationId).delete();
        
        if (kDebugMode) {
          debugPrint('Notification deleted: $notificationId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting notification: $e');
      }
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Create message
  static Future<String> createMessage({
    required String subject,
    required String content,
    required String fromUser,
    String? toUser,
    String category = 'general',
    PlatformFile? attachment,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final docRef = _firestore.collection(_messagesCollection).doc();
      
      String? attachmentUrl;
      String? attachmentName;
      String? publicId;
      
      if (attachment != null) {
        final uploadResult = await CloudinaryService.uploadFile(attachment);
        
        if (uploadResult.containsKey('success') && uploadResult['success'].toString() == 'true') {
          attachmentUrl = uploadResult['url'];
          attachmentName = attachment.name;
          publicId = uploadResult['public_id'];
        }
      }

      final messageData = {
        'id': docRef.id,
        'user_id': userId,
        'subject': subject,
        'content': content,
        'from_user': fromUser,
        'to_user': toUser ?? userId,
        'category': category,
        'attachment_url': attachmentUrl,
        'attachment_name': attachmentName,
        'public_id': publicId,
        'is_read': false,
        'is_important': false,
        'created_at': FieldValue.serverTimestamp(),
        'read_at': null,
      };

      await docRef.set(messageData);
      
      if (kDebugMode) {
        debugPrint('Message created: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating message: $e');
      }
      throw Exception('Failed to create message: $e');
    }
  }

  // Get recent messages
  static Future<List<Map<String, dynamic>>> getRecentMessages({
    int limit = 10,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final snapshot = await _firestore
          .collection(_messagesCollection)
          .where('to_user', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      if (kDebugMode) {
        debugPrint('Found ${snapshot.docs.length} recent messages');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting recent messages: $e');
      }
      return [];
    }
  }

  // Get unread count
  static Future<int> getUnreadCount() async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final results = await Future.wait([
        _firestore
            .collection(_notificationsCollection)
            .where('user_id', isEqualTo: userId)
            .where('is_read', isEqualTo: false)
            .get(),
        _firestore
            .collection(_messagesCollection)
            .where('to_user', isEqualTo: userId)
            .where('is_read', isEqualTo: false)
            .get(),
      ]);

      final notificationCount = results[0].docs.length;
      final messageCount = results[1].docs.length;
      
      return notificationCount + messageCount;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting unread count: $e');
      }
      return 0;
    }
  }

  // Mark message as read
  static Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).update({
        'is_read': true,
        'read_at': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        debugPrint('Message marked as read: $messageId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking message as read: $e');
      }
    }
  }

  // Send system notification
  static Future<void> sendSystemNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'system',
    Map<String, dynamic>? data,
  }) async {
    try {
      await createNotification(
        title: title,
        message: message,
        type: type,
        data: data,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending system notification: $e');
      }
    }
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('user_id', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final publicId = data['public_id'] as String?;
        
        if (publicId != null) {
          await CloudinaryService.deleteFile(publicId);
        }
        
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      if (kDebugMode) {
        debugPrint('All notifications cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing notifications: $e');
      }
    }
  }
}