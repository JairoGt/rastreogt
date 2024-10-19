import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedNotificationIcon extends StatefulWidget {
  final VoidCallback onPressed;
  final Stream<void> notificationStream;

  const AnimatedNotificationIcon({
    super.key,
    required this.onPressed,
    required this.notificationStream,
  });

  @override
  _AnimatedNotificationIconState createState() => _AnimatedNotificationIconState();
}

class _AnimatedNotificationIconState extends State<AnimatedNotificationIcon> {
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    widget.notificationStream.listen((_) {
      setState(() {
        _isAnimating = true;
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _isAnimating = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.notifications,
        color: Colors.white,
      ).animate(target: _isAnimating ? 1 : 0)
        .shake(duration: 1000.ms)
        .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
        .then()
        .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1)),
      onPressed: widget.onPressed,
    );
  }
}