import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:currency_picker/currency_picker.dart';
import '../providers/settings_provider.dart';
import '../auth/auth_repo.dart';
import '../auth/auth_gate.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) => Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // Custom App Bar with Profile Header
              SliverAppBar(
                expandedHeight: 280,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF667eea),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF667eea),
                          Color(0xFF764ba2),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      settings.userName.isNotEmpty
                                          ? settings.userName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        settings.userName,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Quản lý tài khoản và cài đặt',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Quick Stats
                        _buildQuickStats(settings),
                        const SizedBox(height: 20),

                        // Settings Sections
                        _buildSection(
                          context,
                          'Giao diện',
                          Icons.palette,
                          const Color(0xFF667eea),
                          [
                            _buildSwitchTile(
                              'Chế độ tối',
                              'Bật/tắt giao diện tối',
                              Icons.dark_mode,
                              settings.isDarkMode,
                              settings.setDarkMode,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _buildSection(
                          context,
                          'Tiền tệ và giới hạn',
                          Icons.account_balance_wallet,
                          const Color(0xFF48BB78),
                          [
                            _buildListTile(
                              'Tiền tệ',
                              settings.currency,
                              Icons.attach_money,
                              () => _showCurrencyPicker(context, settings),
                            ),
                            _buildLimitTile(
                              context,
                              'Thu nhập hàng tháng',
                              settings.monthlyIncome,
                              settings.currency,
                              settings.setMonthlyIncome,
                            ),
                            _buildLimitTile(
                              context,
                              'Giới hạn hàng ngày',
                              settings.dailyLimit,
                              settings.currency,
                              settings.setDailyLimit,
                            ),
                            _buildLimitTile(
                              context,
                              'Giới hạn hàng tuần',
                              settings.weeklyLimit,
                              settings.currency,
                              settings.setWeeklyLimit,
                            ),
                            _buildLimitTile(
                              context,
                              'Giới hạn hàng tháng',
                              settings.monthlyLimit,
                              settings.currency,
                              settings.setMonthlyLimit,
                            ),
                            _buildLimitTile(
                              context,
                              'Giới hạn hàng năm',
                              settings.yearlyLimit,
                              settings.currency,
                              settings.setYearlyLimit,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _buildSection(
                          context,
                          'Tài khoản',
                          Icons.person,
                          const Color(0xFFED8936),
                          [
                            _buildListTile(
                              'Đổi tên người dùng',
                              settings.userName,
                              Icons.edit,
                              () => _showUsernameDialog(context, settings),
                            ),
                            _buildListTile(
                              'Đăng xuất',
                              'Đăng xuất khỏi tài khoản của bạn',
                              Icons.logout,
                              () => _showSignOutDialog(context),
                              isDestructive: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            'Thống kê nhanh',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Thu nhập tháng',
                  '\$${settings.monthlyIncome.toStringAsFixed(0)}',
                  Icons.trending_up,
                  const Color(0xFF48BB78),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Giới hạn ngày',
                  '\$${settings.dailyLimit.toStringAsFixed(0)}',
                  Icons.schedule,
                  const Color(0xFF667eea),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.grey.shade600,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : const Color(0xFF2D3748),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDestructive ? Colors.red.shade400 : Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.grey.shade600, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3748),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF667eea),
      ),
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
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.attach_money, color: Colors.grey.shade600, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3748),
        ),
      ),
      subtitle: Text(
        '$currency${value.toStringAsFixed(2)}',
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: () => _showNumberInputDialog(context, title, value, onChanged),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Đặt $title'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: '\$',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                onChanged(value);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, SettingsProvider settings) {
    showCurrencyPicker(
      context: context,
      onSelect: (Currency currency) {
        settings.setCurrency(currency.code);
      },
    );
  }

  void _showUsernameDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Đổi tên người dùng'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tên người dùng',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                settings.setUserName(controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _signOut(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final authRepo = AuthRepo();
      await authRepo.signOut();

      if (mounted) {
        // Clear navigation stack and go to auth gate
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Đăng xuất thành công!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Lỗi đăng xuất: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
