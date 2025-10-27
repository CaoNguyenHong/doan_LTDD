import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/notification_provider.dart';
import '../main.dart';

/// Utility class để truy cập Providers một cách an toàn
///
/// ⚠️ CẢNH BÁO: Chỉ sử dụng các phương thức này với BuildContext
/// chắc chắn nằm dưới MultiProvider. KHÔNG sử dụng trong:
/// - MaterialPageRoute.builder
/// - showDialog/showModalBottomSheet builder
/// - StatefulBuilder builder
///
/// Thay vào đó, hãy truyền Provider instance qua constructor hoặc callback.
class ProviderUtils {
  /// Lấy SettingsProvider từ context hoặc global navigator
  ///
  /// ⚠️ CẢNH BÁO: Chỉ sử dụng với BuildContext chắc chắn nằm dưới MultiProvider
  static SettingsProvider getSettingsProvider(BuildContext? context) {
    if (context != null) {
      try {
        return Provider.of<SettingsProvider>(context, listen: false);
      } catch (e) {
        // Fallback to global navigator
      }
    }

    final navigatorContext = navigatorKey.currentContext;
    if (navigatorContext != null) {
      return Provider.of<SettingsProvider>(navigatorContext, listen: false);
    }

    throw Exception(
        'Không thể truy cập SettingsProvider. Đảm bảo context nằm dưới MultiProvider.');
  }

  /// Lấy TransactionProvider từ context hoặc global navigator
  ///
  /// ⚠️ CẢNH BÁO: Chỉ sử dụng với BuildContext chắc chắn nằm dưới MultiProvider
  static TransactionProvider getTransactionProvider(BuildContext? context) {
    if (context != null) {
      try {
        return Provider.of<TransactionProvider>(context, listen: false);
      } catch (e) {
        // Fallback to global navigator
      }
    }

    final navigatorContext = navigatorKey.currentContext;
    if (navigatorContext != null) {
      return Provider.of<TransactionProvider>(navigatorContext, listen: false);
    }

    throw Exception(
        'Không thể truy cập TransactionProvider. Đảm bảo context nằm dưới MultiProvider.');
  }

  /// Lấy AccountProvider từ context hoặc global navigator
  ///
  /// ⚠️ CẢNH BÁO: Chỉ sử dụng với BuildContext chắc chắn nằm dưới MultiProvider
  static AccountProvider getAccountProvider(BuildContext? context) {
    if (context != null) {
      try {
        return Provider.of<AccountProvider>(context, listen: false);
      } catch (e) {
        // Fallback to global navigator
      }
    }

    final navigatorContext = navigatorKey.currentContext;
    if (navigatorContext != null) {
      return Provider.of<AccountProvider>(navigatorContext, listen: false);
    }

    throw Exception(
        'Không thể truy cập AccountProvider. Đảm bảo context nằm dưới MultiProvider.');
  }

  /// Lấy BudgetProvider từ context hoặc global navigator
  ///
  /// ⚠️ CẢNH BÁO: Chỉ sử dụng với BuildContext chắc chắn nằm dưới MultiProvider
  static BudgetProvider getBudgetProvider(BuildContext? context) {
    if (context != null) {
      try {
        return Provider.of<BudgetProvider>(context, listen: false);
      } catch (e) {
        // Fallback to global navigator
      }
    }

    final navigatorContext = navigatorKey.currentContext;
    if (navigatorContext != null) {
      return Provider.of<BudgetProvider>(navigatorContext, listen: false);
    }

    throw Exception(
        'Không thể truy cập BudgetProvider. Đảm bảo context nằm dưới MultiProvider.');
  }

  /// Lấy RecurringProvider từ context hoặc global navigator
  ///
  /// ⚠️ CẢNH BÁO: Chỉ sử dụng với BuildContext chắc chắn nằm dưới MultiProvider
  static RecurringProvider getRecurringProvider(BuildContext? context) {
    if (context != null) {
      try {
        return Provider.of<RecurringProvider>(context, listen: false);
      } catch (e) {
        // Fallback to global navigator
      }
    }

    final navigatorContext = navigatorKey.currentContext;
    if (navigatorContext != null) {
      return Provider.of<RecurringProvider>(navigatorContext, listen: false);
    }

    throw Exception(
        'Không thể truy cập RecurringProvider. Đảm bảo context nằm dưới MultiProvider.');
  }

  /// Lấy ExpenseProvider từ context hoặc global navigator
  ///
  /// ⚠️ CẢNH BÁO: Chỉ sử dụng với BuildContext chắc chắn nằm dưới MultiProvider
  static ExpenseProvider getExpenseProvider(BuildContext? context) {
    if (context != null) {
      try {
        return Provider.of<ExpenseProvider>(context, listen: false);
      } catch (e) {
        // Fallback to global navigator
      }
    }

    final navigatorContext = navigatorKey.currentContext;
    if (navigatorContext != null) {
      return Provider.of<ExpenseProvider>(navigatorContext, listen: false);
    }

    throw Exception(
        'Không thể truy cập ExpenseProvider. Đảm bảo context nằm dưới MultiProvider.');
  }

  /// Lấy AnalyticsProvider từ context hoặc global navigator
  ///
  /// ⚠️ CẢNH BÁO: Chỉ sử dụng với BuildContext chắc chắn nằm dưới MultiProvider
  static AnalyticsProvider getAnalyticsProvider(BuildContext? context) {
    if (context != null) {
      try {
        return Provider.of<AnalyticsProvider>(context, listen: false);
      } catch (e) {
        // Fallback to global navigator
      }
    }

    final navigatorContext = navigatorKey.currentContext;
    if (navigatorContext != null) {
      return Provider.of<AnalyticsProvider>(navigatorContext, listen: false);
    }

    throw Exception(
        'Không thể truy cập AnalyticsProvider. Đảm bảo context nằm dưới MultiProvider.');
  }

  /// Lấy NotificationProvider từ context hoặc global navigator
  ///
  /// ⚠️ CẢNH BÁO: Chỉ sử dụng với BuildContext chắc chắn nằm dưới MultiProvider
  static NotificationProvider getNotificationProvider(BuildContext? context) {
    if (context != null) {
      try {
        return Provider.of<NotificationProvider>(context, listen: false);
      } catch (e) {
        // Fallback to global navigator
      }
    }

    final navigatorContext = navigatorKey.currentContext;
    if (navigatorContext != null) {
      return Provider.of<NotificationProvider>(navigatorContext, listen: false);
    }

    throw Exception(
        'Không thể truy cập NotificationProvider. Đảm bảo context nằm dưới MultiProvider.');
  }

  /// Navigate đến một route mới sử dụng global navigator
  ///
  /// ⚠️ CẢNH BÁO: Chỉ sử dụng khi không có BuildContext phù hợp
  static Future<T?> navigateTo<T extends Object?>(Route<T> route) {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      return navigator.push(route);
    }
    throw Exception('Không thể navigate - Navigator không khả dụng');
  }

  /// Pop route hiện tại
  ///
  /// ⚠️ CẢNH BÁO: Chỉ sử dụng khi không có BuildContext phù hợp
  static void pop<T extends Object?>([T? result]) {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.pop(result);
    }
  }

  /// Pop đến route cụ thể
  ///
  /// ⚠️ CẢNH BÁO: Chỉ sử dụng khi không có BuildContext phù hợp
  static void popUntil(RoutePredicate predicate) {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.popUntil(predicate);
    }
  }
}
