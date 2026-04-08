part of fsanimations;

enum SlideFromSlide { top, bottom, left, right }

class ShowUpTransition extends StatefulWidget {
  /// [child] to be Animated
  final Widget child;

  /// Animation Duration, default is 200 Milliseconds
  final Duration? duration;

  /// Delay before starting Animation, default is Zero
  final Duration? delay;

  /// Bring forward/reverse the Animation
  final bool forward;

  /// From which direction start the [Slide] animation
  final SlideFromSlide slideSide;

  const ShowUpTransition(
      {Key? key,
      required this.child,
      this.duration,
      this.delay,
      this.slideSide = SlideFromSlide.left,
      required this.forward})
      : super(key: key);

  @override
  ShowUpTransitionState createState() => ShowUpTransitionState();
}

class ShowUpTransitionState extends State<ShowUpTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _animOffset;

  List<Offset> slideSides = [
    const Offset(-0.35, 0), // LEFT
    const Offset(0.35, 0), // RIGHT
    const Offset(0, 0.35), // BOTTOM
    const Offset(0, -0.35), // TOP
  ];
  Offset? selectedSlide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this,
        duration: widget.duration ?? const Duration(milliseconds: 400));
    switch (widget.slideSide) {
      case SlideFromSlide.left:
        selectedSlide = slideSides[0];
        break;
      case SlideFromSlide.right:
        selectedSlide = slideSides[1];
        break;
      case SlideFromSlide.bottom:
        selectedSlide = slideSides[2];
        break;
      case SlideFromSlide.top:
        selectedSlide = slideSides[3];
        break;
    }
    _animOffset = Tween<Offset>(begin: selectedSlide, end: Offset.zero).animate(
        CurvedAnimation(
            curve: Curves.fastLinearToSlowEaseIn, parent: _animController));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Timer(widget.delay ?? Duration.zero, () {
      if (widget.forward) {
        if (mounted) _animController.forward();
      } else {
        if (mounted) _animController.reverse();
      }
    });
    return widget.forward
        ? FadeTransition(
            opacity: _animController,
            child: SlideTransition(
              position: _animOffset,
              child: widget.child,
            ),
          )
        : Container();
  }
}
