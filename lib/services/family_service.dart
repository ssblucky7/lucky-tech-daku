import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FamilyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'family_members';

  static Future<String> createFamilyMember({
    required String name,
    required String relation,
    required int age,
    required String bloodGroup,
    String? phone,
    String? email,
    String? address,
    String? emergencyContact,
    Map<String, dynamic>? healthRecords,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final memberData = {
        'id': docRef.id,
        'memberId': 'FM${docRef.id.substring(0, 8).toUpperCase()}',
        'name': name,
        'relation': relation,
        'age': age,
        'bloodGroup': bloodGroup,
        'phone': phone ?? '',
        'email': email ?? '',
        'address': address ?? '',
        'emergencyContact': emergencyContact ?? '',
        'healthRecords': healthRecords ?? {
          'lastCheckup': '',
          'bloodPressure': '',
          'bloodSugar': '',
          'allergies': '',
          'medications': '',
          'conditions': '',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(memberData);
      
      if (kDebugMode) {
        debugPrint('Family member created: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating family member: $e');
      }
      throw Exception('Failed to create family member: $e');
    }
  }

  static Future<void> updateFamilyMember({
    required String documentId,
    String? name,
    String? relation,
    int? age,
    String? bloodGroup,
    String? phone,
    String? email,
    String? address,
    String? emergencyContact,
    Map<String, dynamic>? healthRecords,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (relation != null) updateData['relation'] = relation;
      if (age != null) updateData['age'] = age;
      if (bloodGroup != null) updateData['bloodGroup'] = bloodGroup;
      if (phone != null) updateData['phone'] = phone;
      if (email != null) updateData['email'] = email;
      if (address != null) updateData['address'] = address;
      if (emergencyContact != null) updateData['emergencyContact'] = emergencyContact;
      if (healthRecords != null) updateData['healthRecords'] = healthRecords;

      await _firestore.collection(_collection).doc(documentId).update(updateData);
      
      if (kDebugMode) {
        debugPrint('Family member updated: $documentId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating family member: $e');
      }
      throw Exception('Failed to update family member: $e');
    }
  }

  static Future<void> deleteFamilyMember(String documentId) async {
    try {
      await _firestore.collection(_collection).doc(documentId).delete();
      
      if (kDebugMode) {
        debugPrint('Family member deleted: $documentId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting family member: $e');
      }
      throw Exception('Failed to delete family member: $e');
    }
  }

  static Stream<QuerySnapshot> getFamilyMembersStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  static Future<List<Map<String, dynamic>>> getFamilyMembers() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting family members: $e');
      }
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getFamilyMember(String documentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(documentId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting family member: $e');
      }
      return null;
    }
  }

  static Future<void> updateHealthRecords({
    required String documentId,
    required Map<String, dynamic> healthRecords,
  }) async {
    try {
      await _firestore.collection(_collection).doc(documentId).update({
        'healthRecords': healthRecords,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        debugPrint('Health records updated for: $documentId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating health records: $e');
      }
      throw Exception('Failed to update health records: $e');
    }
  }
}