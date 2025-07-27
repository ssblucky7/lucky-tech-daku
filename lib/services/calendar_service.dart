import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finalapp/services/cloudinary_service.dart';

class CalendarService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _eventsCollection = 'caresync_calendar_events';

  // Create a new event
  static Future<String> createEvent({
    required String title,
    required String description,
    required DateTime dateTime,
    required String eventType,
    String? location,
    int? reminderMinutes,
    PlatformFile? attachment,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final docRef = _firestore.collection(_eventsCollection).doc();
      
      String? attachmentUrl;
      String? attachmentName;
      String? publicId;
      
      // Upload attachment to Cloudinary if provided
      if (attachment != null) {
        final uploadResult = await CloudinaryService.uploadFile(attachment);
        
        if (uploadResult.containsKey('success') && uploadResult['success'].toString() == 'true') {
          attachmentUrl = uploadResult['url'];
          attachmentName = attachment.name;
          publicId = uploadResult['public_id'];
        }
      }

      final eventData = {
        'id': docRef.id,
        'user_id': userId,
        'title': title,
        'description': description,
        'date_time': Timestamp.fromDate(dateTime),
        'event_type': eventType,
        'location': location ?? '',
        'reminder_minutes': reminderMinutes ?? 15,
        'attachment_url': attachmentUrl,
        'attachment_name': attachmentName,
        'public_id': publicId,
        'is_completed': false,
        'is_cancelled': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await docRef.set(eventData);
      
      if (kDebugMode) {
        debugPrint('Event created: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating event: $e');
      }
      throw Exception('Failed to create event: $e');
    }
  }

  // Get all events
  static Future<List<Map<String, dynamic>>> getEvents() async {
    try {
      final snapshot = await _firestore
          .collection(_eventsCollection)
          .orderBy('date_time', descending: false)
          .get();

      if (kDebugMode) {
        debugPrint('Found ${snapshot.docs.length} events');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting events: $e');
      }
      return [];
    }
  }

  // Get events for a specific date
  static Future<List<Map<String, dynamic>>> getEventsForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection(_eventsCollection)
          .where('date_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date_time', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('date_time', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting events for date: $e');
      }
      return [];
    }
  }

  // Get events for a month
  static Future<List<Map<String, dynamic>>> getEventsForMonth(DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final snapshot = await _firestore
          .collection(_eventsCollection)
          .where('date_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date_time', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('date_time', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting events for month: $e');
      }
      return [];
    }
  }

  // Update event
  static Future<void> updateEvent({
    required String eventId,
    String? title,
    String? description,
    DateTime? dateTime,
    String? eventType,
    String? location,
    int? reminderMinutes,
    bool? isCompleted,
    bool? isCancelled,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (dateTime != null) updateData['date_time'] = Timestamp.fromDate(dateTime);
      if (eventType != null) updateData['event_type'] = eventType;
      if (location != null) updateData['location'] = location;
      if (reminderMinutes != null) updateData['reminder_minutes'] = reminderMinutes;
      if (isCompleted != null) updateData['is_completed'] = isCompleted;
      if (isCancelled != null) updateData['is_cancelled'] = isCancelled;

      await _firestore.collection(_eventsCollection).doc(eventId).update(updateData);
      
      if (kDebugMode) {
        debugPrint('Event updated: $eventId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating event: $e');
      }
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete event
  static Future<void> deleteEvent(String eventId) async {
    try {
      final doc = await _firestore.collection(_eventsCollection).doc(eventId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final publicId = data?['public_id'] as String?;
        
        // Delete attachment from Cloudinary if exists
        if (publicId != null) {
          await CloudinaryService.deleteFile(publicId);
        }
        
        // Delete document from Firestore
        await _firestore.collection(_eventsCollection).doc(eventId).delete();
        
        if (kDebugMode) {
          debugPrint('Event deleted: $eventId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting event: $e');
      }
      throw Exception('Failed to delete event: $e');
    }
  }

  // Mark event as completed
  static Future<void> markEventCompleted(String eventId) async {
    try {
      await updateEvent(eventId: eventId, isCompleted: true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking event as completed: $e');
      }
      throw Exception('Failed to mark event as completed: $e');
    }
  }

  // Cancel event
  static Future<void> cancelEvent(String eventId) async {
    try {
      await updateEvent(eventId: eventId, isCancelled: true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error cancelling event: $e');
      }
      throw Exception('Failed to cancel event: $e');
    }
  }

  // Get upcoming events
  static Future<List<Map<String, dynamic>>> getUpcomingEvents({int limit = 10}) async {
    try {
      final now = Timestamp.now();
      final snapshot = await _firestore
          .collection(_eventsCollection)
          .where('date_time', isGreaterThan: now)
          .where('is_cancelled', isEqualTo: false)
          .orderBy('date_time', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting upcoming events: $e');
      }
      return [];
    }
  }

  // Get events by type
  static Future<List<Map<String, dynamic>>> getEventsByType(String eventType) async {
    try {
      final snapshot = await _firestore
          .collection(_eventsCollection)
          .where('event_type', isEqualTo: eventType)
          .orderBy('date_time', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting events by type: $e');
      }
      return [];
    }
  }

  // Search events
  static Future<List<Map<String, dynamic>>> searchEvents(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_eventsCollection)
          .get();

      final events = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Filter by query
      return events.where((event) {
        return event['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
               event['description'].toString().toLowerCase().contains(query.toLowerCase()) ||
               event['event_type'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error searching events: $e');
      }
      return [];
    }
  }
}