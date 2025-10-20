import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class AIService {
  final GenerativeModel model;

  AIService({required String apiKey})
      : model = GenerativeModel(
          model: 'gemini-1.5-flash-8b',
          apiKey: apiKey,
        );

  Future<Map<String, dynamic>> processExpenseInput(String input) async {
    try {
      final prompt = '''
        Extract expense information from the following text and return it in JSON format with these fields:
        - category (one of: food, transport, shopping, utilities, entertainment, other)
        - amount (numeric value, extract any number that represents currency)
        - description (brief description of the expense)
        
        Example input: "spent 25 dollars on lunch today"
        Example output: {"category": "food", "amount": 25.0, "description": "lunch"}
        
        Input text: $input
        
        Return only the JSON object, no other text.
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final text = response.text;

      // Remove any markdown code block markers if present
      final jsonText =
          text?.replaceAll('```json', '').replaceAll('```', '').trim();

      try {
        final Map<String, dynamic> parsed = json.decode(jsonText!);

        // Validate the required fields
        if (!parsed.containsKey('category') ||
            !parsed.containsKey('amount') ||
            !parsed.containsKey('description')) {
          throw const FormatException('Missing required fields in AI response');
        }

        // Ensure amount is a double
        parsed['amount'] = double.parse(parsed['amount'].toString());

        return parsed;
      } catch (e) {
        throw FormatException('Failed to parse AI response: $e');
      }
    } catch (e) {
      throw Exception('Failed to process expense: $e');
    }
  }
}
