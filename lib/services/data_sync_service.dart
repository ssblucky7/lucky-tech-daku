import 'package:flutter/foundation.dart';
import 'api_client.dart';

class DataSyncService {
  static bool _isOnline = true;
  static final List<Map<String, dynamic>> _offlineQueue = [];

  static bool get isOnline => _isOnline;
  static List<Map<String, dynamic>> get offlineQueue => _offlineQueue;

  static Future<void> checkConnectivity() async {
    try {
      final result = await ApiClient.healthCheck();
      _isOnline = result['success'];
      
      if (_isOnline && _offlineQueue.isNotEmpty) {
        await _processOfflineQueue();
      }
    } catch (e) {
      _isOnline = false;
      if (kDebugMode) debugPrint('Connectivity check failed: $e');
    }
  }

  static Future<Map<String, dynamic>> createPatientWithSync({
    required String name,
    required int age,
    required String condition,
    dynamic file,
  }) async {
    final operation = {
      'type': 'create_patient',
      'data': {
        'name': name,
        'age': age,
        'condition': condition,
        'file': file,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (_isOnline) {
      try {
        return await ApiClient.createPatient(
          name: name,
          age: age,
          condition: condition,
          file: file,
        );
      } catch (e) {
        _addToOfflineQueue(operation);
        return {
          'success': false,
          'message': 'Saved offline. Will sync when connection is restored.',
          'offline': true,
        };
      }
    } else {
      _addToOfflineQueue(operation);
      return {
        'success': false,
        'message': 'Saved offline. Will sync when connection is restored.',
        'offline': true,
      };
    }
  }

  static Future<Map<String, dynamic>> updatePatientWithSync({
    required String documentId,
    required String name,
    required int age,
    required String condition,
    dynamic newFile,
    String? existingFileUrl,
    String? existingPublicId,
  }) async {
    final operation = {
      'type': 'update_patient',
      'data': {
        'documentId': documentId,
        'name': name,
        'age': age,
        'condition': condition,
        'newFile': newFile,
        'existingFileUrl': existingFileUrl,
        'existingPublicId': existingPublicId,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (_isOnline) {
      try {
        return await ApiClient.updatePatient(
          documentId: documentId,
          name: name,
          age: age,
          condition: condition,
          newFile: newFile,
          existingFileUrl: existingFileUrl,
          existingPublicId: existingPublicId,
        );
      } catch (e) {
        _addToOfflineQueue(operation);
        return {
          'success': false,
          'message': 'Saved offline. Will sync when connection is restored.',
          'offline': true,
        };
      }
    } else {
      _addToOfflineQueue(operation);
      return {
        'success': false,
        'message': 'Saved offline. Will sync when connection is restored.',
        'offline': true,
      };
    }
  }

  static void _addToOfflineQueue(Map<String, dynamic> operation) {
    _offlineQueue.add(operation);
    if (kDebugMode) {
      debugPrint('Added operation to offline queue: ${operation['type']}');
    }
  }

  static Future<void> _processOfflineQueue() async {
    if (kDebugMode) {
      debugPrint('Processing ${_offlineQueue.length} offline operations...');
    }

    final List<Map<String, dynamic>> failedOperations = [];

    for (final operation in _offlineQueue) {
      try {
        await _executeOperation(operation);
        if (kDebugMode) {
          debugPrint('Successfully synced: ${operation['type']}');
        }
      } catch (e) {
        failedOperations.add(operation);
        if (kDebugMode) {
          debugPrint('Failed to sync: ${operation['type']} - $e');
        }
      }
    }

    _offlineQueue.clear();
    _offlineQueue.addAll(failedOperations);

    if (kDebugMode) {
      debugPrint('Offline sync completed. ${failedOperations.length} operations failed.');
    }
  }

  static Future<void> _executeOperation(Map<String, dynamic> operation) async {
    final type = operation['type'];
    final data = operation['data'];

    switch (type) {
      case 'create_patient':
        await ApiClient.createPatient(
          name: data['name'],
          age: data['age'],
          condition: data['condition'],
          file: data['file'],
        );
        break;
      case 'update_patient':
        await ApiClient.updatePatient(
          documentId: data['documentId'],
          name: data['name'],
          age: data['age'],
          condition: data['condition'],
          newFile: data['newFile'],
          existingFileUrl: data['existingFileUrl'],
          existingPublicId: data['existingPublicId'],
        );
        break;
      case 'delete_patient':
        await ApiClient.deletePatient(data['documentId']);
        break;
      default:
        throw Exception('Unknown operation type: $type');
    }
  }

  static Future<void> clearOfflineQueue() async {
    _offlineQueue.clear();
    if (kDebugMode) {
      debugPrint('Offline queue cleared');
    }
  }

  static int getOfflineQueueCount() {
    return _offlineQueue.length;
  }
}