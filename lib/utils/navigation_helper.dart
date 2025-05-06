import 'package:flutter/material.dart';

class NavigationHelper {
  static final observer = _NavigationObserver();

  static void push(BuildContext context, Widget page) {
    debugPrint('\x1B[33mNavigating to: ${page.runtimeType}\x1B[0m');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  static void pushReplacement(BuildContext context, Widget page) {
    debugPrint('\x1B[33mReplacing with: ${page.runtimeType}\x1B[0m');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  static void pushAndRemoveUntil(BuildContext context, Widget page) {
    debugPrint('\x1B[33mNavigating to: ${page.runtimeType} and removing all previous routes\x1B[0m');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => page),
      (route) => false,
    );
  }

  static void pop(BuildContext context) {
    debugPrint('\x1B[33mPopping current route\x1B[0m');
    Navigator.pop(context);
  }
}

class _NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('\x1B[33mPushed: ${route.settings.name}\x1B[0m');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('\x1B[33mPopped: ${route.settings.name}\x1B[0m');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint('\x1B[33mReplaced: ${oldRoute?.settings.name} with ${newRoute?.settings.name}\x1B[0m');
  }
} 