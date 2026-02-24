# File Preview - Quick Reference

## 🚀 Quick Start

### 1. Single File Preview
```dart
FilePreview(
  fileUrl: 'https://cloudinary.com/image.jpg',
  fileName: 'document.pdf',
  fileType: 'pdf',
  width: 200,
  height: 200,
)
```

### 2. Grid of Files
```dart
FileGridPreview(
  files: [
    {'file_url': 'https://...', 'file_name': 'doc1.pdf'},
    {'file_url': 'https://...', 'file_name': 'doc2.jpg'},
  ],
)
```

### 3. List with Actions
```dart
FileListPreview(
  files: filesList,
  onTap: (file) => print('Tapped: ${file['file_name']}'),
  onDelete: (file) => deleteFile(file['id']),
)
```

## 📱 Responsive Breakpoints

| Screen Size | Columns | Use Case |
|-------------|---------|----------|
| < 600px | 2 | Mobile phones |
| 600-900px | 3 | Tablets |
| > 900px | 4 | Desktop/Web |

## 🎨 File Type Colors

```
PDF       → Red
Images    → Blue
Word      → Dark Blue
Excel     → Dark Green
Archives  → Orange
Video     → Purple
Audio     → Pink
Other     → Grey
```

## 🔧 Common Patterns

### Pattern 1: Dialog with Preview
```dart
showDialog(
  context: context,
  builder: (context) => Dialog(
    child: Column(
      children: [
        AppBar(title: Text('Preview')),
        Expanded(
          child: FilePreview(
            fileUrl: url,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ],
    ),
  ),
);
```

### Pattern 2: Card with Thumbnail
```dart
Card(
  child: Row(
    children: [
      SizedBox(
        width: 60,
        height: 60,
        child: FilePreview(
          fileUrl: url,
          enableFullScreen: false,
        ),
      ),
      Expanded(child: Text(fileName)),
    ],
  ),
)
```

### Pattern 3: Full Screen on Tap
```dart
FilePreview(
  fileUrl: url,
  enableFullScreen: true,  // Default
)
// Tap image → Opens full screen viewer
// Tap PDF → Opens in external app
```

## ✅ Integration Checklist

- [ ] Import: `import 'package:finalapp/widgets/file_preview.dart';`
- [ ] Replace Image.network with FilePreview
- [ ] Add file_url or image_url to data
- [ ] Add file_name and file_type if available
- [ ] Test on mobile, tablet, desktop
- [ ] Verify caching works (fast reload)
- [ ] Check error states
- [ ] Test full-screen viewer

## 🐛 Troubleshooting

**Images not loading?**
- Check file_url is valid HTTPS URL
- Verify Cloudinary credentials
- Check network connection

**Full screen not working?**
- Ensure `enableFullScreen: true`
- Check if fileUrl is not null
- Verify image type detection

**Grid not responsive?**
- Wrap in LayoutBuilder or use default
- Check constraints are not too tight
- Verify parent widget allows expansion

## 📦 File Data Format

```dart
{
  'file_url': 'https://...',      // Required (or 'image_url')
  'file_name': 'document.pdf',    // Optional but recommended
  'file_type': 'pdf',             // Optional (auto-detected)
  'file_size': 1024000,           // Optional (for display)
  'category': 'Medical',          // Optional
  'title': 'Report',              // Alternative to file_name
}
```

## 🎯 Where to Use

✅ **Multi Options Screen** - Upload previews
✅ **Medication Tracker** - Prescription images
✅ **Reports Screen** - Medical reports
✅ **Doctor Consultation** - Profile images
✅ **Family Records** - Documents
✅ **Appointments** - Attachments
✅ **Health Records** - Scans

## 💡 Pro Tips

1. **Always provide fileName** for better UX
2. **Use fit: BoxFit.contain** for documents
3. **Use fit: BoxFit.cover** for thumbnails
4. **Enable caching** (automatic with cached_network_image)
5. **Test with slow network** to see loading states
6. **Provide file_type** for accurate icons
7. **Use FileListPreview** for better performance with many files

## 🔗 Related Files

- `lib/widgets/file_preview.dart` - Main widget
- `lib/screens/multi_options_screen.dart` - Example usage
- `lib/screens/medication_tracker_screen.dart` - Example usage
- `FILE_PREVIEW_SYSTEM.md` - Full documentation

---

**Ready to use!** Just import and start previewing files! 🎉
