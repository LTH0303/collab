import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'models/AIService/ai_service.dart';
import 'models/DatabaseService/database_service.dart';
import 'models/ProjectRepository/project_repository.dart';
import 'models/ProjectRepository/application_repository.dart'; // Correct path

import 'ViewModel/AuthViewModel/auth_view_model.dart';
import 'ViewModel/PlannerViewModel/planner_view_model.dart';
import 'ViewModel/JobViewModule/job_view_model.dart';
import 'ViewModel/ApplicationViewModel/application_view_model.dart';
import 'ViewModel/ProjectDetailsViewModel/project_details_view_model.dart';

import 'View/Authentication/login_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final aiService = AIService();
  final dbService = DatabaseService();
  final projectRepo = ProjectRepository(aiService, dbService);
  final appRepo = ApplicationRepository(dbService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlannerViewModel(projectRepo)),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => JobViewModel(dbService)),
        ChangeNotifierProvider(create: (_) => ApplicationViewModel(appRepo)),
        ChangeNotifierProvider(create: (_) => ProjectDetailsViewModel()),
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
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const LoginPage(),
    );
  }
}