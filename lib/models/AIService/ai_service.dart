// lib/models/AI Service/ai_service.dart

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/project_model.dart'; // 引用刚才建的 Model

class AIService {
  late final GenerativeModel _model;

  AIService() {
    // ⚠️ 记得换成你的真实 Key
    const apiKey = 'AIzaSyA7S-HCq7hwe1hZVc9czbVr3GAdXAXvOic';

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      // 关键：强制 AI 输出 JSON 格式
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  Future<Project> generateProjectDraft(String resources) async {
    // 专门为你定制的 Prompt，包含“无总薪资”和“里程碑奖励”逻辑
    final prompt = '''
      You are a rural development expert. A village leader has these resources: "$resources".
      Generate a project plan in JSON structure.
      
      RULES:
      1. NO total monetary compensation field.
      2. Instead, provide specific "incentive" for each milestone (e.g., "50 points", "Free fertilizer", "Harvest Share").
      3. For "verification_type", use ONLY "photo" or "leader".
      4. "phase_name" should be like "Day 1", "Week 2".
      
      JSON Format:
      {
        "project_title": "String",
        "timeline": "String (e.g. 3-4 months)",
        "required_skills": ["String", "String"],
        "participant_range": "String (e.g. 5-8 participants)",
        "description": "String",
        "milestones": [
          {
            "phase_name": "Day 1",
            "task_name": "Clear Land",
            "verification_type": "photo",
            "incentive": "100 Points"
          }
        ]
      }
    ''';

    final response = await _model.generateContent([Content.text(prompt)]);

    if (response.text == null) throw Exception("AI returned empty response");

    try {
      final jsonMap = jsonDecode(response.text!);
      return Project.fromJson(jsonMap);
    } catch (e) {
      throw Exception("Failed to parse AI JSON: $e");
    }
  }
}