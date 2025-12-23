// lib/models/AIService/ai_service.dart

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../ProjectRepository/project_model.dart';

class AIService {
  late final GenerativeModel _model;

  AIService() {
    // Ideally use environment variables for keys
    const apiKey = "AIzaSyB8Ufbx3qf4wTHQifc0gp2mBvguAC9LEj0";
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  Future<Project> generateProjectDraft(String resources, String budgetAmount) async {
    final prompt = '''
      You are a senior rural development consultant in Malaysia.
      
      INPUTS:
      1. Resources: "$resources"
      2. Total Grant: RM $budgetAmount
      
      TASK:
      Generate a detailed, professional project plan JSON for a village rejuvenation project.
      
      STRICT REQUIREMENTS:
      1. Milestones: Generate exactly 6 to 8 milestones. 
         - Cover phases: Planning, Site Prep, Infrastructure, Planting/Stocking, Maintenance, and Harvest.
      2. Descriptions: Must be detailed (2-3 sentences). Explain *what* to do and *why*.
      3. Verification: Be specific. Instead of "Photo", use "Photo of cleared land", "Receipt of seeds", "Water quality report".
      4. Address: Generate a realistic Malaysian Kampung address (e.g., Lot 123, Jalan Mawar, Kampung...).
      5. Budget: Distribute the exact RM $budgetAmount across milestones based on realistic costs.
      
      RESPONSE FORMAT (JSON ONLY):
      {
        "project_title": "Professional Title (e.g. Integrated Organic Chill Farm)",
        "description": "A comprehensive summary of the project goals, impact on the village, and sustainability plan.",
        "timeline": "e.g. 6 Months",
        "total_budget": "$budgetAmount",
        "required_skills": ["Skill 1", "Skill 2", "Skill 3", "Skill 4"],
        "participant_range": "e.g. 5-8 Youth",
        "starting_resources": ["Resource 1", "Resource 2"],
        "address": "Full Address String",
        "milestones": [
          {
            "phase_name": "Phase 1: Preparation",
            "task_name": "Site Clearing & Mapping",
            "description": "Clear the designated 2-acre plot of weeds and debris. Map out the planting zones and irrigation paths.",
            "verification_type": "Photo of cleared site & drawn map",
            "incentive": "RM 50 + Lunch",
            "allocated_budget": "300" 
          }
        ]
      }
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text == null) throw Exception("AI returned empty response");

      // Clean up potential markdown formatting if Gemini adds it
      String cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '');

      final jsonMap = jsonDecode(cleanJson);
      return Project.fromJson(jsonMap);
    } catch (e) {
      print("AI Error: $e");
      throw Exception("AI Service Error: $e");
    }
  }
}