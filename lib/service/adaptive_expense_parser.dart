// Enhanced ExpenseParser with learning capabilities
import 'package:spend_sage/hive/learned_category.dart';
import 'package:spend_sage/service/database_service.dart';

class AdaptiveExpenseParser {
  static final RegExp _amountPattern = RegExp(r'\b(\d+(\.\d{1,2})?)\b');
  //static late Box<LearnedCategory> _learnedCategoriesBox;

  // Expanded category keywords including common items and variations
  static final Map<String, List<String>> _baseKeywords = {
    'food': [
      // Generic terms
      'food', 'lunch', 'dinner', 'breakfast', 'snack', 'grocery', 'restaurant',
      'meal', 'coffee',
      // Specific food items
      'burger', 'pizza', 'sandwich', 'sushi', 'rice', 'noodles', 'pasta',
      'salad', 'bread',
      'chicken', 'meat', 'fish', 'seafood', 'vegetables', 'fruits', 'dessert',
      'ice cream',
      // Drink items
      'drink', 'beverage', 'coffee', 'tea', 'juice', 'soda', 'water',
      // Places
      'restaurant', 'café', 'cafeteria', 'diner', 'bistro', 'bakery',
      'supermarket',
      'mcdonalds', 'starbucks', 'subway', 'kfc', 'foodcourt',
    ],
    'transport': [
      // Methods
      'transport', 'transportation', 'bus', 'train', 'taxi', 'uber', 'lyft',
      'grab', 'fare',
      'subway', 'metro', 'railway', 'cab', 'ride',
      // Vehicle related
      'gas', 'fuel', 'petrol', 'diesel', 'parking', 'toll', 'car', 'bike',
      'bicycle', 'scooter',
      'motorcycle', 'vehicle', 'maintenance', 'service', 'repair', 'wash',
      // Air travel
      'flight', 'plane', 'airline', 'airport', 'travel',
    ],
    'shopping': [
      // Clothing
      'shopping', 'clothes', 'clothing', 'shirt', 't-shirt', 'pants', 'jeans',
      'dress', 'shoes',
      'jacket', 'coat', 'socks', 'underwear', 'accessories', 'hat', 'cap',
      'scarf', 'belt',
      // Electronics
      'electronics', 'phone', 'laptop', 'computer', 'tablet', 'gadget',
      'device', 'charger',
      'headphones', 'earphones', 'speaker',
      // Places
      'store', 'mall', 'shop', 'retail', 'market', 'outlet', 'boutique',
      'amazon', 'online',
      // Home items
      'furniture', 'decor', 'household', 'kitchen', 'appliance', 'tool',
      // Personal care
      'cosmetics', 'makeup', 'skincare', 'perfume', 'toiletries',
    ],
    'utilities': [
      // Basic utilities
      'utility', 'utilities', 'electricity', 'water', 'gas', 'power', 'energy',
      // Communications
      'internet', 'wifi', 'broadband', 'phone', 'mobile', 'cellular',
      'telephone', 'network',
      // Home related
      'rent', 'lease', 'mortgage', 'housing', 'maintenance', 'repair',
      // Bills
      'bill', 'invoice', 'subscription', 'service', 'payment',
      // Insurance
      'insurance', 'coverage', 'protection',
    ],
    'entertainment': [
      // Events
      'entertainment', 'movie', 'film', 'cinema', 'theater', 'theatre',
      'concert', 'show',
      'performance', 'event', 'ticket', 'admission', 'entry',
      // Activities
      'game', 'gaming', 'sport', 'sports', 'gym', 'fitness', 'recreation',
      'hobby',
      'park', 'museum', 'exhibition', 'zoo', 'amusement',
      // Digital entertainment
      'netflix', 'spotify', 'subscription', 'streaming', 'music', 'video',
      'app', 'game',
      // Social
      'bar', 'pub', 'club', 'party', 'social', 'gathering',
    ],
  };

  // Get combined keywords (base + learned)
  static Map<String, List<String>> _getAllKeywords() {
    final Map<String, List<String>> allKeywords = Map.from(_baseKeywords);

    // Add learned keywords with their frequencies
    for (var learned in DatabaseService.learnedCategoriesBox.values) {
      if (!allKeywords[learned.category]!.contains(learned.word)) {
        allKeywords[learned.category]!.add(learned.word);
      }
    }

    return allKeywords;
  }

  static Map<String, dynamic> parseExpenseInput(String input) {
    final String normalizedInput = input.toLowerCase();

    // Extract amount
    final Match? amountMatch = _amountPattern.firstMatch(normalizedInput);
    if (amountMatch == null) {
      throw const FormatException('No valid amount found in the input');
    }
    final double amount = double.parse(amountMatch.group(1)!);

    // Get all keywords including learned ones
    final allKeywords = _getAllKeywords();

    // Determine category using word tokenization
    String category = 'other';
    double maxScore = 0.0;
    final List<String> words = normalizedInput.split(RegExp(r'\s+'));

    for (final entry in allKeywords.entries) {
      double score = 0.0;

      for (final word in words) {
        if (word.length <= 3) continue; // Skip very short words

        // Check exact matches
        if (entry.value.contains(word)) {
          score += _getWordScore(word, entry.key);
        }
        // Check partial matches
        else {
          for (final keyword in entry.value) {
            if (word.contains(keyword) || keyword.contains(word)) {
              score += _getWordScore(word, entry.key) * 0.5;
            }
          }
        }
      }

      if (score > maxScore) {
        maxScore = score;
        category = entry.key;
      }
    }

    // Clean up description
    String description = normalizedInput
        .replaceAll(_amountPattern, '')
        .replaceAll(
            RegExp(r'\b(spent|paid|bought|dollars|usd|\$|for|on|at|the)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (description.length > 50) {
      description = description.split(' ').take(5).join(' ');
    }

    return {
      'category': category,
      'amount': amount,
      'description': description,
      'originalWords': words, // Keep original words for learning
    };
  }

  // Calculate word score based on learned frequencies
  static double _getWordScore(String word, String category) {
    final learned = DatabaseService.learnedCategoriesBox.values.firstWhere(
      (item) => item.word == word && item.category == category,
      orElse: () =>
          LearnedCategory(word: word, category: category, frequency: 0),
    );

    // Base score is 1.0, additional 0.2 for each time it was learned
    return 1.0 + (learned.frequency * 0.2);
  }

  // Learn from user corrections
  static Future<void> learnFromCorrection(
      String originalText, String correctedCategory) async {
    final originalWords = originalText.toLowerCase().split(RegExp(r'\s+'));

    for (var word in originalWords) {
      if (word.length <= 3) continue; // Skip very short words

      // Clean the word
      word = word.replaceAll(RegExp(r'[^\w\s]'), '');

      // Find existing learned category or create new one
      final existing = DatabaseService.learnedCategoriesBox.values.firstWhere(
        (item) => item.word == word && item.category == correctedCategory,
        orElse: () => LearnedCategory(word: word, category: correctedCategory),
      );

      // Update frequency and save
      existing.frequency++;
      await DatabaseService.learnedCategoriesBox
          .put('$word-$correctedCategory', existing);
    }
  }

  // Reset learned categories
  static Future<void> resetLearning() async {
    await DatabaseService.learnedCategoriesBox.clear();
  }
}
