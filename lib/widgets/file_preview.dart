import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class FilePreview extends StatelessWidget {
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool showFileName;
  final bool enableFullScreen;

  const FilePreview({
    super.key,
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.showFileName = false,
    this.enableFullScreen = true,
  });

  bool get _isImage {
    if (fileType != null) {
      return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(fileType!.toLowerCase());
    }
    if (fileName != null) {
      final ext = fileName!.split('.').last.toLowerCase();
      return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
    }
    if (fileUrl != null) {
      return fileUrl!.contains(RegExp(r'\.(jpg|jpeg|png|gif|webp|bmp)', caseSensitive: false));
    }
    return false;
  }

  bool get _isPdf {
    if (fileType != null) return fileType!.toLowerCase() == 'pdf';
    if (fileName != null) return fileName!.toLowerCase().endsWith('.pdf');
    if (fileUrl != null) return fileUrl!.toLowerCase().contains('.pdf');
    return false;
  }

  IconData get _fileIcon {
    if (_isPdf) return Icons.picture_as_pdf;
    if (_isImage) return Icons.image;
    final type = fileType?.toLowerCase() ?? fileName?.split('.').last.toLowerCase() ?? '';
    if (['doc', 'docx'].contains(type)) return Icons.description;
    if (['xls', 'xlsx'].contains(type)) return Icons.table_chart;
    if (['zip', 'rar'].contains(type)) return Icons.folder_zip;
    if (['mp4', 'avi', 'mov'].contains(type)) return Icons.video_file;
    if (['mp3', 'wav'].contains(type)) return Icons.audio_file;
    return Icons.insert_drive_file;
  }

  Color get _fileColor {
    if (_isPdf) return Colors.red;
    if (_isImage) return Colors.blue;
    final type = fileType?.toLowerCase() ?? fileName?.split('.').last.toLowerCase() ?? '';
    if (['doc', 'docx'].contains(type)) return Colors.blue.shade700;
    if (['xls', 'xlsx'].contains(type)) return Colors.green.shade700;
    if (['zip', 'rar'].contains(type)) return Colors.orange;
    if (['mp4', 'avi', 'mov'].contains(type)) return Colors.purple;
    if (['mp3', 'wav'].contains(type)) return Colors.pink;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (fileUrl == null || fileUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: enableFullScreen ? () => _openFullScreen(context) : null,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _isImage ? _buildImagePreview() : _buildFilePreview(),
            ),
          ),
        ),
        if (showFileName && fileName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              fileName!,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return CachedNetworkImage(
      imageUrl: fileUrl!,
      fit: fit,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildFilePreview() {
    return Container(
      color: _fileColor.withValues(alpha: 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_fileIcon, size: 48, color: _fileColor),
          if (fileName != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                fileName!,
                style: TextStyle(fontSize: 12, color: _fileColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width ?? 100,
      height: height ?? 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  void _openFullScreen(BuildContext context) {
    if (_isImage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenImageViewer(
            imageUrl: fileUrl!,
            fileName: fileName,
          ),
        ),
      );
    } else {
      _openFile();
    }
  }

  Future<void> _openFile() async {
    if (fileUrl != null) {
      final uri = Uri.parse(fileUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? fileName;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          fileName ?? 'Image Preview',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () async {
              final uri = Uri.parse(imageUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const CircularProgressIndicator(
              color: Colors.white,
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.error,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

// Responsive Grid Preview for multiple files
class FileGridPreview extends StatelessWidget {
  final List<Map<String, dynamic>> files;
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;

  const FileGridPreview({
    super.key,
    required this.files,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.0,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const Center(
        child: Text('No files to display'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final responsiveCrossAxisCount = width < 600 ? 2 : (width < 900 ? 3 : 4);
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: responsiveCrossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            return FilePreview(
              fileUrl: file['file_url'] ?? file['image_url'],
              fileName: file['file_name'] ?? file['title'],
              fileType: file['file_type'],
              showFileName: true,
            );
          },
        );
      },
    );
  }
}

// List Preview for files
class FileListPreview extends StatelessWidget {
  final List<Map<String, dynamic>> files;
  final Function(Map<String, dynamic>)? onTap;
  final Function(Map<String, dynamic>)? onDelete;

  const FileListPreview({
    super.key,
    required this.files,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No files to display'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: SizedBox(
              width: 60,
              height: 60,
              child: FilePreview(
                fileUrl: file['file_url'] ?? file['image_url'],
                fileName: file['file_name'] ?? file['title'],
                fileType: file['file_type'],
                enableFullScreen: false,
              ),
            ),
            title: Text(
              file['file_name'] ?? file['title'] ?? 'Untitled',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _formatFileSize(file['file_size']) ?? 
              file['category'] ?? 
              file['scan_type'] ?? 
              'File',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: onDelete != null
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onDelete!(file),
                  )
                : const Icon(Icons.chevron_right),
            onTap: onTap != null ? () => onTap!(file) : null,
          ),
        );
      },
    );
  }

  String? _formatFileSize(dynamic size) {
    if (size == null) return null;
    final bytes = size is int ? size : int.tryParse(size.toString());
    if (bytes == null) return null;
    
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
