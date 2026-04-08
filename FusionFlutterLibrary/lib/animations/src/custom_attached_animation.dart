part of fsanimations;

class CustomAttachedAnimation extends StatefulWidget {
  final AnimationController? controller;
  final Widget? child;

  const CustomAttachedAnimation({Key? key, this.controller, this.child})
      : super(key: key);

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
