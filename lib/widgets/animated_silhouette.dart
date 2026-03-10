import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AnimatedSilhouette extends StatefulWidget {
  final double radius;
  const AnimatedSilhouette({super.key, this.radius = 50});

  @override
  State<AnimatedSilhouette> createState() => _AnimatedSilhouetteState();
}

class _AnimatedSilhouetteState extends State<AnimatedSilhouette> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.1, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: theme.primaryColor.withOpacity(_animation.value),
          child: Icon(
            LucideIcons.user,
            size: widget.radius,
            color: theme.primaryColor.withOpacity(0.5),
          ),
        );
      },
    );
  }
}
