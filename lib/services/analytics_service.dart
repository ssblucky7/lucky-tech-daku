import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finalapp/services/cloudinary_service.dart';

class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _analyticsCollection = 'caresync_analytics';
  static const String _reportsCollection = 'caresync_analytics_reports';

  // Track user activity
  static Future<void> trackActivity({
    required String activityType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final docRef = _firestore.collection(_analyticsCollection).doc();
      
      final activityData = {
        'id': docRef.id,
        'user_id': userId,
        'activity_type': activityType,
        'description': description,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
        'app_version': '1.0.0',
        'created_at': FieldValue.serverTimestamp(),
      };

      await docRef.set(activityData);
      
      if (kDebugMode) {
        debugPrint('Activity tracked: $activityType');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error tracking activity: $e');
      }
    }
  }

  // Get user analytics data
  static Future<List<Map<String, dynamic>>> getUserAnalytics({
    int limit = 100,
    String? activityType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_analyticsCollection)
          .orderBy('timestamp', descending: true);

      if (activityType != null) {
        query = query.where('activity_type', isEqualTo: activityType);
      }

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.limit(limit).get();

      if (kDebugMode) {
        debugPrint('Found ${snapshot.docs.length} analytics records');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting analytics: $e');
      }
      return [];
    }
  }

  // Get analytics summary
  static Future<Map<String, dynamic>> getAnalyticsSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(_analyticsCollection);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final activities = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      // Process data
      final summary = <String, dynamic>{
        'total_activities': activities.length,
        'activity_types': <String, int>{},
        'screen_views': <String, int>{},
        'button_clicks': <String, int>{},
        'daily_activity': <String, int>{},
        'most_active_day': '',
        'most_used_feature': '',
      };

      // Count by activity type
      for (final activity in activities) {
        final type = activity['activity_type'] as String;
        summary['activity_types'][type] = (summary['activity_types'][type] ?? 0) + 1;

        // Count screen views
        if (type == 'screen_view') {
          final metadata = activity['metadata'] as Map<String, dynamic>?;
          if (metadata != null && metadata.containsKey('screen_name')) {
            final screenName = metadata['screen_name'] as String;
            summary['screen_views'][screenName] = (summary['screen_views'][screenName] ?? 0) + 1;
          }
        }

        // Count button clicks
        if (type == 'button_click') {
          final metadata = activity['metadata'] as Map<String, dynamic>?;
          if (metadata != null && metadata.containsKey('button_name')) {
            final buttonName = metadata['button_name'] as String;
            summary['button_clicks'][buttonName] = (summary['button_clicks'][buttonName] ?? 0) + 1;
          }
        }

        // Count daily activity
        final timestamp = activity['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          summary['daily_activity'][dateKey] = (summary['daily_activity'][dateKey] ?? 0) + 1;
        }
      }

      // Find most active day
      if (summary['daily_activity'].isNotEmpty) {
        final mostActiveEntry = (summary['daily_activity'] as Map<String, int>)
            .entries
            .reduce((a, b) => a.value > b.value ? a : b);
        summary['most_active_day'] = mostActiveEntry.key;
      }

      // Find most used feature
      if (summary['screen_views'].isNotEmpty) {
        final mostUsedEntry = (summary['screen_views'] as Map<String, int>)
            .entries
            .reduce((a, b) => a.value > b.value ? a : b);
        summary['most_used_feature'] = mostUsedEntry.key;
      }

      return summary;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting analytics summary: $e');
      }
      return {};
    }
  }

  // Generate analytics report
  static Future<String> generateReport({
    required String reportType,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    PlatformFile? attachment,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final docRef = _firestore.collection(_reportsCollection).doc();
      
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

      // Get analytics data for the period
      final analyticsData = await getUserAnalytics(
        startDate: startDate,
        endDate: endDate,
        limit: 1000,
      );

      final summary = await getAnalyticsSummary(
        startDate: startDate,
        endDate: endDate,
      );

      final reportData = {
        'id': docRef.id,
        'user_id': userId,
        'report_type': reportType,
        'title': title,
        'start_date': Timestamp.fromDate(startDate),
        'end_date': Timestamp.fromDate(endDate),
        'summary': summary,
        'total_records': analyticsData.length,
        'attachment_url': attachmentUrl,
        'attachment_name': attachmentName,
        'public_id': publicId,
        'status': 'generated',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await docRef.set(reportData);
      
      if (kDebugMode) {
        debugPrint('Analytics report generated: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating report: $e');
      }
      throw Exception('Failed to generate report: $e');
    }
  }

  // Get analytics reports
  static Future<List<Map<String, dynamic>>> getReports() async {
    try {
      final snapshot = await _firestore
          .collection(_reportsCollection)
          .orderBy('created_at', descending: true)
          .get();

      if (kDebugMode) {
        debugPrint('Found ${snapshot.docs.length} analytics reports');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting reports: $e');
      }
      return [];
    }
  }

  // Delete analytics report
  static Future<void> deleteReport(String reportId) async {
    try {
      final doc = await _firestore.collection(_reportsCollection).doc(reportId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final publicId = data?['public_id'] as String?;
        
        // Delete attachment from Cloudinary if exists
        if (publicId != null) {
          await CloudinaryService.deleteFile(publicId);
        }
        
        // Delete document from Firestore
        await _firestore.collection(_reportsCollection).doc(reportId).delete();
        
        if (kDebugMode) {
          debugPrint('Analytics report deleted: $reportId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting report: $e');
      }
      throw Exception('Failed to delete report: $e');
    }
  }

  // Get activity trends
  static Future<Map<String, List<Map<String, dynamic>>>> getActivityTrends({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final analytics = await getUserAnalytics(
        startDate: startDate,
        endDate: endDate,
        limit: 1000,
      );

      final trends = <String, List<Map<String, dynamic>>>{
        'daily': [],
        'hourly': [],
        'activity_type': [],
      };

      // Group by day
      final dailyData = <String, int>{};
      final hourlyData = <int, int>{};
      final typeData = <String, int>{};

      for (final activity in analytics) {
        final timestamp = activity['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          
          // Daily data
          final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          dailyData[dateKey] = (dailyData[dateKey] ?? 0) + 1;
          
          // Hourly data
          hourlyData[date.hour] = (hourlyData[date.hour] ?? 0) + 1;
        }

        // Activity type data
        final type = activity['activity_type'] as String;
        typeData[type] = (typeData[type] ?? 0) + 1;
      }

      // Convert to chart data format
      trends['daily'] = dailyData.entries.map((e) => {
        'date': e.key,
        'count': e.value,
      }).toList();

      trends['hourly'] = hourlyData.entries.map((e) => {
        'hour': e.key,
        'count': e.value,
      }).toList();

      trends['activity_type'] = typeData.entries.map((e) => {
        'type': e.key,
        'count': e.value,
      }).toList();

      return trends;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting activity trends: $e');
      }
      return {};
    }
  }

  // Clear old analytics data
  static Future<void> clearOldData({required int daysToKeep}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final snapshot = await _firestore
          .collection(_analyticsCollection)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      if (kDebugMode) {
        debugPrint('Cleared ${snapshot.docs.length} old analytics records');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing old data: $e');
      }
    }
  }

  // Export analytics data
  static Future<Map<String, dynamic>> exportData({
    required DateTime startDate,
    required DateTime endDate,
    String format = 'json',
  }) async {
    try {
      final analytics = await getUserAnalytics(
        startDate: startDate,
        endDate: endDate,
        limit: 10000,
      );

      final summary = await getAnalyticsSummary(
        startDate: startDate,
        endDate: endDate,
      );

      return {
        'export_date': DateTime.now().toIso8601String(),
        'period': {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
        'summary': summary,
        'data': analytics,
        'format': format,
        'total_records': analytics.length,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error exporting data: $e');
      }
      throw Exception('Failed to export data: $e');
    }
  }
}