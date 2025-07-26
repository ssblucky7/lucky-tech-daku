import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Separate database collections for each app section
  static const Map<String, String> collections = {
    'users': 'caresync_users',
    'hospitals': 'caresync_hospitals', 
    'appointments': 'caresync_appointments',
    'medications': 'caresync_medications',
    'reports': 'caresync_medical_reports',
    'prescriptions': 'caresync_prescriptions',
    'certificates': 'caresync_certificates',
    'user_files': 'caresync_user_files',
    'family_members': 'caresync_family_members',
    'doctors': 'caresync_doctors',
    'consultations': 'caresync_consultations',
    'alarms': 'caresync_medication_alarms',
    'health_records': 'caresync_health_records',
    'notifications': 'caresync_notifications',
    'hospital_registrations': 'caresync_hospital_registrations',
  };
  
  // Get collection name with prefix
  static String getCollectionName(String section) {
    return collections[section] ?? 'caresync_$section';
  }

  // Initialize database with separate collections
  static Future<void> initializeDatabase() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _db.batch();
    
    // Initialize all sections
    await _initializeUserProfile(user, batch);
    await _initializeHospitals(batch);
    await _initializeMedicalSection(user.uid, batch);
    await _initializeAppointmentSection(user.uid, batch);
    await _initializeMedicationSection(user.uid, batch);
    await _initializeFamilySection(user.uid, batch);
    
    await batch.commit();
  }

  static Future<void> _initializeUserProfile(User user, WriteBatch batch) async {
    final userRef = _db.collection(getCollectionName('users')).doc(user.uid);
    final userDoc = await userRef.get();
    
    if (!userDoc.exists) {
      batch.set(userRef, {
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? 'User',
        'role': 'patient',
        'phone': '',
        'blood_group': '',
        'dob': '',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'profile_complete': false,
        'section': 'user_management',
      });
    }
  }

  static Future<void> _initializeHospitals(WriteBatch batch) async {
    final hospitalsRef = _db.collection(getCollectionName('hospitals'));
    final snapshot = await hospitalsRef.limit(1).get();
    
    if (snapshot.docs.isEmpty) {
      final hospitals = [
        {
          'name': 'City General Hospital',
          'location': 'Downtown',
          'distance': '2.5 km',
          'rating': 4.5,
          'specialties': ['Cardiology', 'Neurology', 'Pediatrics'],
          'contact': '+1-555-0101',
          'email': 'info@citygeneral.com',
          'website': 'www.citygeneral.com',
          'open_hours': '24/7',
          'patient_count': 1250,
          'created_at': FieldValue.serverTimestamp(),
          'section': 'hospital_management',
        },
        {
          'name': 'Metro Medical Center',
          'location': 'Midtown',
          'distance': '3.8 km',
          'rating': 4.3,
          'specialties': ['Orthopedics', 'Dermatology', 'Emergency'],
          'contact': '+1-555-0102',
          'email': 'contact@metromedical.com',
          'website': 'www.metromedical.com',
          'open_hours': '6:00 AM - 10:00 PM',
          'patient_count': 980,
          'created_at': FieldValue.serverTimestamp(),
          'section': 'hospital_management',
        },
      ];

      for (final hospital in hospitals) {
        batch.set(hospitalsRef.doc(), hospital);
      }
    }
  }

  static Future<void> _initializeMedicalSection(String userId, WriteBatch batch) async {
    final reportsRef = _db.collection(getCollectionName('reports'));
    batch.set(reportsRef.doc(), {
      'user_id': userId,
      'title': 'Annual Health Checkup',
      'patient': 'Current User',
      'doctor': 'Dr. Smith',
      'date': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 45))),
      'category': 'General',
      'status': 'Completed',
      'summary': 'Overall health is good.',
      'recommendations': 'Continue regular exercise.',
      'attachments': 0,
      'type': 'report',
      'section': 'medical_reports',
      'created_at': FieldValue.serverTimestamp(),
    });
  }
  
  static Future<void> _initializeAppointmentSection(String userId, WriteBatch batch) async {
    final appointmentsRef = _db.collection(getCollectionName('appointments'));
    batch.set(appointmentsRef.doc(), {
      'patient_id': userId,
      'doctor': 'Dr. Sarah Johnson',
      'specialty': 'Cardiology',
      'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
      'time': '10:00 AM',
      'symptoms': 'Chest pain, shortness of breath',
      'status': 'confirmed',
      'section': 'appointment_management',
      'created_at': FieldValue.serverTimestamp(),
    });
  }
  
  static Future<void> _initializeMedicationSection(String userId, WriteBatch batch) async {
    final medicationsRef = _db.collection(getCollectionName('medications'));
    batch.set(medicationsRef.doc(), {
      'user_id': userId,
      'name': 'Lisinopril',
      'dosage': '10mg',
      'frequency': 'Once daily',
      'time': '08:00',
      'is_active': true,
      'section': 'medication_management',
      'created_at': FieldValue.serverTimestamp(),
    });
  }
  
  static Future<void> _initializeFamilySection(String userId, WriteBatch batch) async {
    final familyRef = _db.collection(getCollectionName('family_members'));
    batch.set(familyRef.doc(), {
      'user_id': userId,
      'name': 'Current User',
      'relation': 'Self',
      'age': 30,
      'blood_group': 'O+',
      'section': 'family_management',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // Dynamic collection creation with section-based naming
  static Future<String> createDocument(String section, Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user != null) {
      data['user_id'] = user.uid;
    }
    data['section'] = section;
    data['created_at'] = FieldValue.serverTimestamp();
    data['updated_at'] = FieldValue.serverTimestamp();

    final collectionName = getCollectionName(section);
    final docRef = await _db.collection(collectionName).add(data);
    return docRef.id;
  }

  // Get documents with section-based filtering
  static Stream<QuerySnapshot> getDocuments(String section, {
    String? orderBy,
    bool descending = true,
    int? limit,
  }) {
    final user = _auth.currentUser;
    final collectionName = getCollectionName(section);
    Query query = _db.collection(collectionName);

    if (user != null && section != 'hospitals') {
      query = query.where('user_id', isEqualTo: user.uid);
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  // Update document with section-based collection
  static Future<void> updateDocument(String section, String docId, Map<String, dynamic> data) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    final collectionName = getCollectionName(section);
    await _db.collection(collectionName).doc(docId).update(data);
  }

  // Delete document from section-based collection
  static Future<void> deleteDocument(String section, String docId) async {
    final collectionName = getCollectionName(section);
    await _db.collection(collectionName).doc(docId).delete();
  }

  // Batch operations for complex updates
  static WriteBatch createBatch() => _db.batch();
  
  static Future<void> commitBatch(WriteBatch batch) async {
    await batch.commit();
  }
}