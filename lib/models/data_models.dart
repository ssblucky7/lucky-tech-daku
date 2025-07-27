import 'package:cloud_firestore/cloud_firestore.dart';

// Base model for all documents
abstract class BaseModel {
  String? id;
  String? userId;
  DateTime? createdAt;
  DateTime? updatedAt;

  BaseModel({this.id, this.userId, this.createdAt, this.updatedAt});

  Map<String, dynamic> toMap();
  
  void fromMap(Map<String, dynamic> map, String docId) {
    id = docId;
    userId = map['user_id'];
    createdAt = (map['created_at'] as Timestamp?)?.toDate();
    updatedAt = (map['updated_at'] as Timestamp?)?.toDate();
  }
}

// User Profile Model
class UserProfile extends BaseModel {
  String uniqueId;
  String email;
  String name;
  String role;
  String? phone;
  String? bloodGroup;
  String? dob;
  bool profileComplete;

  UserProfile({
    super.id,
    super.userId,
    required this.uniqueId,
    required this.email,
    required this.name,
    this.role = 'patient',
    this.phone,
    this.bloodGroup,
    this.dob,
    this.profileComplete = false,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'unique_id': uniqueId,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'blood_group': bloodGroup,
      'dob': dob,
      'profile_complete': profileComplete,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String docId) {
    final profile = UserProfile(
      uniqueId: map['unique_id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'patient',
      phone: map['phone'],
      bloodGroup: map['blood_group'],
      dob: map['dob'],
      profileComplete: map['profile_complete'] ?? false,
    );
    profile.fromMap(map, docId);
    return profile;
  }
}

// Report Model
class Report extends BaseModel {
  String title;
  String patient;
  String doctor;
  DateTime date;
  String category;
  String status;
  String summary;
  String recommendations;
  int attachments;
  String type;
  String? fileUrl;
  String? fileName;
  String? publicId;

  Report({
    super.id,
    super.userId,
    required this.title,
    required this.patient,
    required this.doctor,
    required this.date,
    required this.category,
    required this.status,
    required this.summary,
    required this.recommendations,
    this.attachments = 0,
    this.type = 'report',
    this.fileUrl,
    this.fileName,
    this.publicId,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'title': title,
      'patient': patient,
      'doctor': doctor,
      'date': Timestamp.fromDate(date),
      'category': category,
      'status': status,
      'summary': summary,
      'recommendations': recommendations,
      'attachments': attachments,
      'type': type,
      'file_url': fileUrl,
      'file_name': fileName,
      'public_id': publicId,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory Report.fromMap(Map<String, dynamic> map, String docId) {
    final report = Report(
      title: map['title'] ?? '',
      patient: map['patient'] ?? '',
      doctor: map['doctor'] ?? '',
      date: map['date'] is Timestamp 
          ? (map['date'] as Timestamp).toDate() 
          : DateTime.now(),
      category: map['category'] ?? '',
      status: map['status'] ?? '',
      summary: map['summary'] ?? '',
      recommendations: map['recommendations'] ?? '',
      attachments: map['attachments'] ?? 0,
      type: map['type'] ?? 'report',
      fileUrl: map['file_url'],
      fileName: map['file_name'],
      publicId: map['public_id'],
    );
    report.fromMap(map, docId);
    return report;
  }
}