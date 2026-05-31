# CareSync - Healthcare Management System

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white" alt="iOS">
</div>

## 📋 Overview

CareSync is a comprehensive healthcare management application built with Flutter, designed to streamline healthcare operations for patients, doctors, and administrators. The app provides a unified platform for managing appointments, medication tracking, family health records, and healthcare analytics.

## ✨ Key Features

### 🔐 Authentication & User Management
- **Multi-role Authentication**: Support for Patient, Doctor, and Admin roles
- **Firebase Authentication**: Secure email/password authentication
- **Social Login**: Google and Facebook integration
- **Persistent Sessions**: Automatic login state management
- **Profile Management**: Complete user profile with health information

### 📅 Appointment Management
- **Smart Scheduling**: Interactive calendar with date/time selection
- **Multi-user Support**: Book appointments for family members
- **Doctor Selection**: Choose from available specialists
- **Symptom Tracking**: Record symptoms and medical concerns
- **Status Tracking**: Real-time appointment status updates
- **Offline Support**: Local storage for offline functionality

### 💊 Medication & Health Tracking
- **Medication Reminders**: Customizable alarm system
- **Dosage Tracking**: Track medication intake and schedules
- **Health Reports**: Generate and manage medical reports
- **Family Health Records**: Manage health data for family members
- **Medical History**: Comprehensive health timeline

### 🏥 Healthcare Services
- **Hospital Directory**: Find nearby healthcare facilities
- **Doctor Consultation**: Virtual consultation platform
- **AI Health Assistant**: Groq AI-powered health chatbot
- **OCR Document Processing**: Extract data from medical documents
- **Report Generation**: Automated health report creation
- **Quick Actions**: Upload files, scan documents, generate QR codes, share profiles
- **File Preview System**: Responsive preview for images, PDFs, and documents

### 📊 Analytics & Insights
- **Health Analytics**: Personal health insights and trends
- **Activity Tracking**: Monitor user engagement and health activities
- **Dashboard**: Comprehensive overview of health metrics
- **Data Visualization**: Charts and graphs for health data

### 🔔 Communication & Notifications
- **Real-time Notifications**: Instant updates and reminders
- **Message System**: Secure communication between users
- **Push Notifications**: Cross-platform notification support
- **Notification History**: Track all communications

## 🏗️ Technical Architecture

### Frontend (Flutter)
```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   └── data_models.dart
├── screens/                     # UI screens (25+ screens)
│   ├── auth/                    # Authentication screens
│   ├── dashboard/               # Main dashboard
│   ├── appointments/            # Appointment management
│   ├── health/                  # Health tracking
│   └── admin/                   # Admin panel
├── services/                    # Business logic (28+ services)
│   ├── firebase_service.dart    # Firebase integration
│   ├── auth_service.dart        # Authentication
│   ├── notification_service.dart # Notifications
│   ├── appointment_service.dart  # Appointments
│   ├── groq_service.dart        # AI integration
│   ├── groq_ocr_service.dart    # OCR processing
│   ├── cloudinary_service.dart  # File storage
│   └── quick_actions_service.dart # Quick actions
├── widgets/                     # Reusable components
│   ├── custom_bottom_navbar.dart
│   ├── tracked_button.dart
│   ├── file_preview.dart        # File preview system
│   └── responsive_layout.dart
└── utils/                       # Utility functions
    └── platform_helper.dart
```

### Backend Services
- **Firebase Firestore**: Real-time database
- **Firebase Authentication**: User management
- **Firebase Storage**: File storage
- **Cloudinary**: Media management and optimization
- **Groq AI**: Natural language processing and OCR
- **Cached Network Images**: Image caching and optimization

### Cross-Platform Support
- ✅ **Android**: Native Android support
- ✅ **iOS**: Native iOS support  
- ✅ **Web**: Progressive Web App
- ✅ **Windows**: Desktop application
- ✅ **macOS**: Desktop application
- ⚠️ **Linux**: Partial support

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.8.1)
- Dart SDK
- Firebase project setup
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/caresync.git
   cd caresync
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Configuration**
   
   Create a `.env` file in the root directory:
   ```env
   # Firebase Configuration
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_WEB_API_KEY=your-api-key
   FIREBASE_AUTH_DOMAIN=your-auth-domain
   FIREBASE_STORAGE_BUCKET=your-storage-bucket
   
   # Cloudinary Configuration
   CLOUDINARY_CLOUD_NAME=your-cloud-name
   CLOUDINARY_API_KEY=your-api-key
   CLOUDINARY_API_SECRET=your-api-secret
   CLOUDINARY_UPLOAD_PRESET=patient_upload
   CLOUDINARY_FOLDER=finalapp/patients
   
   # Groq AI Configuration
   GROQ_API_KEY=your-groq-api-key
   GROQ_MODEL=llama-3.3-70b-versatile
   ```

4. **Firebase Setup**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Login to Firebase
   firebase login
   
   # Initialize Firebase in your project
   firebase init
   ```

5. **Run the application**
   ```bash
   # For development
   flutter run
   
   # For specific platform
   flutter run -d chrome    # Web
   flutter run -d android   # Android
   flutter run -d ios       # iOS
   ```

## 📱 App Screens & Navigation

### Main Navigation
- **Home Dashboard**: Welcome screen with quick actions
- **Hospitals**: Healthcare facility directory
- **Multi Options**: Feature access hub
- **Calendar**: Appointment and event calendar
- **Analytics**: Health insights and reports
- **AI Chatbot**: Health assistant
- **Profile**: User settings and information

### Feature Screens
- **Appointment Management**: Create, view, and manage appointments
- **Medication Tracker**: Set reminders and track medication with prescription previews
- **Family Records**: Manage family member health data
- **Reports**: Generate and view health reports
- **Notifications**: Message center and alerts
- **Admin Panel**: System administration (admin users)
- **Quick Actions**: Upload files, scan documents, generate QR codes, share profiles
- **File Preview**: View images, PDFs, and documents with zoom and full-screen support

## 🔧 Configuration

### Firebase Configuration
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication, Firestore, and Storage
3. Download configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
4. Update Firebase rules in `firestore.rules`

### Cloudinary Setup
1. Create account at [Cloudinary](https://cloudinary.com)
2. Get API credentials from dashboard
3. Configure upload presets for file handling
4. Set folder structure for organized storage

### Groq AI Integration
1. Get API key from [Groq Console](https://console.groq.com)
2. Configure for OCR and chatbot features
3. Select appropriate model (llama-3.3-70b-versatile recommended)

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Generate test coverage
flutter test --coverage
```

## 📦 Build & Deployment
flutter pub get
flutter analyze
flutter run



### Development Guidelines
- Follow Flutter/Dart style guidelines
- Ensure cross-platform compatibility



## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Cloudinary for media management
- Groq AI for language model integration
- Open source community for various packages

## 📚 Additional Documentation

- [Quick Actions Fix Guide](QUICK_ACTIONS_FIX.md) - Quick actions troubleshooting
- [Testing Guide](TESTING_GUIDE.md) - Feature testing instructions
- [File Preview System](FILE_PREVIEW_SYSTEM.md) - File preview documentation
- [File Preview Quick Reference](FILE_PREVIEW_QUICK_REF.md) - Quick reference guide
- [Implementation Summary](FILE_PREVIEW_IMPLEMENTATION.md) - Implementation details

## Try Once Android APK APP
Download Link: <a href='https://drive.google.com/file/d/1oDJfwLC75VKHZJBbTPPKSnp_DnnfJfH-/view?usp=sharing'> CareSync </a>


---

<div align="center">
<h1>Team Lucky-TechDaku</h1>
  <p>Made with ❤️ for better healthcare management</p>
  <p>© 2025 CareSync. All rights reserved.</p>
</div>
