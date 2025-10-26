import '../hive/expense.dart';
import '../models/transaction.dart' as models;

class TransactionConverter {
  /// Convert Transaction to Expense for backward compatibility
  static Expense transactionToExpense(models.Transaction transaction) {
    return Expense(
      id: transaction.id,
      description: transaction.description,
      amount: transaction.amount,
      category: mapCategory(transaction.categoryId),
      dateTime: transaction.dateTime,
    );
  }

  /// Convert Expense to Transaction
  static models.Transaction expenseToTransaction(Expense expense) {
    return models.Transaction(
      id: expense.id,
      type: 'expense', // Default to expense
      accountId: 'default-account', // Default account
      categoryId: _mapCategoryToId(expense.category),
      amount: expense.amount,
      currency: 'VND', // Default currency
      description: expense.description,
      tags: [],
      dateTime: expense.dateTime,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      deleted: false,
    );
  }

  /// Map category ID to category name
  static String mapCategory(String? categoryId) {
    switch (categoryId) {
      // Expense categories
      case 'food':
        return '🍽️ Ăn uống';
      case 'transport':
        return '🚗 Giao thông';
      case 'shopping':
        return '🛍️ Mua sắm';
      case 'entertainment':
        return '🎬 Giải trí';
      case 'utilities':
        return '💡 Tiện ích';
      case 'health':
        return '🏥 Sức khỏe';
      case 'healthcare':
        return '🏥 Sức khỏe';
      case 'education':
        return '📚 Giáo dục';

      // Income categories
      case 'salary':
        return '💰 Lương';
      case 'freelance':
        return '💼 Freelance';
      case 'investment':
        return '📈 Đầu tư';
      case 'business':
        return '🏢 Kinh doanh';
      case 'gift':
        return '🎁 Quà tặng';

      // Transfer categories
      case 'savings':
        return '🏦 Tiết kiệm';
      case 'loan':
        return '💳 Vay mượn';
      case 'family':
        return '👨‍👩‍👧‍👦 Gia đình';

      // Refund categories
      case 'purchase':
        return '🛒 Mua hàng';
      case 'service':
        return '🔧 Dịch vụ';
      case 'subscription':
        return '📱 Đăng ký';

      case 'other':
        return '📝 Khác';
      default:
        return '📝 Khác';
    }
  }

  /// Map category name to category ID
  static String _mapCategoryToId(String category) {
    // Expense categories
    if (category.contains('🍽️') || category.contains('Ăn uống')) return 'food';
    if (category.contains('🚗') || category.contains('Giao thông'))
      return 'transport';
    if (category.contains('🛍️') || category.contains('Mua sắm'))
      return 'shopping';
    if (category.contains('🎬') || category.contains('Giải trí'))
      return 'entertainment';
    if (category.contains('💡') || category.contains('Tiện ích'))
      return 'utilities';
    if (category.contains('🏥') || category.contains('Sức khỏe'))
      return 'health';
    if (category.contains('📚') || category.contains('Giáo dục'))
      return 'education';

    // Income categories
    if (category.contains('💰') || category.contains('Lương')) return 'salary';
    if (category.contains('💼') || category.contains('Freelance'))
      return 'freelance';
    if (category.contains('📈') || category.contains('Đầu tư'))
      return 'investment';
    if (category.contains('🏢') || category.contains('Kinh doanh'))
      return 'business';
    if (category.contains('🎁') || category.contains('Quà tặng')) return 'gift';

    // Transfer categories
    if (category.contains('🏦') || category.contains('Tiết kiệm'))
      return 'savings';
    if (category.contains('💳') || category.contains('Vay mượn')) return 'loan';
    if (category.contains('👨‍👩‍👧‍👦') || category.contains('Gia đình'))
      return 'family';

    // Refund categories
    if (category.contains('🛒') || category.contains('Mua hàng'))
      return 'purchase';
    if (category.contains('🔧') || category.contains('Dịch vụ'))
      return 'service';
    if (category.contains('📱') || category.contains('Đăng ký'))
      return 'subscription';

    return 'other';
  }
}
