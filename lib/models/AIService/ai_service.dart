// lib/models/AIService/ai_service.dart

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../ProjectRepository/project_model.dart';

class AIService {
  late final GenerativeModel _model;

  AIService() {
    // Ideally use environment variables for keys
    const apiKey = "-"; // Keep empty as per instructions, injected at runtime
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  Future<Project> generateProjectDraft(String resources, String budgetAmount) async {
    // --- UPDATED PROMPT WITH GUARDRAILS ---
    final prompt = '''
      You are the official AI Project Planner for "Smart Village Advisor", an app dedicated to rural development in Malaysia.
      
      YOUR ROLE:
      Your SOLE purpose is to convert user inputs (Resources & Budget) into a structured JSON project plan. 
      
      STRICT GUARDRAILS (CRITICAL):
      1. DO NOT act as a general chatbot. DO NOT answer general knowledge questions, personal questions, or engage in casual conversation (e.g., "Who are you?", "What is the capital of France?", "Tell me a joke").
      2. IF the input under "Resources" is unrelated to village development, agriculture, or infrastructure (e.g., gibberish, political questions, or random chat), YOU MUST REFUSE TO ANSWER.
      3. INSTEAD of answering the question, you MUST generate a valid JSON "Error Project" with:
         - "project_title": "Invalid Input Detected"
         - "description": "The input provided was not recognized as a valid resource for a village project. Please strictly input available assets like '2 acres of land', '10 youth volunteers', or 'idle tractors'."
         - "total_budget": "0"
         - "milestones": []
         - "required_skills": []
      4. ALWAYS output valid JSON. Never output plain text explanations.

      INPUTS:
      1. Resources: "$resources"
      2. Total Grant: RM $budgetAmount
      
      TASK:
      If the inputs are valid resources, generate a detailed, professional project plan JSON for a village rejuvenation project.
      
      REQUIREMENTS FOR VALID PROJECTS:
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

      // Attempt to parse JSON
      final jsonMap = jsonDecode(cleanJson);

      return Project.fromJson(jsonMap);
    } catch (e) {
      print("AI Error: $e");
      // Fallback in case of severe parsing error, ensuring the app doesn't crash
      return Project(
          title: "AI Generation Error",
          description: "Could not generate plan. Please try again with clearer inputs. (Error: $e)",
          timeline: "N/A",
          skills: [],
          participantRange: "0",
          milestones: [],
          totalBudget: budgetAmount
      );
    }
  }
}