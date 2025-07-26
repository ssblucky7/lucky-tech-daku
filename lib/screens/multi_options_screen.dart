import 'package:flutter/material.dart';
import 'dart:math';
import 'package:finalapp/services/permission_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finalapp/utils/platform_utils.dart';

class MultiOptionsScreen extends StatefulWidget {
  const MultiOptionsScreen({super.key});

  @override
  State<MultiOptionsScreen> createState() => _MultiOptionsScreenState();
}

class _MultiOptionsScreenState extends State<MultiOptionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('Options'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ],
        ),
        Expanded(
          child: Padding(
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
                        onTap: () => _showUploadOptions(context),
                      ),
                      _buildOptionCard(
                        title: 'Scan Document',
                        icon: Icons.document_scanner,
                        color: Colors.green,
                        onTap: () => _showScanOptions(context),
                      ),
                      _buildOptionCard(
                        title: 'QR Generator',
                        icon: Icons.qr_code,
                        color: Colors.purple,
                        onTap: () => _showQRGenerator(context),
                      ),
                      _buildOptionCard(
                        title: 'Share Profile',
                        icon: Icons.share,
                        color: Colors.orange,
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
    );
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required Color color,
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
                await _requestStorageAndPickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _requestCameraAndTakePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.blue),
              title: const Text('From Files'),
              onTap: () async {
                Navigator.pop(context);
                await _requestStoragePermission('Files');
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
                await _requestCameraForScan('Medical Report');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: Colors.green),
              title: const Text('Prescription'),
              onTap: () async {
                Navigator.pop(context);
                await _requestCameraForScan('Prescription');
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: Colors.green),
              title: const Text('QR Code'),
              onTap: () async {
                Navigator.pop(context);
                await _requestCameraForScan('QR Code');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQRGenerator(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code,
                  size: 150,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Patient ID: P12345'),
            const Text('Profile: John Doe'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR Code saved to gallery')),
              );
            },
            child: const Text('Save'),
          ),
        ],
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
              title: const Text('Share Link'),
              onTap: () {
                Navigator.pop(context);
                _generateShareLink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.orange),
              title: const Text('Share QR Code'),
              onTap: () {
                Navigator.pop(context);
                _showQRGenerator(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestCameraAndTakePhoto() async {
    if (PlatformUtils.isWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera not available on web platform'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
        if (image != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo captured successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to capture photo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        PermissionService.showPermissionDialog(
          context,
          'Camera',
          () => _requestCameraAndTakePhoto(),
        );
      }
    }
  }

  Future<void> _requestStorageAndPickImage(ImageSource source) async {
    final hasPermission = await PermissionService.requestPhotosPermission();
    if (hasPermission) {
      try {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        if (image != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image selected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to select image'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        PermissionService.showPermissionDialog(
          context,
          'Storage',
          () => _requestStorageAndPickImage(source),
        );
      }
    }
  }

  Future<void> _requestStoragePermission(String type) async {
    final hasPermission = await PermissionService.requestStoragePermission();
    if (hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$type access granted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        PermissionService.showPermissionDialog(
          context,
          'Storage',
          () => _requestStoragePermission(type),
        );
      }
    }
  }

  Future<void> _requestCameraForScan(String type) async {
    final hasPermission = await PermissionService.requestCameraPermission();
    if (hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanning $type...')),
        );
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$type scanned successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    } else {
      if (mounted) {
        PermissionService.showPermissionDialog(
          context,
          'Camera',
          () => _requestCameraForScan(type),
        );
      }
    }
  }

  void _generateShareLink() {
    final random = Random();
    final linkId = random.nextInt(999999).toString().padLeft(6, '0');
    final shareLink = 'https://caresync.app/profile/$linkId';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share link generated: $shareLink'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link copied to clipboard')),
            );
          },
        ),
      ),
    );
  }
}
