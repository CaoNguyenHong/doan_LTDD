import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:spend_sage/utilities/utilities.dart';
import 'package:spend_sage/widgets/filter_selector.dart';
import 'package:spend_sage/widgets/total_amount_display.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final TextEditingController _expenseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('SpendSage'),
            actions: const [
              TotalAmountDisplay(),
              SizedBox(width: 16),
              FilterSelector(),
            ],
          ),
          body: Column(
            children: [
              if (expenseProvider.error.isNotEmpty)
                Container(
                  color: Colors.red.shade100,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    expenseProvider.error,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Expanded(
                child: ExpenseList(expenses: expenseProvider.expenses),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Utilities.showAnimatedDialog(
                  context: context,
                  title: 'Enter Expense',
                  content: _buildExpenseInput(expenseProvider),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ]);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          ),
        );
      },
    );
  }

  Widget _buildExpenseInput(ExpenseProvider expenseProvider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _expenseController,
          decoration: InputDecoration(
            hintText: 'Describe your expense...',
            helperText: 'Example: "spent 25 dollars on lunch today"',
            suffixIcon: IconButton(
              onPressed: () {
                if (_isListening) {
                  _stopListening();
                } else {
                  _startListening();
                }
              },
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () async {
                if (_expenseController.text.isNotEmpty) {
                  await expenseProvider
                      .addExpenseFromText(_expenseController.text);
                  // clear the text field
                  _expenseController.clear();
                  if (mounted && expenseProvider.error.isEmpty) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Add with AI'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_expenseController.text.isNotEmpty) {
                  await expenseProvider
                      .addExpenseFromTextLocal(_expenseController.text);
                  // clear the text field
                  _expenseController.clear();
                  if (mounted && expenseProvider.error.isEmpty) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Add Locally'),
            ),
          ],
        ),
      ],
    );
  }
}
