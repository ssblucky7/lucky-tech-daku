import 'package:flutter/foundation.dart';
import 'package:finalapp/services/profile_service.dart';
import 'package:finalapp/services/profile_sync_service.dart';

class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic>? _profile;
  bool _isLoading = false;

  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;

  String get userName => _profile?['name'] ?? 'User';
  String get userEmail => _profile?['email'] ?? '';
  String? get userPhone => _profile?['phone'];
  String? get userBloodGroup => _profile?['blood_group'];
  String? get profileImageUrl => _profile?['profile_image_url'];
  bool get isEmailVerified => _profile?['is_email_verified'] ?? false;

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await ProfileService.getUserProfile();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_profile != null) {
      _profile!.addAll(updates);
      notifyListeners();
    }
  }

  void startListening() {
    ProfileSyncService.profileStream().listen((profileData) {
      if (profileData != null) {
        _profile = profileData;
        notifyListeners();
      }
    });
  }

  void clearProfile() {
    _profile = null;
    notifyListeners();
  }
}
