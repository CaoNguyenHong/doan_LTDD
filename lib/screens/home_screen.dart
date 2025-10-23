import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:spend_sage/utilities/utilities.dart';
import 'package:spend_sage/widgets/filter_selector.dart';
import 'package:spend_sage/widgets/total_amount_display.dart';
import 'package:spend_sage/hive/expense.dart';
import 'package:uuid/uuid.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final TextEditingController _expenseController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    await _speech.initialize();
  }

  void _startListening() async {
    if (!_isListening) {
      if (await _speech.initialize()) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _expenseController.text = result.recognizedWords;
            });
          },
        );
      }
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _showAddExpenseDialog(
      BuildContext context, ExpenseProvider expenseProvider) {
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    String selectedCategory = 'food';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Thêm chi tiêu mới',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              // Description Field
              TextField(
                controller: descriptionController,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Mô tả chi tiêu',
                  labelStyle: const TextStyle(color: Colors.black87),
                  hintText: 'Ví dụ: Mua cà phê, Ăn trưa...',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: const Icon(Icons.description_outlined,
                      color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF667eea),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextField(
                controller: amountController,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Số tiền',
                  labelStyle: const TextStyle(color: Colors.black87),
                  hintText: 'Nhập số tiền...',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon:
                      const Icon(Icons.attach_money, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF667eea),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: selectedCategory,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Danh mục',
                  labelStyle: const TextStyle(color: Colors.black87),
                  prefixIcon:
                      const Icon(Icons.category_outlined, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF667eea),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                dropdownColor: Colors.white,
                items: const [
                  DropdownMenuItem(
                    value: 'food',
                    child: Text(
                      '🍽️ Ăn uống',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'transport',
                    child: Text(
                      '🚗 Giao thông',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'utilities',
                    child: Text(
                      '⚡ Tiện ích',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'health',
                    child: Text(
                      '🏥 Sức khỏe',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'education',
                    child: Text(
                      '📚 Giáo dục',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'shopping',
                    child: Text(
                      '🛍️ Mua sắm',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'entertainment',
                    child: Text(
                      '🎬 Giải trí',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(
                      '📦 Khác',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ],
                onChanged: (String? value) {
                  if (value != null) {
                    selectedCategory = value;
                  }
                },
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (descriptionController.text.isNotEmpty &&
                            amountController.text.isNotEmpty) {
                          final amount = double.tryParse(amountController.text);
                          if (amount != null && amount > 0) {
                            // Create expense manually
                            final expense = Expense(
                              id: const Uuid().v4(),
                              category: selectedCategory,
                              amount: amount,
                              description: descriptionController.text,
                              dateTime: DateTime.now(),
                            );

                            await expenseProvider.addExpenseFromText(
                                '${expense.description} ${expense.amount} ${expense.category}');

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('✅ Đã thêm chi tiêu thành công!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('❌ Vui lòng nhập số tiền hợp lệ!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('❌ Vui lòng điền đầy đủ thông tin!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Thêm chi tiêu'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenseInput(ExpenseProvider expenseProvider) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _expenseController,
            decoration: const InputDecoration(
              hintText: 'Mô tả chi tiêu của bạn...',
              helperText: 'Ví dụ: "chi 25 đô cho bữa trưa hôm nay"',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isListening ? _stopListening : _startListening,
                  icon: Icon(_isListening ? Icons.stop : Icons.mic),
                  label: Text(_isListening ? 'Dừng' : 'Ghi âm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_expenseController.text.isNotEmpty) {
                      await expenseProvider
                          .addExpenseFromText(_expenseController.text);
                      _expenseController.clear();
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.smart_toy),
                  label: const Text('Thêm với AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (_expenseController.text.isNotEmpty) {
                  await expenseProvider
                      .addExpenseFromText(_expenseController.text);
                  _expenseController.clear();
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm cục bộ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: const Text('SpendSage'),
            backgroundColor: const Color(0xFF667eea),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FilterSelector(),
              ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF667eea),
                          Color(0xFF764ba2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chào mừng trở lại!',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SpendSage',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        // Total Amount Display
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const TotalAmountDisplay(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick Actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thao tác nhanh',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2D3748),
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionButton(
                                icon: Icons.add_circle_outline,
                                label: 'Thêm chi tiêu',
                                color: const Color(0xFF667eea),
                                onTap: () => _showAddExpenseDialog(
                                    context, expenseProvider),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                icon: Icons.analytics_outlined,
                                label: 'Xem báo cáo',
                                color: const Color(0xFF48BB78),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Chuyển đến tab Biểu đồ'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Recent Expenses Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chi tiêu gần đây',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3748),
                            ),
                      ),
                      TextButton(
                        onPressed: () =>
                            _showAddExpenseDialog(context, expenseProvider),
                        child: const Text(
                          'Thêm mới',
                          style: TextStyle(
                            color: Color(0xFF667eea),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Expense List
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: expenseProvider.expenses.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Chưa có chi tiêu nào',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Thêm chi tiêu đầu tiên của bạn',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.grey.shade500,
                                      ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddExpenseDialog(
                                      context, expenseProvider),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Thêm chi tiêu'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF667eea),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ExpenseList(expenses: expenseProvider.expenses),
                  ),

                  const SizedBox(height: 100), // Bottom padding for FAB
                ],
              ),
            ),
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () => _showAddExpenseDialog(context, expenseProvider),
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Thêm chi tiêu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
