// lib/models/AIService/ai_service.dart

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/project_model.dart';

class AIService {
  late final GenerativeModel _model;

  AIService() {
    // ⚠️ 记得换成你的真实 Key, 这里暂时留空，运行时环境会注入
    const apiKey = "AIzaSyBxvDeDdjl63lRG8sEYeElG6V2e_fMOA8E";

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  Future<Project> generateProjectDraft(String resources) async {
    final prompt = '''
      You are a rural development expert in Malaysia (Kampung context). A village leader has these initial resources: "$resources".
      
      Generate a comprehensive project plan in JSON structure based on these resources.
      
      RULES:
      1. "starting_resources": Must include the user's input ("$resources") AND add other logical starting materials needed (e.g., if user inputs "land", you add "seeds", "hoes", "fertilizer").
      2. "address": Generate a realistic sounding Malaysian Kampung address (e.g., "Kampung Baru, Lot 123...").
      3. "incentive": Instead of monetary salary, provide specific incentives for each milestone (e.g., "50 points", "Bag of Harvest", "Community Credit").
      4. "milestones": Include a "description" field explaining what the participant needs to do in detail.
      
      JSON Format:
      {
        "project_title": "String",
        "description": "String (Short summary)",
        "timeline": "String (e.g. 3-4 months)",
        "required_skills": ["String", "String"],
        "participant_range": "String (e.g. 5-8 participants)",
        "starting_resources": ["String", "String"],
        "address": "String",
        "milestones": [
          {
            "phase_name": "Day 1",
            "task_name": "Clear Land",
            "description": "Clear weeds and rocks from the designated 2-acre plot to prepare for planting.",
            "verification_type": "photo",
            "incentive": "RM50 + Lunch"
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