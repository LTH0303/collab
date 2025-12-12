import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// --- 1. 严格对应你截图的路径 ---
// 注意大小写：models (小写) -> AIService (大写) -> ai_service.dart
import 'models/AIService/ai_service.dart';
import 'models/DatabaseService/database_service.dart';
import 'models/ProjectRepository/project_repository.dart';

// 注意大小写：ViewModel (大写) -> PlannerViewModel (大写)
import 'ViewModel/PlannerViewModel/planner_view_model.dart';
import 'ViewModel/JobViewModule/job_view_model.dart';

// 注意大小写：View (大写) -> LeaderUserInterface (大写)
import 'View/LeaderUserInterface/leader_main_layout.dart';
import 'firebase_options.dart'; // 如果你有这个文件，保留它；如果没有，删掉这行

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  // 如果你生成了 firebase_options.dart，请使用 options: DefaultFirebaseOptions.currentPlatform
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. 初始化服务层 (Model)
  final aiService = AIService();
  final dbService = DatabaseService();

  // 3. 初始化仓库层 (Repository)
  final projectRepo = ProjectRepository(aiService, dbService);

  runApp(
    // 🔴 关键修复：MultiProvider 必须包裹整个 MyApp
    MultiProvider(
      providers: [
        // 注入村长的 ViewModel
        ChangeNotifierProvider(create: (_) => PlannerViewModel(projectRepo)),

        // 注入参与者/JobBoard 的 ViewModel
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
        primarySwatch: Colors.green, // 配合你的绿色主题
        useMaterial3: true,
      ),
      // 指向村长的主界面
      home: LeaderMainLayout(),
    );
  }
}