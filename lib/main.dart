import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:finalapp/services/firebase_service.dart';
import 'package:finalapp/services/cloudinary_service.dart';
import 'package:finalapp/services/media_storage_service.dart';
import 'package:finalapp/services/activity_tracking_service.dart';
import 'package:finalapp/services/database_init_service.dart';
import 'package:finalapp/services/data_sync_service.dart';
import 'package:finalapp/utils/platform_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:finalapp/firebase_options.dart';
import 'package:finalapp/widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize Firebase first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize services with error handling
  try {
    await FirebaseService.initialize();
    await CloudinaryService.initialize();
    await MediaStorageService.initialize();
    
    // Initialize database collections
    await DatabaseInitService.initializeCollections();
    
    // Check connectivity and sync offline data
    await DataSyncService.checkConnectivity();
  } catch (e) {
    if (kDebugMode) debugPrint('Service initialization error: $e');
    // Continue app startup even if some services fail
  }
  
  // Log app startup
  if (FirebaseService.isUserLoggedIn()) {
    await ActivityTrackingService.trackActivity(
      activityType: ActivityTrackingService.appStart,
      description: 'Application started',
      metadata: {
        'version': dotenv.env['APP_VERSION'],
        'environment': dotenv.env['ENVIRONMENT'],
        'platform': kIsWeb ? 'web' : PlatformHelper.getPlatformName(),
      },
    );
  }
  
  if (kDebugMode) {
    debugPrint('All services initialized successfully');
  }
  
  // Platform-specific configurations
  if (PlatformHelper.isMobile) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
  
  // Enable web debugging in debug mode
  if (kDebugMode && PlatformHelper.isWeb) {
    debugPrint('Running CareSync on Web Platform');
  }
  
  runApp(const CareSync());
}

class CareSync extends StatelessWidget {
  const CareSync({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        visualDensity: PlatformHelper.isDesktop 
            ? VisualDensity.comfortable 
            : VisualDensity.compact,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 8,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: PlatformHelper.isDesktop ? 16 : 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: PlatformHelper.isDesktop ? 32 : 24,
              vertical: PlatformHelper.isDesktop ? 16 : 12,
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}


