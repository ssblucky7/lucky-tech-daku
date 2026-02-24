# Responsive File Preview System

## Overview
A comprehensive, responsive file preview system for the CareSync app that handles images, PDFs, documents, and other file types with caching, full-screen viewing, and adaptive layouts.

## Features

### ✅ File Type Support
- **Images**: JPG, JPEG, PNG, GIF, WEBP, BMP
- **Documents**: PDF, DOC, DOCX, XLS, XLSX
- **Archives**: ZIP, RAR
- **Media**: MP4, AVI, MOV, MP3, WAV
- **Generic**: Any other file type with appropriate icon

### ✅ Preview Modes
1. **Single File Preview** - Display individual files with optional full-screen
2. **Grid Preview** - Responsive grid layout for multiple files
3. **List Preview** - List view with thumbnails and file details

### ✅ Responsive Design
- Adapts to screen size (mobile, tablet, desktop)
- Grid columns adjust automatically:
  - Mobile (< 600px): 2 columns
  - Tablet (600-900px): 3 columns
  - Desktop (> 900px): 4 columns

### ✅ Performance
- **Cached Network Images** - Automatic caching for faster loading
- **Lazy Loading** - Images load on demand
- **Placeholder Support** - Loading indicators while fetching
- **Error Handling** - Graceful fallback for failed loads

## Components

### 1. FilePreview Widget

Single file preview with full-screen capability.

```dart
FilePreview(
  fileUrl: 'https://cloudinary.com/image.jpg',
  fileName: 'prescription.jpg',
  fileType: 'jpg',
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  showFileName: true,
  enableFullScreen: true,
)
```

**Parameters:**
- `fileUrl` (String?) - URL of the file to preview
- `fileName` (String?) - Display name of the file
- `fileType` (String?) - File extension (jpg, pdf, etc.)
- `width` (double?) - Width of preview container
- `height` (double?) - Height of preview container
- `fit` (BoxFit) - How image should fit (default: BoxFit.cover)
- `showFileName` (bool) - Show filename below preview (default: false)
- `enableFullScreen` (bool) - Enable tap to open full screen (default: true)

**Behavior:**
- Images: Shows cached network image with loading/error states
- PDFs: Shows PDF icon with filename
- Other files: Shows appropriate icon with color coding
- Tap to open full screen (images) or external app (other files)

### 2. FullScreenImageViewer

Full-screen image viewer with zoom and pan.

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => FullScreenImageViewer(
      imageUrl: 'https://cloudinary.com/image.jpg',
      fileName: 'prescription.jpg',
    ),
  ),
);
```

**Features:**
- Pinch to zoom (0.5x to 4x)
- Pan to navigate zoomed image
- Black background for better viewing
- Open in external app button
- Close button to return

### 3. FileGridPreview Widget

Responsive grid layout for multiple files.

```dart
FileGridPreview(
  files: [
    {
      'file_url': 'https://...',
      'file_name': 'document.pdf',
      'file_type': 'pdf',
    },
    // ... more files
  ],
  crossAxisCount: 3,  // Optional, auto-responsive
  childAspectRatio: 1.0,
  spacing: 8.0,
)
```

**Parameters:**
- `files` (List<Map<String, dynamic>>) - List of file data
- `crossAxisCount` (int) - Number of columns (default: auto-responsive)
- `childAspectRatio` (double) - Width/height ratio (default: 1.0)
- `spacing` (double) - Space between items (default: 8.0)

**File Data Structure:**
```dart
{
  'file_url': 'https://...',      // or 'image_url'
  'file_name': 'document.pdf',    // or 'title'
  'file_type': 'pdf',
  'file_size': 1024000,           // Optional
  'category': 'Medical Report',   // Optional
}
```

### 4. FileListPreview Widget

List view with thumbnails and actions.

```dart
FileListPreview(
  files: filesList,
  onTap: (file) {
    // Handle file tap
    print('Tapped: ${file['file_name']}');
  },
  onDelete: (file) {
    // Handle delete
    deleteFile(file['id']);
  },
)
```

**Parameters:**
- `files` (List<Map<String, dynamic>>) - List of file data
- `onTap` (Function?) - Callback when file is tapped
- `onDelete` (Function?) - Callback for delete action

**Features:**
- 60x60 thumbnail preview
- File name and size/category display
- Delete button (if onDelete provided)
- Chevron icon (if onTap provided)
- Formatted file sizes (B, KB, MB)

## Usage Examples

### Example 1: Multi Options Screen (Uploads List)

```dart
void _showUploadsList() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Uploads'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: FileListPreview(
          files: _uploads,
          onTap: (file) => _showFileDetail(file),
          onDelete: (file) => _deleteUpload(file['id']),
        ),
      ),
    ),
  );
}
```

### Example 2: Medication Prescription Preview

```dart
void _showPrescriptionImage(Map<String, dynamic> medication) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Column(
          children: [
            AppBar(
              title: Text('Prescription - ${medication['name']}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: FilePreview(
                fileUrl: medication['prescription_image_url'],
                fileName: 'Prescription',
                fileType: 'jpg',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### Example 3: File Detail View

```dart
void _showFileDetail(Map<String, dynamic> file) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            AppBar(
              title: Text(file['file_name'] ?? 'File Details'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    FilePreview(
                      fileUrl: file['file_url'],
                      fileName: file['file_name'],
                      fileType: file['file_type'],
                      height: 300,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 16),
                    // File details...
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### Example 4: Grid of Medical Reports

```dart
Widget _buildReportsGrid() {
  return FileGridPreview(
    files: _medicalReports,
    crossAxisCount: 3,
    childAspectRatio: 0.8,
    spacing: 12.0,
  );
}
```

## File Type Icons & Colors

| File Type | Icon | Color |
|-----------|------|-------|
| PDF | picture_as_pdf | Red |
| Image | image | Blue |
| Word | description | Blue (Dark) |
| Excel | table_chart | Green (Dark) |
| Archive | folder_zip | Orange |
| Video | video_file | Purple |
| Audio | audio_file | Pink |
| Generic | insert_drive_file | Grey |

## Integration Points

### Current Integrations
1. ✅ **Multi Options Screen** - Upload file previews and lists
2. ✅ **Medication Tracker** - Prescription image previews
3. 🔄 **Reports Screen** - Medical report previews (ready to integrate)
4. 🔄 **Doctor Consultation** - Profile image previews (ready to integrate)
5. 🔄 **Family Records** - Document previews (ready to integrate)

### How to Integrate

1. **Import the widget:**
```dart
import 'package:finalapp/widgets/file_preview.dart';
```

2. **Replace existing Image.network with FilePreview:**
```dart
// Before
Image.network(
  fileUrl,
  fit: BoxFit.cover,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return const CircularProgressIndicator();
  },
  errorBuilder: (context, error, stackTrace) {
    return const Icon(Icons.error);
  },
)

// After
FilePreview(
  fileUrl: fileUrl,
  fileName: fileName,
  fileType: fileType,
  fit: BoxFit.cover,
)
```

3. **Use FileListPreview for lists:**
```dart
// Before
ListView.builder(
  itemCount: files.length,
  itemBuilder: (context, index) {
    final file = files[index];
    return ListTile(
      leading: Image.network(file['url']),
      title: Text(file['name']),
      // ...
    );
  },
)

// After
FileListPreview(
  files: files,
  onTap: (file) => _handleFileTap(file),
  onDelete: (file) => _handleDelete(file),
)
```

## Dependencies

```yaml
dependencies:
  cached_network_image: ^3.3.1  # Image caching
  url_launcher: ^6.2.5          # Open files externally
```

## Performance Considerations

### Caching Strategy
- Images are automatically cached by `cached_network_image`
- Cache is persistent across app restarts
- Reduces network usage and improves load times

### Memory Management
- Images are loaded on-demand (lazy loading)
- Cached images are managed by the package
- Large images are automatically scaled

### Network Optimization
- Only visible images are loaded
- Failed loads don't retry indefinitely
- Placeholder shown during loading

## Error Handling

### Image Load Failures
- Shows broken image icon
- Grey background
- No crash or blank screen

### Missing File URLs
- Shows placeholder with "no image" icon
- Graceful degradation

### Network Issues
- Loading indicator while fetching
- Error icon if fetch fails
- Retry on user interaction (tap)

## Accessibility

- All icons have semantic labels
- Images have alt text (filename)
- Tap targets are appropriately sized
- Color contrast meets WCAG standards

## Testing Checklist

- [ ] Image preview loads correctly
- [ ] PDF shows appropriate icon
- [ ] Full-screen viewer works
- [ ] Zoom and pan in full-screen
- [ ] Grid layout is responsive
- [ ] List view shows thumbnails
- [ ] Delete action works
- [ ] Tap action works
- [ ] File sizes format correctly
- [ ] Error states display properly
- [ ] Loading states show
- [ ] Cache works (fast reload)
- [ ] External app opens for PDFs
- [ ] Works on mobile
- [ ] Works on tablet
- [ ] Works on desktop
- [ ] Works on web

## Future Enhancements

- [ ] Video preview with play button
- [ ] Audio player integration
- [ ] PDF inline viewer (web)
- [ ] Download button
- [ ] Share button
- [ ] Multiple file selection
- [ ] Drag and drop upload
- [ ] Image editing (crop, rotate)
- [ ] Thumbnail generation
- [ ] Search within files

## Files Modified

1. `lib/widgets/file_preview.dart` - New widget file
2. `lib/screens/multi_options_screen.dart` - Integrated FileListPreview
3. `lib/screens/medication_tracker_screen.dart` - Integrated FilePreview
4. `pubspec.yaml` - Added cached_network_image dependency

## Summary

The responsive file preview system provides:
- ✅ Unified file preview across the app
- ✅ Automatic caching for performance
- ✅ Responsive layouts for all screen sizes
- ✅ Full-screen viewing with zoom
- ✅ Support for multiple file types
- ✅ Graceful error handling
- ✅ Easy integration with existing code

Ready to use throughout the CareSync application! 🎉
