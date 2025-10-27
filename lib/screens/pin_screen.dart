import 'package:flutter/material.dart';
import '../providers/settings_provider.dart';

class PinScreen extends StatefulWidget {
  final Function(String)? onSuccess;
  final bool isSetupMode;
  final String? oldPin;
  final SettingsProvider settingsProvider;

  const PinScreen({
    super.key,
    this.onSuccess,
    this.isSetupMode = false,
    this.oldPin,
    required this.settingsProvider,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> with TickerProviderStateMixin {
  final List<String> _enteredPin = [];
  final int _pinLength = 4;
  bool _isLoading = false;
  String _errorMessage = '';
  int _failedAttempts = 0;
  final int _maxFailedAttempts = 3;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _addDigit(String digit) {
    if (_enteredPin.length < _pinLength) {
      setState(() {
        _enteredPin.add(digit);
        _errorMessage = '';
      });
      if (_enteredPin.length == _pinLength) {
        _processPin();
      }
    }
  }

  void _deleteDigit() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
        _errorMessage = '';
      });
    }
  }

  Future<void> _processPin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pin = _enteredPin.join('');
      print('PinScreen: Processing PIN: $pin');

      // Sử dụng SettingsProvider được truyền vào
      SettingsProvider settingsProvider = widget.settingsProvider;
      print('PinScreen: SettingsProvider pinCode: ${settingsProvider.pinCode}');
      print(
          'PinScreen: SettingsProvider isPinEnabled: ${settingsProvider.isPinEnabled}');
      print(
          'PinScreen: SettingsProvider isAppLocked: ${settingsProvider.isAppLocked}');

      if (widget.isSetupMode) {
        print('PinScreen: Setup mode');
        // Setup mode - verify old PIN if provided
        if (widget.oldPin != null) {
          if (widget.oldPin != pin) {
            throw Exception('Mã PIN cũ không đúng');
          }
        }
        // For new PIN setup, we'll handle it in the calling screen
        if (widget.onSuccess != null) {
          print('PinScreen: Calling onSuccess callback with PIN: $pin');
          widget.onSuccess!(pin);
        }
      } else {
        print('PinScreen: Verification mode');
        // Verification mode
        bool isValid = settingsProvider.verifyPinCode(pin);
        print('PinScreen: PIN verification result: $isValid');

        if (isValid) {
          print('PinScreen: PIN is valid, unlocking app...');
          await settingsProvider.unlockApp();
          print('PinScreen: App unlocked, calling onSuccess callback');
          if (widget.onSuccess != null) {
            widget.onSuccess!(pin);
          }
        } else {
          _failedAttempts++;
          if (_failedAttempts >= _maxFailedAttempts) {
            throw Exception('Quá nhiều lần nhập sai. Vui lòng thử lại sau.');
          } else {
            throw Exception(
                'Mã PIN không đúng. Còn ${_maxFailedAttempts - _failedAttempts} lần thử.');
          }
        }
      }
    } catch (e) {
      print('PinScreen: Error processing PIN: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _enteredPin.clear();
        _failedAttempts++;
      });
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF667eea),
      body: SafeArea(
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header section
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.security,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        widget.isSetupMode ? 'Thiết lập mã PIN' : 'Nhập mã PIN',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        widget.isSetupMode
                            ? 'Tạo mã PIN 4 chữ số để bảo vệ ứng dụng'
                            : 'Nhập mã PIN để tiếp tục',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // PIN Dots
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_pinLength, (index) {
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index < _enteredPin.length
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.3),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Error Message
                      if (_errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),

                // Number Pad section
                Expanded(
                  flex: 3,
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: List.generate(12, (index) {
                      if (index == 9) {
                        // Empty space
                        return const SizedBox();
                      } else if (index == 10) {
                        // Number 0
                        return _buildNumberButton('0');
                      } else if (index == 11) {
                        // Delete button
                        return _buildActionButton(
                          icon: Icons.backspace_outlined,
                          onTap: _deleteDigit,
                        );
                      } else {
                        // Numbers 1-9
                        return _buildNumberButton('${index + 1}');
                      }
                    }),
                  ),
                ),

                // Loading indicator
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: () => _addDigit(number),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
