import 'package:flutter/material.dart';

class Utilities {
  // Re-usable animated dialog
  static Future<void> showAnimatedDialog({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation1, animation2) {
        return Container();
      },
      transitionBuilder: (context, animation1, animation2, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(
              parent: animation1,
              curve: Curves.bounceInOut,
            ),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.5, end: 1.0).animate(
              CurvedAnimation(
                parent: animation1,
                curve: Curves.bounceIn,
              ),
            ),
            child: AlertDialog(
              title: Text(
                title,
                textAlign: TextAlign.center,
              ),
              content: content,
              actions: actions,
            ),
          ),
        );
      },
    );
  }
}
