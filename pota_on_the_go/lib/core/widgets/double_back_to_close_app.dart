import 'package:flutter/material.dart';

class DoubleBackToCloseApp extends StatefulWidget {
  final Widget child;
  final Duration interval;
  final String message;

  const DoubleBackToCloseApp({
    required this.child,
    this.interval = const Duration(seconds: 2),
    this.message = 'Çıkmak için tekrar geriye basın',
    Key? key,
  }) : super(key: key);

  @override
  State<DoubleBackToCloseApp> createState() => _DoubleBackToCloseAppState();
}

class _DoubleBackToCloseAppState extends State<DoubleBackToCloseApp> {
  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > widget.interval) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.message), duration: widget.interval),
          );
          return false;
        }

        return true;
      },
      child: widget.child,
    );
  }
}
