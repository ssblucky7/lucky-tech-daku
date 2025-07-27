import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:finalapp/services/quick_actions_service.dart';
import 'package:finalapp/services/permission_service.dart';
import 'package:finalapp/utils/platform_utils.dart';
import 'package:finalapp/widgets/tracked_screen.dart';
import 'package:finalapp/widgets/tracked_button.dart';

class MultiOptionsScreen extends StatefulWidget {
  const MultiOptionsScreen({super.key});

  @override
  State<MultiOptionsScreen> createState() => _MultiOptionsScreenState();
}

class _MultiOptionsScreenState extends State<MultiOptionsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _uploads = [];
  List<Map<String, dynamic>> _scans = [];
  List<Map<String, dynamic>> _qrCodes = [];
  List<Map<String, dynamic>> _sharedProfiles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final results = await Future.wait([
        QuickActionsService.getUploads(),
        QuickActionsService.getScans(),
        QuickActionsService.getQRCodes(),
        QuickActionsService.getSharedProfiles(),
      ]);
      
      setState(() {
        _uploads = results[0];
        _scans = results[1];
        _qrCodes = results[2];
        _sharedProfiles = results[3];
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TrackedScreen(
      screenName: 'multi_options_screen',
      child: Column(
        children: [
          AppBar(
            title: const Text('Options'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: [
                              _buildOptionCard(
                                title: 'Upload File',
                                icon: Icons.upload_file,
                                color: Colors.blue,
                                count: _uploads.length,
                                onTap: () => _showUploadOptions(context),
                              ),
                              _buildOptionCard(
                                title: 'Scan Document',
                                icon: Icons.document_scanner,
                                color: Colors.green,
                                count: _scans.length,
                                onTap: () => _showScanOptions(context),
                              ),
                              _buildOptionCard(
                                title: 'QR Generator',
                                icon: Icons.qr_code,
                                color: Colors.purple,
                                count: _qrCodes.length,
                                onTap: () => _showQRGenerator(context),
                              ),
                              _buildOptionCard(
                                title: 'Share Profile',
                                icon: Icons.share,
                                color: Colors.orange,
                                count: _sharedProfiles.length,
                                onTap: () => _showShareOptions(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 40,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload File',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('From Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _uploadFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _takePhotoAndUpload();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.blue),
              title: const Text('From Files'),
              onTap: () async {
                Navigator.pop(context);
                await _uploadFromFiles();
              },
            ),
            ListTile(
              leading: const Icon(Icons.list, color: Colors.blue),
              title: Text('View Uploads (${_uploads.length})'),
              onTap: () {
                Navigator.pop(context);
                _showUploadsList();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showScanOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Scan Document',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.green),
              title: const Text('Medical Report'),
              onTap: () async {
                Navigator.pop(context);
                await _scanDocument('Medical Report');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: Colors.green),
              title: const Text('Prescription'),
              onTap: () async {
                Navigator.pop(context);
                await _scanDocument('Prescription');
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: Colors.green),
              title: const Text('QR Code'),
              onTap: () async {
                Navigator.pop(context);
                await _scanDocument('QR Code');
              },
            ),
            ListTile(
              leading: const Icon(Icons.list, color: Colors.green),
              title: Text('View Scans (${_scans.length})'),
              onTap: () {
                Navigator.pop(context);
                _showScansList();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQRGenerator(BuildContext context) {
    final contentController = TextEditingController();
    final titleController = TextEditingController();
    String qrType = 'profile';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Generate QR Code'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'QR Code Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: qrType,
                  decoration: const InputDecoration(
                    labelText: 'QR Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'profile', child: Text('Profile')),
                    DropdownMenuItem(value: 'contact', child: Text('Contact')),
                    DropdownMenuItem(value: 'url', child: Text('URL')),
                    DropdownMenuItem(value: 'text', child: Text('Text')),
                  ],
                  onChanged: (value) => setDialogState(() => qrType = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => setDialogState(() {}),
                ),
                const SizedBox(height: 16),
                if (contentController.text.isNotEmpty)
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: QrImageView(
                      data: contentController.text,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TrackedButton(
              buttonName: 'generate_qr',
              screenName: 'qr_generator',
              onPressed: () async {
                if (contentController.text.isNotEmpty) {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  
                  try {
                    await QuickActionsService.generateQRCode(
                      content: contentController.text,
                      qrType: qrType,
                      title: titleController.text.isEmpty ? 'QR Code' : titleController.text,
                    );
                    
                    await _loadData();
                    
                    navigator.pop();
                    
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('QR Code generated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Error generating QR code: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter content for QR code'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Generate'),
            ),
            TrackedButton(
              buttonName: 'view_qr_codes',
              screenName: 'qr_generator',
              onPressed: () {
                Navigator.pop(context);
                _showQRCodesList();
              },
              child: Text('View All (${_qrCodes.length})'),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.orange),
              title: const Text('Create Share Link'),
              onTap: () {
                Navigator.pop(context);
                _createShareLink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.orange),
              title: const Text('Share via QR Code'),
              onTap: () {
                Navigator.pop(context);
                _shareViaQR();
              },
            ),
            ListTile(
              leading: const Icon(Icons.list, color: Colors.orange),
              title: Text('View Shared (${_sharedProfiles.length})'),
              onTap: () {
                Navigator.pop(context);
                _showSharedProfilesList();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFromGallery() async {
    final hasPermission = await PermissionService.requestPhotosPermission();
    if (hasPermission) {
      try {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        
        if (image != null) {
          await _processUpload(image.path, image.name, 'Gallery Image');
        }
      } catch (e) {
        _showError('Failed to select image from gallery');
      }
    }
  }

  Future<void> _takePhotoAndUpload() async {
    if (PlatformUtils.isWeb) {
      _showError('Camera not available on web platform');
      return;
    }
    
    final hasPermission = await PermissionService.requestCameraPermission();
    if (hasPermission) {
      try {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        
        if (image != null) {
          await _processUpload(image.path, image.name, 'Camera Photo');
        }
      } catch (e) {
        _showError('Failed to capture photo');
      }
    }
  }

  Future<void> _uploadFromFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        await _processFileUpload(file, 'Document');
      }
    } catch (e) {
      _showError('Failed to select file');
    }
  }

  Future<void> _processUpload(String filePath, String fileName, String category) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // Read file bytes and create PlatformFile
      final bytes = await _readFileBytes(filePath);
      final file = PlatformFile(
        name: fileName,
        size: bytes.length,
        bytes: bytes,
      );
      
      await QuickActionsService.uploadFile(
        file: file,
        category: category,
        description: 'Uploaded via Quick Actions',
      );
      
      await _loadData();
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showError('Failed to upload file: $e');
      }
    }
  }

  Future<Uint8List> _readFileBytes(String filePath) async {
    try {
      final file = File(filePath);
      return await file.readAsBytes();
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }

  Future<void> _processFileUpload(PlatformFile file, String category) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      await QuickActionsService.uploadFile(
        file: file,
        category: category,
        description: 'Uploaded via Quick Actions',
      );
      
      await _loadData();
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showError('Failed to upload file: $e');
      }
    }
  }

  Future<void> _scanDocument(String scanType) async {
    final hasPermission = await PermissionService.requestCameraPermission();
    if (hasPermission) {
      try {
        // Take photo for scanning
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        
        if (image != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );
          
          // Read image bytes
          final bytes = await image.readAsBytes();
          final scannedImage = PlatformFile(
            name: 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
            size: bytes.length,
            bytes: bytes,
          );
          
          final mockContent = 'Scanned $scanType content - ${DateTime.now().millisecondsSinceEpoch}';
          
          await QuickActionsService.saveScanResult(
            scanType: scanType,
            content: mockContent,
            scannedImage: scannedImage,
            extractedData: {
              'scan_date': DateTime.now().toIso8601String(),
              'scan_type': scanType,
              'confidence': 0.95,
            },
          );
          
          await _loadData();
          
          if (mounted) {
            Navigator.pop(context); // Close loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$scanType scanned successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          _showError('Failed to scan $scanType: $e');
        }
      }
    }
  }

  Future<void> _createShareLink() async {
    try {
      final profileData = {
        'name': 'John Doe',
        'patient_id': 'P12345',
        'email': 'john.doe@example.com',
        'phone': '+1234567890',
        'emergency_contact': '+0987654321',
      };
      
      final shareId = await QuickActionsService.createSharedProfile(
        profileData: profileData,
        customMessage: 'Shared via CareSync Quick Actions',
      );
      
      await _loadData();
      
      final shareLink = 'https://caresync.app/profile/$shareId';
      
      await Share.share(
        shareLink,
        subject: 'My CareSync Profile',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share link created and shared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to create share link');
    }
  }

  Future<void> _shareViaQR() async {
    try {
      final qrContent = 'caresync://profile/${DateTime.now().millisecondsSinceEpoch}';
      
      await QuickActionsService.generateQRCode(
        content: qrContent,
        qrType: 'profile',
        title: 'Profile QR Code',
      );
      
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile QR code generated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to generate profile QR code');
    }
  }

  void _showUploadsList() {
    _showListDialog('Uploads', _uploads, Icons.upload_file, Colors.blue);
  }

  void _showScansList() {
    _showListDialog('Scans', _scans, Icons.document_scanner, Colors.green);
  }

  void _showQRCodesList() {
    _showListDialog('QR Codes', _qrCodes, Icons.qr_code, Colors.purple);
  }

  void _showSharedProfilesList() {
    _showListDialog('Shared Profiles', _sharedProfiles, Icons.share, Colors.orange);
  }

  void _showListDialog(String title, List<Map<String, dynamic>> items, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: items.isEmpty
              ? const Center(child: Text('No items found'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: Icon(icon, color: color),
                      title: Text(item['title'] ?? item['file_name'] ?? item['scan_type'] ?? 'Item'),
                      subtitle: Text(item['created_at']?.toString() ?? 'No date'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteItem(title, item['id'], index),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(String type, String itemId, int index) async {
    try {
      if (type == 'Uploads') {
        await QuickActionsService.deleteUpload(itemId);
      } else if (type == 'Scans') {
        await QuickActionsService.deleteScan(itemId);
      }
      
      await _loadData();
      
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.substring(0, type.length - 1)} deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to delete item');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}