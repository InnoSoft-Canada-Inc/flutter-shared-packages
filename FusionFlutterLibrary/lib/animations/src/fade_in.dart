part of fsanimations;

class FadeInTransition extends StatefulWidget {
  /// [child] to be Animated
  final Widget child;

  /// Animation Duration, default is 200 Milliseconds
  final Duration? duration;

  /// Animation Curve, default is Linear
  final Curve? curve;

  /// Delay before starting Animation
  final Duration? delay;

  const FadeInTransition({
    Key? key,
    required this.child,
    this.duration,
    this.curve,
    this.delay,
  }) : super(key: key);

  @override
  FadeInTransitionState createState() => FadeInTransitionState();
}

class FadeInTransitionState extends State<FadeInTransition>
    with TickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this,
        duration: widget.duration ?? const Duration(milliseconds: 200));
    if (widget.delay == null) {
      _animController.forward();
    } else {
      Timer(widget.delay!, () {
        _animController.forward();
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: _animController,
          curve: widget.curve == null ? Curves.linear : widget.curve!),
      child: widget.child,
    );
  }
}
