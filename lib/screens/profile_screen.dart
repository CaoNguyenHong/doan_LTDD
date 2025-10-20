import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:currency_picker/currency_picker.dart';
import '../providers/settings_provider.dart';
import '../auth/auth_repo.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) => Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(settings.userName),
                background: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        settings.userName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                _buildSection(
                  context,
                  'Appearance',
                  [
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      value: settings.isDarkMode,
                      onChanged: settings.setDarkMode,
                    ),
                  ],
                ),
                _buildSection(
                  context,
                  'Currency and Limits',
                  [
                    ListTile(
                      title: const Text('Currency'),
                      subtitle: Text(settings.currency),
                      onTap: () => _showCurrencyPicker(context, settings),
                    ),
                    _buildLimitTile(
                      context,
                      'Monthly Income',
                      settings.monthlyIncome,
                      settings.currency,
                      settings.setMonthlyIncome,
                    ),
                    _buildLimitTile(
                      context,
                      'Daily Limit',
                      settings.dailyLimit,
                      settings.currency,
                      settings.setDailyLimit,
                    ),
                    _buildLimitTile(
                      context,
                      'Weekly Limit',
                      settings.weeklyLimit,
                      settings.currency,
                      settings.setWeeklyLimit,
                    ),
                    _buildLimitTile(
                      context,
                      'Monthly Limit',
                      settings.monthlyLimit,
                      settings.currency,
                      settings.setMonthlyLimit,
                    ),
                    _buildLimitTile(
                      context,
                      'Yearly Limit',
                      settings.yearlyLimit,
                      settings.currency,
                      settings.setYearlyLimit,
                    ),
                  ],
                ),
                _buildSection(
                  context,
                  'Account',
                  [
                    ListTile(
                      title: const Text('Change Username'),
                      subtitle: Text(settings.userName),
                      onTap: () => _showUsernameDialog(context, settings),
                    ),
                    ListTile(
                      title: const Text('Sign Out'),
                      subtitle: const Text('Sign out of your account'),
                      leading: const Icon(Icons.logout),
                      onTap: () => _showSignOutDialog(context),
                    ),
                  ],
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildLimitTile(
    BuildContext context,
    String title,
    double value,
    String currency,
    Function(double) onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text('$currency${value.toStringAsFixed(2)}'),
      onTap: () => _showNumberInputDialog(
        context,
        title,
        value,
        onChanged,
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, SettingsProvider settings) {
    showCurrencyPicker(
      context: context,
      showFlag: true,
      showSearchField: true,
      showCurrencyName: true,
      showCurrencyCode: true,
      onSelect: (Currency currency) {
        settings.setCurrency(currency.symbol);
      },
    );
  }

  void _showNumberInputDialog(
    BuildContext context,
    String title,
    double currentValue,
    Function(double) onChanged,
  ) {
    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set $title'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                onChanged(value);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showUsernameDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Username',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                settings.setUserName(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _signOut(context);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final authRepo = AuthRepo();
      await authRepo.signOut();
      // Navigation will be handled by AuthGate
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e')),
        );
      }
    }
  }
}
