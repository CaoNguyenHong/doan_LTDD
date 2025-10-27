import 'package:flutter/material.dart';

class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    print('AppLifecycleManager: App state changed to $state');

    // Không cần khóa app ở đây vì AuthGate sẽ tự động khóa khi khởi động
    // AppLifecycleManager chỉ log lifecycle state
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        print(
            'AppLifecycleManager: App backgrounded - AuthGate will handle PIN lock on next startup');
        break;
      case AppLifecycleState.resumed:
        print('AppLifecycleManager: App resumed');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
