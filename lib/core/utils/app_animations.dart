import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Types of route transitions
enum RouteTransitionType {
  fade,
  scale,
  slideLeft,
  slideRight,
  slideUp,
  slideDown,
  fadeSlide,
}

/// Types of staggered animations
enum StaggeredAnimationType {
  fade,
  scale,
  slide,
  fadeSlide,
}

/// Standardized Animation System for Consistent UI Transitions
/// 
/// Provides pre-configured animations and transitions that follow
/// Material Design guidelines and ensure consistent user experience.
class AppAnimations {
  // Standard durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration extraSlow = Duration(milliseconds: 800);
  
  // Standard curves
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticIn = Curves.elasticIn;
  static const Curve elasticOut = Curves.elasticOut;
  
  /// Fade transition animation
  static Widget fadeTransition({
    required Widget child,
    required Animation<double> animation,
    Duration duration = medium,
    Curve curve = easeInOut,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: curve),
      child: child,
    );
  }
  
  /// Scale transition animation
  static Widget scaleTransition({
    required Widget child,
    required Animation<double> animation,
    Duration duration = medium,
    Curve curve = elasticOut,
    Alignment alignment = Alignment.center,
  }) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: animation, curve: curve),
      alignment: alignment,
      child: child,
    );
  }
  
  /// Slide transition animation
  static Widget slideTransition({
    required Widget child,
    required Animation<double> animation,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    Duration duration = medium,
    Curve curve = easeInOut,
  }) {
    return SlideTransition(
      position: Tween<Offset>(begin: begin, end: end).animate(
        CurvedAnimation(parent: animation, curve: curve),
      ),
      child: child,
    );
  }
  
  /// Combined fade + slide transition
  static Widget fadeSlideTransition({
    required Widget child,
    required Animation<double> animation,
    Offset begin = const Offset(0.3, 0.0),
    Offset end = Offset.zero,
    Duration duration = medium,
    Curve curve = easeInOut,
  }) {
    return SlideTransition(
      position: Tween<Offset>(begin: begin, end: end).animate(
        CurvedAnimation(parent: animation, curve: curve),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: curve),
        child: child,
      ),
    );
  }
  
  /// Page route transition
  static PageRouteBuilder<T> createRoute<T>({
    required Widget page,
    RouteTransitionType type = RouteTransitionType.fadeSlide,
    Duration duration = medium,
    Curve curve = easeInOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (type) {
          case RouteTransitionType.fade:
            return fadeTransition(child: child, animation: animation, curve: curve);
          case RouteTransitionType.scale:
            return scaleTransition(child: child, animation: animation, curve: curve);
          case RouteTransitionType.slideLeft:
            return slideTransition(
              child: child,
              animation: animation,
              begin: const Offset(1.0, 0.0),
              curve: curve,
            );
          case RouteTransitionType.slideRight:
            return slideTransition(
              child: child,
              animation: animation,
              begin: const Offset(-1.0, 0.0),
              curve: curve,
            );
          case RouteTransitionType.slideUp:
            return slideTransition(
              child: child,
              animation: animation,
              begin: const Offset(0.0, 1.0),
              curve: curve,
            );
          case RouteTransitionType.slideDown:
            return slideTransition(
              child: child,
              animation: animation,
              begin: const Offset(0.0, -1.0),
              curve: curve,
            );
          case RouteTransitionType.fadeSlide:
            return fadeSlideTransition(child: child, animation: animation, curve: curve);
        }
      },
    );
  }

  /// Create a Page for GoRouter with custom transitions
  static Page<T> createPage<T>({
    required Widget child,
    required String name,
    Object? arguments,
    RouteTransitionType type = RouteTransitionType.fadeSlide,
    Duration duration = medium,
    Curve curve = easeInOut,
    String? restorationId,
  }) {
    return CustomTransitionPage<T>(
      key: ValueKey(name),
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      child: child,
      transitionType: type,
      transitionDuration: duration,
      transitionCurve: curve,
    );
  }

  /// Helper for GoRouter pageBuilder that applies animations
  static Page<T> animatedPageBuilder<T>(
    BuildContext context,
    GoRouterState state,
    Widget child, {
    RouteTransitionType type = RouteTransitionType.fadeSlide,
    Duration duration = medium,
    Curve curve = easeInOut,
  }) {
    return createPage<T>(
      child: child,
      name: state.matchedLocation,
      arguments: state.extra,
      type: type,
      duration: duration,
      curve: curve,
      restorationId: state.matchedLocation,
    );
  }
}

/// Custom Page implementation for GoRouter that supports AppAnimations
class CustomTransitionPage<T> extends Page<T> {
  const CustomTransitionPage({
    required this.child,
    required this.transitionType,
    this.transitionDuration = AppAnimations.medium,
    this.transitionCurve = AppAnimations.easeInOut,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final RouteTransitionType transitionType;
  final Duration transitionDuration;
  final Curve transitionCurve;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: transitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (transitionType) {
          case RouteTransitionType.fade:
            return AppAnimations.fadeTransition(
              child: child,
              animation: animation,
              curve: transitionCurve,
            );
          case RouteTransitionType.scale:
            return AppAnimations.scaleTransition(
              child: child,
              animation: animation,
              curve: transitionCurve,
            );
          case RouteTransitionType.slideLeft:
            return AppAnimations.slideTransition(
              child: child,
              animation: animation,
              begin: const Offset(1.0, 0.0),
              curve: transitionCurve,
            );
          case RouteTransitionType.slideRight:
            return AppAnimations.slideTransition(
              child: child,
              animation: animation,
              begin: const Offset(-1.0, 0.0),
              curve: transitionCurve,
            );
          case RouteTransitionType.slideUp:
            return AppAnimations.slideTransition(
              child: child,
              animation: animation,
              begin: const Offset(0.0, 1.0),
              curve: transitionCurve,
            );
          case RouteTransitionType.slideDown:
            return AppAnimations.slideTransition(
              child: child,
              animation: animation,
              begin: const Offset(0.0, -1.0),
              curve: transitionCurve,
            );
          case RouteTransitionType.fadeSlide:
            return AppAnimations.fadeSlideTransition(
              child: child,
              animation: animation,
              curve: transitionCurve,
            );
        }
      },
    );
  }
}

/// Animated container with easy configuration
class AnimatedAppContainer extends StatefulWidget {
  const AnimatedAppContainer({
    super.key,
    required this.child,
    this.duration = AppAnimations.medium,
    this.curve = AppAnimations.easeInOut,
    this.animateOnInit = true,
    this.padding,
    this.margin,
    this.decoration,
    this.width,
    this.height,
    this.alignment,
  });
  
  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool animateOnInit;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  
  @override
  State<AnimatedAppContainer> createState() => _AnimatedAppContainerState();
}

class _AnimatedAppContainerState extends State<AnimatedAppContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    
    if (widget.animateOnInit) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _animation.value),
          child: Opacity(
            opacity: _animation.value,
            child: AnimatedContainer(
              duration: widget.duration,
              curve: widget.curve,
              padding: widget.padding,
              margin: widget.margin,
              decoration: widget.decoration,
              width: widget.width,
              height: widget.height,
              alignment: widget.alignment,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Staggered animation helper for lists
class StaggeredAnimationHelper {
  static List<Widget> createStaggeredList({
    required List<Widget> children,
    Duration itemDelay = const Duration(milliseconds: 100),
    Duration itemDuration = AppAnimations.medium,
    Curve curve = AppAnimations.easeInOut,
    StaggeredAnimationType type = StaggeredAnimationType.fadeSlide,
  }) {
    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      final delay = itemDelay * index;
      
      return StaggeredAnimationWidget(
        delay: delay,
        duration: itemDuration,
        curve: curve,
        type: type,
        child: child,
      );
    }).toList();
  }
}

/// Individual staggered animation widget
class StaggeredAnimationWidget extends StatefulWidget {
  const StaggeredAnimationWidget({
    super.key,
    required this.child,
    required this.delay,
    this.duration = AppAnimations.medium,
    this.curve = AppAnimations.easeInOut,
    this.type = StaggeredAnimationType.fadeSlide,
  });
  
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final StaggeredAnimationType type;
  
  @override
  State<StaggeredAnimationWidget> createState() => _StaggeredAnimationWidgetState();
}

class _StaggeredAnimationWidgetState extends State<StaggeredAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(_animation);
    
    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case StaggeredAnimationType.fade:
        return FadeTransition(
          opacity: _animation,
          child: widget.child,
        );
      case StaggeredAnimationType.scale:
        return ScaleTransition(
          scale: _animation,
          child: widget.child,
        );
      case StaggeredAnimationType.slide:
        return SlideTransition(
          position: _slideAnimation,
          child: widget.child,
        );
      case StaggeredAnimationType.fadeSlide:
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _animation,
            child: widget.child,
          ),
        );
    }
  }
}

/// Hero animation helper
class AppHeroHelper {
  /// Create a hero widget with enhanced animations
  static Widget createHero({
    required String tag,
    required Widget child,
    Duration transitionDuration = const Duration(milliseconds: 400),
    CreateRectTween? createRectTween,
  }) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      createRectTween: createRectTween ?? (begin, end) {
        return RectTween(begin: begin, end: end);
      },
      child: child,
    );
  }
  
  /// Create a hero animation for images
  static Widget createImageHero({
    required String tag,
    required Widget image,
    Duration transitionDuration = const Duration(milliseconds: 400),
  }) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      child: Material(
        type: MaterialType.transparency,
        child: image,
      ),
    );
  }
}

/// Mixin for widgets that need animation capabilities
mixin AnimationMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;
  late Animation<Offset> slideAnimation;
  
  @override
  void initState() {
    super.initState();
    setupAnimations();
  }
  
  void setupAnimations({
    Duration duration = AppAnimations.medium,
    Curve curve = AppAnimations.easeInOut,
  }) {
    animationController = AnimationController(duration: duration, vsync: this);
    
    fadeAnimation = CurvedAnimation(parent: animationController, curve: curve);
    scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(fadeAnimation);
    slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(fadeAnimation);
  }
  
  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
  
  void startAnimation() => animationController.forward();
  void reverseAnimation() => animationController.reverse();
  void resetAnimation() => animationController.reset();
  void stopAnimation() => animationController.stop();
}
