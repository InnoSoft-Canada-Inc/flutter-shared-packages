part of '../fs_animations.dart';

class CustomAttachedAnimation extends StatefulWidget {
  final AnimationController? controller;
  final Widget? child;

  const CustomAttachedAnimation({super.key, this.controller, this.child});

  @override
  CustomAttachedAnimationState createState() => CustomAttachedAnimationState();
}

class CustomAttachedAnimationState extends State<CustomAttachedAnimation> {
  late Animation<double> animation;

  @override
  void initState() {
    animation =
        CurvedAnimation(parent: widget.controller!, curve: Curves.decelerate);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller!,
      builder: (BuildContext context, Widget? child) {
        return ClipRect(
          child: Align(
            heightFactor: animation.value,
            widthFactor: animation.value,
            child: Opacity(
              opacity: animation.value,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
