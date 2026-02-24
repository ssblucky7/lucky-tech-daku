import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:finalapp/services/reports_service.dart';
import 'package:finalapp/models/data_models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finalapp/widgets/tracked_screen.dart';
import 'package:finalapp/widgets/tracked_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Report> _medicalReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportsData();
  }

  Future<void> _loadReportsData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final reports = await ReportsService.getReports();
      
      setState(() {
        _medicalReports = reports;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading reports: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TrackedScreen(
      screenName: 'reports_screen',
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Medical Reports'),
          actions: [
            TrackedIconButton(
              buttonName: 'search_reports',
              screenName: 'reports_screen',
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchDialog(),
            ),
            TrackedIconButton(
              buttonName: 'filter_reports',
              screenName: 'reports_screen',
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(context),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadReportsData,
                child: _buildReportsList(_medicalReports),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showUploadReportDialog(context),
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildReportsList(List<Report> reports) {
    if (reports.isEmpty) {
      return _buildEmptyState('No medical reports available', Icons.description);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        final formattedDate = DateFormat('MMM dd, yyyy').format(report.date);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        report.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        report.category,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          report.patient,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.medical_services, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(report.doctor),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(formattedDate),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Summary:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(report.summary),
                    const SizedBox(height: 12),
                    Text(
                      'Recommendations:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(report.recommendations),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PopupMenuButton<String>(
                      enabled: report.attachments > 0 && report.fileUrl != null,
                      child: TextButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: Text('${report.attachments} Attachments'),
                        style: TextButton.styleFrom(
                          foregroundColor: report.attachments > 0 && report.fileUrl != null
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'view':
                            _showDocumentViewer(context, report);
                            break;
                          case 'download':
                            _downloadAttachment(report);
                            break;
                          case 'share':
                            _shareAttachment(report);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 16),
                              SizedBox(width: 8),
                              Text('View'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'download',
                          child: Row(
                            children: [
                              Icon(Icons.download, size: 16),
                              SizedBox(width: 8),
                              Text('Download'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 16),
                              SizedBox(width: 8),
                              Text('Share'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => _shareReport(report),
                          color: Colors.blue,
                          tooltip: 'Share',
                        ),
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => _downloadReport(report),
                          color: Colors.blue,
                          tooltip: 'Download',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteReport(report.id!),
                          color: Colors.red,
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TrackedButton(
            buttonName: 'upload_first_report',
            screenName: 'reports_screen',
            onPressed: () => _showUploadReportDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add),
                SizedBox(width: 8),
                Text('Upload Document'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Reports'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TrackedButton(
            buttonName: 'search_submit',
            screenName: 'search_dialog',
            onPressed: () async {
              Navigator.pop(context);
              if (searchController.text.isNotEmpty) {
                final results = await ReportsService.searchReports(searchController.text);
                setState(() {
                  _medicalReports = results;
                });
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Reports'),
              onTap: () {
                Navigator.pop(context);
                _loadReportsData();
              },
            ),
            ListTile(
              title: const Text('General'),
              onTap: () async {
                Navigator.pop(context);
                final results = await ReportsService.getReportsByCategory('General');
                setState(() {
                  _medicalReports = results;
                });
              },
            ),
            ListTile(
              title: const Text('Laboratory'),
              onTap: () async {
                Navigator.pop(context);
                final results = await ReportsService.getReportsByCategory('Laboratory');
                setState(() {
                  _medicalReports = results;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadReportDialog(BuildContext context) {
    final titleController = TextEditingController();
    final summaryController = TextEditingController();
    final recommendationsController = TextEditingController();
    String? selectedPatient;
    String? selectedCategory = 'General';
    PlatformFile? selectedFile;
    
    final List<String> patients = ['John Doe', 'Jane Smith', 'Mike Doe', 'Sarah Doe'];
    final List<String> categories = ['General', 'Laboratory', 'Radiology', 'Cardiology', 'Neurology'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Upload Medical Report'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Report Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Patient',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: selectedPatient,
                  onChanged: (value) => selectedPatient = value,
                  items: patients.map((patient) {
                    return DropdownMenuItem<String>(
                      value: patient,
                      child: Text(patient),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: selectedCategory,
                  onChanged: (value) => selectedCategory = value,
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: summaryController,
                  decoration: const InputDecoration(
                    labelText: 'Summary',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: recommendationsController,
                  decoration: const InputDecoration(
                    labelText: 'Recommendations',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        selectedFile != null ? Icons.check_circle : Icons.upload_file,
                        size: 48,
                        color: selectedFile != null ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedFile != null 
                            ? 'File Selected: ${selectedFile!.name}'
                            : 'No file selected',
                        style: TextStyle(
                          color: selectedFile != null ? Colors.green : Colors.grey[600],
                          fontWeight: selectedFile != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                              allowMultiple: false,
                            );
                            
                            if (result != null && result.files.isNotEmpty) {
                              setDialogState(() {
                                selectedFile = result.files.first;
                              });
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error selecting file: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Select File (PDF/Image)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
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
              buttonName: 'upload_report',
              screenName: 'upload_dialog',
              onPressed: () async {
                if (titleController.text.isNotEmpty && 
                    selectedPatient != null && 
                    summaryController.text.isNotEmpty) {
                  
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                  
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  
                  try {
                    await ReportsService.createReport(
                      title: titleController.text,
                      patient: selectedPatient!,
                      doctor: 'Current Doctor',
                      category: selectedCategory ?? 'General',
                      summary: summaryController.text,
                      recommendations: recommendationsController.text.isEmpty 
                          ? 'No specific recommendations' 
                          : recommendationsController.text,
                      file: selectedFile,
                    );
                    
                    await _loadReportsData();
                    
                    navigator.pop(); // Close loading
                    navigator.pop(); // Close dialog
                    
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Report uploaded successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    navigator.pop(); // Close loading
                    
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to upload report: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentViewer(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report.fileName ?? 'Document',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _buildDocumentPreview(report),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentPreview(Report report) {
    final fileUrl = report.fileUrl;
    final fileName = report.fileName;
    
    if (fileUrl == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Document not available'),
          ],
        ),
      );
    }
    
    final isImage = fileName != null && 
        (fileName.toLowerCase().endsWith('.jpg') ||
         fileName.toLowerCase().endsWith('.jpeg') ||
         fileName.toLowerCase().endsWith('.png'));
    
    if (isImage) {
      return Center(
        child: Image.network(
          fileUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Failed to load image'),
              ],
            );
          },
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              fileName ?? 'PDF Document',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'PDF Preview not available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _deleteReport(String reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TrackedButton(
            buttonName: 'confirm_delete',
            screenName: 'delete_dialog',
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      
      try {
        await ReportsService.deleteReport(reportId);
        await _loadReportsData();
        
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Report deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error deleting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareReport(Report report) async {
    try {
      final reportText = '''
Medical Report: ${report.title}
Patient: ${report.patient}
Doctor: ${report.doctor}
Date: ${DateFormat('MMM dd, yyyy').format(report.date)}
Category: ${report.category}

Summary:
${report.summary}

Recommendations:
${report.recommendations}
''';

      if (report.fileUrl != null) {
        await Share.share(
          '$reportText\nDocument: ${report.fileUrl}',
          subject: 'Medical Report - ${report.title}',
        );
      } else {
        await Share.share(
          reportText,
          subject: 'Medical Report - ${report.title}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadReport(Report report) async {
    try {
      if (report.fileUrl != null) {
        final uri = Uri.parse(report.fileUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch ${report.fileUrl}';
        }
      } else {
        // Copy report text to clipboard if no file
        final reportText = '''
Medical Report: ${report.title}
Patient: ${report.patient}
Doctor: ${report.doctor}
Date: ${DateFormat('MMM dd, yyyy').format(report.date)}
Category: ${report.category}

Summary:
${report.summary}

Recommendations:
${report.recommendations}
''';
        
        await Clipboard.setData(ClipboardData(text: reportText));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report copied to clipboard'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadAttachment(Report report) async {
    if (report.fileUrl != null) {
      try {
        final uri = Uri.parse(report.fileUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not download attachment';
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error downloading attachment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _shareAttachment(Report report) async {
    if (report.fileUrl != null) {
      try {
        await Share.share(
          report.fileUrl!,
          subject: 'Medical Report Attachment - ${report.fileName ?? report.title}',
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sharing attachment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}