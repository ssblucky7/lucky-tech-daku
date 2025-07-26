import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ActivityTrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _collectionName = 'caresync_user_activities';
  
  // Activity types
  static const String login = 'login';
  static const String logout = 'logout';
  static const String screenView = 'screen_view';
  static const String buttonClick = 'button_click';
  static const String formSubmit = 'form_submit';
  static const String formFieldChange = 'form_field_change';
  static const String fileUpload = 'file_upload';
  static const String dataUpdate = 'data_update';
  static const String search = 'search';
  static const String error = 'error';
  static const String navigation = 'navigation';
  static const String userAction = 'user_action';
  static const String appStart = 'app_start';
  
  // Track user activity
  static Future<void> trackActivity({
    required String activityType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        if (kDebugMode) debugPrint('Cannot track activity: User not authenticated');
        return;
      }
      
      final environment = dotenv.env['ENVIRONMENT'] ?? 'development';
      final isProduction = environment.toLowerCase() == 'production';
      
      // Don't track activities in development mode if configured
      if (!isProduction && !(dotenv.env['TRACK_DEV_ACTIVITIES'] == 'true')) {
        if (kDebugMode) debugPrint('Activity tracking disabled in development mode');
        return;
      }
      
      final activityData = {
        'user_id': userId,
        'activity_type': activityType,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'mobile',
        'environment': environment,
      };
      
      // Add metadata if provided
      if (metadata != null && metadata.isNotEmpty) {
        activityData['metadata'] = metadata;
      }
      
      await _firestore.collection(_collectionName).add(activityData);
      
      if (kDebugMode) debugPrint('Activity tracked: $activityType - $description');
    } catch (e) {
      if (kDebugMode) debugPrint('Error tracking activity: $e');
    }
  }
  
  // Track screen view
  static Future<void> trackScreenView(String screenName) async {
    await trackActivity(
      activityType: screenView,
      description: 'Viewed $screenName screen',
      metadata: {'screen_name': screenName},
    );
  }
  
  // Track button click
  static Future<void> trackButtonClick(String buttonName, {String? screenName}) async {
    await trackActivity(
      activityType: buttonClick,
      description: 'Clicked $buttonName button',
      metadata: {
        'button_name': buttonName,
        if (screenName != null) 'screen_name': screenName,
      },
    );
  }
  
  // Track form submission
  static Future<void> trackFormSubmit(String formName, {Map<String, dynamic>? formData, String? screenName}) async {
    // Remove sensitive data from form data
    final safeFormData = formData != null ? _sanitizeFormData(formData) : null;
    
    await trackActivity(
      activityType: formSubmit,
      description: 'Submitted $formName form',
      metadata: {
        'form_name': formName,
        if (safeFormData != null) 'form_data': safeFormData,
        if (screenName != null) 'screen_name': screenName,
      },
    );
  }
  
  // Track file upload
  static Future<void> trackFileUpload(String fileName, String fileType, int fileSize) async {
    await trackActivity(
      activityType: fileUpload,
      description: 'Uploaded file: $fileName',
      metadata: {
        'file_name': fileName,
        'file_type': fileType,
        'file_size': fileSize,
      },
    );
  }
  
  // Track data update
  static Future<void> trackDataUpdate(String dataType, String itemId, {String? action}) async {
    await trackActivity(
      activityType: dataUpdate,
      description: '${action ?? 'Updated'} $dataType data',
      metadata: {
        'data_type': dataType,
        'item_id': itemId,
        if (action != null) 'action': action,
      },
    );
  }
  
  // Track search
  static Future<void> trackSearch(String searchTerm, String searchCategory) async {
    await trackActivity(
      activityType: search,
      description: 'Searched for "$searchTerm" in $searchCategory',
      metadata: {
        'search_term': searchTerm,
        'search_category': searchCategory,
      },
    );
  }
  
  // Track error
  static Future<void> trackError(String errorMessage, String errorSource, {StackTrace? stackTrace}) async {
    await trackActivity(
      activityType: error,
      description: 'Error in $errorSource: $errorMessage',
      metadata: {
        'error_message': errorMessage,
        'error_source': errorSource,
        if (stackTrace != null) 'stack_trace': stackTrace.toString(),
      },
    );
  }
  
  // Remove sensitive data from form data
  static Map<String, dynamic> _sanitizeFormData(Map<String, dynamic> formData) {
    final sensitiveFields = ['password', 'token', 'secret', 'credit_card', 'ssn', 'pin'];
    final sanitizedData = Map<String, dynamic>.from(formData);
    
    for (final field in sensitiveFields) {
      for (final key in sanitizedData.keys.toList()) {
        if (key.toLowerCase().contains(field)) {
          sanitizedData[key] = '***REDACTED***';
        }
      }
    }
    
    return sanitizedData;
  }
  
  // Public method to sanitize form data (used by tracked_form.dart)
  static Map<String, dynamic> sanitizeFormData(Map<String, dynamic> formData) {
    return _sanitizeFormData(formData);
  }
  
  // Get user activity history (for admin or user profile)
  static Future<List<Map<String, dynamic>>> getUserActivityHistory(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Convert Timestamp to DateTime
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
        }
        
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching user activity history: $e');
      return [];
    }
  }
  
  // Track navigation between screens
  static Future<void> trackNavigation(String navigationType, String targetScreen, Map<String, dynamic>? metadata) async {
    final navigationMetadata = <String, dynamic>{
      'navigation_type': navigationType,
      'target_screen': targetScreen,
    };
    
    // Add any additional metadata
    if (metadata != null && metadata.isNotEmpty) {
      navigationMetadata.addAll(metadata);
    }
    
    await trackActivity(
      activityType: navigation,
      description: 'Navigated to $targetScreen',
      metadata: navigationMetadata,
    );
  }
  
  // Track user actions (login, logout, etc.)
  static Future<void> trackUserAction(String actionType, Map<String, dynamic>? metadata) async {
    await trackActivity(
      activityType: userAction,
      description: 'User action: $actionType',
      metadata: {
        'action_type': actionType,
        if (metadata != null) ...metadata,
      },
    );
  }
  
  // Track form field changes
  static Future<void> trackFormFieldChange(String fieldName, String formName, {String? screenName}) async {
    await trackActivity(
      activityType: formFieldChange,
      description: 'Changed $fieldName field in $formName form',
      metadata: {
        'field_name': fieldName,
        'form_name': formName,
        if (screenName != null) 'screen_name': screenName,
      },
    );
  }
}