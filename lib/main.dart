import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// --- 1. Imports ---
import 'models/AIService/ai_service.dart';
import 'models/DatabaseService/database_service.dart';
import 'models/ProjectRepository/project_repository.dart';
import 'ViewModel/AuthViewModel/auth_view_model.dart';
import 'ViewModel/PlannerViewModel/planner_view_model.dart';
import 'ViewModel/JobViewModule/job_view_model.dart';
import 'View/Authentication/login_page.dart';

// Views
import 'View/LeaderUserInterface/leader_main_layout.dart'; // Keep this if referenced elsewhere
import 'View/Authentication/login_page.dart'; // Added Login Page

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Initialize Service Layer (Model)
  final aiService = AIService();
  final dbService = DatabaseService();

  // 3. Initialize Repository Layer
  final projectRepo = ProjectRepository(aiService, dbService);

  runApp(
    MultiProvider(
      providers: [
        // Inject Village Leader ViewModel
        ChangeNotifierProvider(create: (_) => PlannerViewModel(projectRepo)),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        // Inject Youth Participant/JobBoard ViewModel
        ChangeNotifierProvider(create: (_) => JobViewModel(dbService)),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Village Advisor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      // Point home to LoginPage instead of LeaderMainLayout
      home: const LoginPage(),
    );
  }
}