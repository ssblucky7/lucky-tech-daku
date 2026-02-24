# Autonomous Modular Account System

## Overview
The system provides autonomous, role-based account management with modular architecture for data isolation and feature access control.

## Architecture

### 1. Account Module (`lib/modules/account_module.dart`)
**Purpose**: Core account management with role-based permissions

**Features**:
- User roles: Patient, Doctor, Admin, Guest
- 13 granular permissions
- Automatic account creation
- Role-based access control

**Usage**:
```dart
// Check permission
bool canEdit = await AccountModule.hasPermission(Permission.editProfile);

// Get user role
UserRole role = await AccountModule.getUserRole();

// Update role (admin only)
await AccountModule.updateUserRole(userId, UserRole.doctor);
```

### 2. Data Isolation Module (`lib/modules/data_isolation_module.dart`)
**Purpose**: Automatic user-specific data filtering

**Features**:
- Automatic user_id injection
- Query filtering by user
- Access control on CRUD operations
- Real-time data streams

**Usage**:
```dart
// Add document (auto-adds user_id)
await DataIsolationModule.addDocument('appointments', {
  'date': DateTime.now(),
  'doctor': 'Dr. Smith',
});

// Get user documents
List<Map> docs = await DataIsolationModule.getUserDocuments('appointments');

// Stream user data
Stream<List<Map>> stream = DataIsolationModule.streamUserDocuments('medications');
```

### 3. Session Module (`lib/modules/session_module.dart`)
**Purpose**: Autonomous session management

**Features**:
- Auto-initialization on login
- Session caching
- Session tracking
- Auto-cleanup on logout

**Usage**:
```dart
// Initialize (called automatically)
await SessionModule.initializeSession();

// Get cached data
UserRole? role = SessionModule.getCachedRole();

// Check validity
bool valid = SessionModule.isSessionValid();
```

### 4. Feature Access Module (`lib/modules/feature_access_module.dart`)
**Purpose**: Modular feature access control

**Features**:
- Feature-level permissions
- Dynamic feature discovery
- Permission combinations (AND/OR)

**Usage**:
```dart
// Check feature access
bool canAccess = await FeatureAccessModule.canAccessFeature('admin_panel');

// Get accessible features
List<String> features = await FeatureAccessModule.getAccessibleFeatures();

// Check multiple permissions
bool hasAll = await FeatureAccessModule.hasAllPermissions([
  Permission.viewReports,
  Permission.generateReports,
]);
```

### 5. Protected Route Widget (`lib/widgets/protected_route.dart`)
**Purpose**: UI-level access control

**Usage**:
```dart
ProtectedRoute(
  featureName: 'admin_panel',
  child: AdminPanelScreen(),
  fallback: AccessDeniedScreen(), // Optional
)
```

## Role Permissions Matrix

| Permission | Patient | Doctor | Admin | Guest |
|------------|---------|--------|-------|-------|
| View Profile | ✓ | ✓ | ✓ | ✓ |
| Edit Profile | ✓ | ✓ | ✓ | ✗ |
| View Medical History | ✓ | ✓ | ✓ | ✗ |
| Edit Medical History | ✓ | ✗ | ✓ | ✗ |
| Book Appointment | ✓ | ✗ | ✓ | ✗ |
| View Appointments | ✓ | ✓ | ✓ | ✗ |
| Manage Appointments | ✗ | ✓ | ✓ | ✗ |
| Prescribe Medication | ✗ | ✓ | ✓ | ✗ |
| View Reports | ✓ | ✓ | ✓ | ✗ |
| Generate Reports | ✗ | ✓ | ✓ | ✗ |
| Manage Users | ✗ | ✗ | ✓ | ✗ |
| View Analytics | ✗ | ✓ | ✓ | ✗ |
| Access AI | ✓ | ✓ | ✓ | ✗ |

## Features Mapping

| Feature | Required Permissions |
|---------|---------------------|
| profile | viewProfile, editProfile |
| medical_history | viewMedicalHistory, editMedicalHistory |
| appointments | viewAppointments, bookAppointment |
| medications | viewMedicalHistory |
| reports | viewReports |
| analytics | viewAnalytics |
| ai_chatbot | accessAI |
| admin_panel | manageUsers |

## Integration Examples

### Protect a Screen
```dart
class MedicalHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProtectedRoute(
      featureName: 'medical_history',
      child: Scaffold(
        appBar: AppBar(title: Text('Medical History')),
        body: MedicalHistoryContent(),
      ),
    );
  }
}
```

### Conditional UI Elements
```dart
FutureBuilder<bool>(
  future: AccountModule.hasPermission(Permission.manageUsers),
  builder: (context, snapshot) {
    if (snapshot.data == true) {
      return ElevatedButton(
        onPressed: () => navigateToAdminPanel(),
        child: Text('Admin Panel'),
      );
    }
    return SizedBox.shrink();
  },
)
```

### Data Operations
```dart
// Automatically filtered by user
final appointments = await DataIsolationModule.getUserDocuments(
  'caresync_appointments',
  orderBy: 'date',
  descending: true,
  limit: 10,
);
```

## Benefits

1. **Autonomy**: Self-managing sessions and permissions
2. **Modularity**: Independent, reusable modules
3. **Security**: Automatic data isolation per account
4. **Scalability**: Easy to add new roles/permissions
5. **Maintainability**: Clear separation of concerns
6. **Flexibility**: Fine-grained access control

## Database Collections

### caresync_accounts
```json
{
  "user_id": "string",
  "email": "string",
  "role": "patient|doctor|admin|guest",
  "is_active": true,
  "is_verified": true,
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### caresync_sessions
```json
{
  "user_id": "string",
  "email": "string",
  "role": "string",
  "login_time": "timestamp",
  "device_info": {
    "platform": "web|mobile"
  }
}
```

## Future Enhancements

- Custom role creation
- Permission inheritance
- Time-based access control
- IP-based restrictions
- Multi-factor authentication
- Audit logging
