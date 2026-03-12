import 'dart:ui';

import 'package:flutter/material.dart';

/// Shared top toast helper with a Dynamic Island inspired look.
class AppToast {
  static OverlayEntry? _activeEntry;

  static void show(
    BuildContext context,
    String message, {
    bool success = true,
    Duration duration = const Duration(seconds: 2),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _activeEntry?.remove();
    _activeEntry = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return _DynamicIslandToast(
          message: message,
          success: success,
          duration: duration,
          actionLabel: actionLabel,
          onAction: onAction,
          onDismissed: () {
            if (_activeEntry == entry) {
              _activeEntry = null;
            }
            entry.remove();
          },
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }
}

class _DynamicIslandToast extends StatefulWidget {
  final String message;
  final bool success;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const _DynamicIslandToast({
    required this.message,
    required this.success,
    required this.duration,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_DynamicIslandToast> createState() => _DynamicIslandToastState();
}

class _DynamicIslandToastState extends State<_DynamicIslandToast>
    with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _timerController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _timerController =
        AnimationController(vsync: this, duration: widget.duration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _dismiss();
            }
          });

    _fadeAnimation = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.30), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _enterController,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeIn,
          ),
        );

    _enterController.forward();
    _timerController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;

    await _enterController.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top + 10;
    final statusColor = widget.success
        ? const Color(0xFF3BE38E)
        : Colors.redAccent;
    final hasAction = widget.actionLabel != null && widget.onAction != null;

    return Positioned(
      top: topInset,
      left: 18,
      right: 18,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 12, 14, 10),
                        decoration: BoxDecoration(
                          color: const Color(0xE6141414),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white24, width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55000000),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: statusColor.withValues(
                                          alpha: 0.6,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.message,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                                if (hasAction)
                                  TextButton(
                                    onPressed: () {
                                      widget.onAction?.call();
                                      _dismiss();
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFFFFA21D),
                                      minimumSize: const Size(40, 30),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: Text(widget.actionLabel!),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Container(color: Colors.white12),
                                    AnimatedBuilder(
                                      animation: _timerController,
                                      builder: (context, child) {
                                        return Align(
                                          alignment: Alignment.centerRight,
                                          child: FractionallySizedBox(
                                            widthFactor: _timerController.value,
                                            child: Container(
                                              color: const Color(0xFFFF8A00),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
