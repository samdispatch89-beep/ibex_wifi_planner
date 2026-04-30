import 'package:flutter/material.dart';

class AnimatedPageSwitcher extends StatelessWidget {
  const AnimatedPageSwitcher({
    super.key,
    required this.child,
    required this.transitionKey,
  });

  final Widget child;
  final Object transitionKey;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(fade);

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey<Object>(transitionKey), child: child),
    );
  }
}

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 320),
    this.offsetY = 12,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration + delay,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        final delayedProgress = delay == Duration.zero
            ? value
            : ((value * duration.inMilliseconds + delay.inMilliseconds) /
                          (duration.inMilliseconds + delay.inMilliseconds) -
                      (delay.inMilliseconds /
                          (duration.inMilliseconds + delay.inMilliseconds)))
                  .clamp(0.0, 1.0);

        return Opacity(
          opacity: delayedProgress,
          child: Transform.translate(
            offset: Offset(0, (1 - delayedProgress) * offsetY),
            child: child,
          ),
        );
      },
    );
  }
}

class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.enableHover = true,
    this.hoverOffset = -4,
    this.hoverShadow = const [
      BoxShadow(
        color: Color(0x12000000),
        blurRadius: 18,
        offset: Offset(0, 10),
      ),
    ],
  });

  final Widget child;
  final double borderRadius;
  final bool enableHover;
  final double hoverOffset;
  final List<BoxShadow> hoverShadow;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final shouldHover = widget.enableHover;

    return MouseRegion(
      onEnter: shouldHover ? (_) => setState(() => _hovered = true) : null,
      onExit: shouldHover ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          0,
          _hovered && shouldHover ? widget.hoverOffset : 0,
          0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _hovered && shouldHover ? widget.hoverShadow : const [],
        ),
        child: widget.child,
      ),
    );
  }
}

class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
