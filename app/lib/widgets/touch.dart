import 'package:app/theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class Touch extends StatefulWidget {
  const Touch({
    super.key,
    this.child,
    this.onTap,
  });

  final Widget? child;
  final VoidCallback? onTap;

  @override
  State<Touch> createState() => _TouchState();
}

class _TouchState extends State<Touch> {
  bool isDown = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap != null ? handleTapDown : null,
      onTapCancel: handleTapCancel,
      onTapUp: handleTapUp,
      child: AnimatedContainer(
        duration: kAnimation,
        transform: Matrix4.identity()..scale(isDown ? 1.005 : 1.0),
        transformAlignment: Alignment.center,
        child: AnimatedOpacity(
          opacity: isDown ? 0.8 : 1,
          duration: kAnimation,
          child: widget.child,
        ),
      ),
    );
  }

  void handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    isDown = true;
    setState(() {});
  }

  void handleTapCancel() {
    isDown = false;
    setState(() {});
  }

  void handleTapUp(TapUpDetails details) => handleTapCancel();
}
