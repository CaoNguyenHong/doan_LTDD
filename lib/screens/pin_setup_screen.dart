import 'package:flutter/material.dart';
import '../providers/settings_provider.dart';
import 'pin_screen.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isChangingPin;
  final SettingsProvider settingsProvider;
  final Function(String)? onPinSaved;

  const PinSetupScreen({
    super.key,
    this.isChangingPin = false,
    required this.settingsProvider,
    this.onPinSaved,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String? _newPin; // Lưu PIN từ lần nhập đầu tiên

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isChangingPin) {
        _showChangePinFlow();
      } else {
        _showNewPinFlow();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print(
        'PinSetupScreen: Building with isChangingPin: ${widget.isChangingPin}');
    print(
        'PinSetupScreen: SettingsProvider: ${widget.settingsProvider.runtimeType}');

    return Scaffold(
      backgroundColor: const Color(0xFF667eea),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            print('PinSetupScreen: Back button pressed');
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.isChangingPin ? 'Đổi mã PIN' : 'Thiết lập mã PIN',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 30),

                // Title
                Text(
                  widget.isChangingPin ? 'Đổi mã PIN' : 'Thiết lập mã PIN',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  widget.isChangingPin
                      ? 'Thay đổi mã PIN để bảo vệ ứng dụng'
                      : 'Tạo mã PIN 4 chữ số để bảo vệ ứng dụng',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 50),

                // Features
                _buildFeatureItem(
                  Icons.security,
                  'Bảo mật cao',
                  'Mã PIN được mã hóa và lưu trữ an toàn',
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  Icons.lock,
                  'Khóa ứng dụng',
                  'Tự động khóa khi thoát ứng dụng',
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  Icons.fingerprint,
                  'Xác thực nhanh',
                  'Nhập mã PIN để truy cập ứng dụng',
                ),
                const SizedBox(height: 60),

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.isChangingPin) {
                        _showChangePinFlow();
                      } else {
                        _showNewPinFlow();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF667eea),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.isChangingPin ? 'Đổi mã PIN' : 'Thiết lập mã PIN',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showChangePinFlow() {
    try {
      print('PinSetupScreen: Starting change PIN flow');
      // First, verify old PIN
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PinScreen(
            isSetupMode: true,
            settingsProvider: widget.settingsProvider,
            onSuccess: (pin) {
              Navigator.pop(context); // Close PIN screen
              _showNewPinFlow(); // Show new PIN setup
            },
          ),
        ),
      );
    } catch (e) {
      print('PinSetupScreen: Error in change PIN flow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNewPinFlow() {
    try {
      print('PinSetupScreen: Starting new PIN flow');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PinScreen(
            isSetupMode: true,
            settingsProvider: widget.settingsProvider,
            onSuccess: (pin) {
              print('PinSetupScreen: First PIN entered: $pin');
              _newPin = pin; // Lưu PIN đầu tiên
              Navigator.pop(context); // Close PIN screen
              _showConfirmPinFlow(); // Show confirm PIN
            },
          ),
        ),
      );
    } catch (e) {
      print('PinSetupScreen: Error in new PIN flow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showConfirmPinFlow() {
    try {
      print('PinSetupScreen: Starting confirm PIN flow');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PinScreen(
            isSetupMode: true,
            settingsProvider: widget.settingsProvider,
            onSuccess: (confirmPin) {
              print('PinSetupScreen: Confirm PIN entered: $confirmPin');
              print('PinSetupScreen: Original PIN: $_newPin');

              // Kiểm tra PIN confirmation
              if (_newPin == confirmPin) {
                print('PinSetupScreen: PINs match, saving PIN');
                Navigator.pop(context); // Close PIN screen
                _savePin(confirmPin); // Save the PIN
              } else {
                print('PinSetupScreen: PINs do not match');
                Navigator.pop(context); // Close PIN screen
                _showPinMismatchDialog(); // Show error dialog
              }
            },
          ),
        ),
      );
    } catch (e) {
      print('PinSetupScreen: Error in confirm PIN flow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePin(String pin) async {
    try {
      print('PinSetupScreen: Saving PIN: $pin');

      // Lưu PIN vào SettingsProvider
      await widget.settingsProvider.setPinCode(pin);

      // Gọi callback nếu có
      if (widget.onPinSaved != null) {
        widget.onPinSaved!(pin);
      }

      // Hiển thị thông báo thành công
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thiết lập PIN thành công'),
          content: const Text('Mã PIN đã được thiết lập thành công!'),
          actions: [
            TextButton(
              onPressed: () {
                print('PinSetupScreen: PIN setup success dialog OK pressed');
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close PinSetupScreen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('PinSetupScreen: Error saving PIN: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu PIN: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPinMismatchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Mã PIN không khớp',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Mã PIN xác nhận không khớp với mã PIN ban đầu. Vui lòng thử lại.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _newPin = null; // Reset PIN
              _showNewPinFlow(); // Start over
            },
            child: const Text('Thử lại'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close PinSetupScreen
            },
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }
}
