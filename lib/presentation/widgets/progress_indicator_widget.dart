import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/colors_const.dart';
import '../../core/constants/text_style_const.dart';

/// Custom progress indicator widgets with black theme
class AppProgressIndicator extends StatelessWidget {
  const AppProgressIndicator({
    super.key,
    this.message,
    this.size = 24.0,
    this.strokeWidth = 3.0,
    this.color = ColorsConst.accentBlue,
    this.showMessage = true,
  });

  final String? message;
  final double size;
  final double strokeWidth;
  final Color color;
  final bool showMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            color: color,
            strokeWidth: strokeWidth,
          ),
        ),
        if (showMessage && message != null) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            style: TextStyleConst.bodyMedium.copyWith(
              color: ColorsConst.darkTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Linear progress indicator with custom styling
class AppLinearProgressIndicator extends StatelessWidget {
  const AppLinearProgressIndicator({
    super.key,
    this.value,
    this.backgroundColor = ColorsConst.borderMuted,
    this.valueColor = ColorsConst.accentBlue,
    this.height = 4.0,
    this.borderRadius = 2.0,
    this.showPercentage = false,
    this.message,
  });

  final double? value;
  final Color backgroundColor;
  final Color valueColor;
  final double height;
  final double borderRadius;
  final bool showPercentage;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message != null) ...[
          Text(
            message!,
            style: TextStyleConst.bodyMedium.copyWith(
              color: ColorsConst.darkTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value ?? 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: valueColor,
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                ),
              ),
            ),
            if (showPercentage && value != null) ...[
              const SizedBox(width: 8),
              Text(
                '${(value! * 100).toInt()}%',
                style: TextStyleConst.caption.copyWith(
                  color: ColorsConst.darkTextSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Shimmer loading placeholder
class AppShimmerLoading extends StatelessWidget {
  const AppShimmerLoading({
    super.key,
    required this.child,
    this.baseColor = ColorsConst.darkElevated,
    this.highlightColor = ColorsConst.darkCard,
    this.enabled = true,
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

/// Content card shimmer placeholder
class ContentCardShimmer extends StatelessWidget {
  const ContentCardShimmer({
    super.key,
    this.aspectRatio = 0.7,
  });

  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AppShimmerLoading(
      child: Card(
        color: ColorsConst.darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: ColorsConst.darkElevated,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
              ),

              // Content placeholder
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title placeholder
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: ColorsConst.darkElevated,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Container(
                        height: 14,
                        width: 120,
                        decoration: BoxDecoration(
                          color: ColorsConst.darkElevated,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Artist placeholder
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: ColorsConst.darkElevated,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      const Spacer(),

                      // Bottom row placeholder
                      Row(
                        children: [
                          Container(
                            height: 10,
                            width: 40,
                            decoration: BoxDecoration(
                              color: ColorsConst.darkElevated,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            height: 16,
                            width: 24,
                            decoration: BoxDecoration(
                              color: ColorsConst.darkElevated,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid shimmer loading
class ContentGridShimmer extends StatelessWidget {
  const ContentGridShimmer({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.aspectRatio = 0.7,
  });

  final int itemCount;
  final int crossAxisCount;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => ContentCardShimmer(
        aspectRatio: aspectRatio,
      ),
    );
  }
}

/// Pulsing dot indicator
class PulsingDotIndicator extends StatefulWidget {
  const PulsingDotIndicator({
    super.key,
    this.color = ColorsConst.accentBlue,
    this.size = 8.0,
    this.dotCount = 3,
  });

  final Color color;
  final double size;
  final int dotCount;

  @override
  State<PulsingDotIndicator> createState() => _PulsingDotIndicatorState();
}

class _PulsingDotIndicatorState extends State<PulsingDotIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.dotCount,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.dotCount, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.2),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withValues(
                  alpha: 0.3 + (0.7 * _animations[index].value),
                ),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

/// Skeleton loading for text
class TextSkeleton extends StatelessWidget {
  const TextSkeleton({
    super.key,
    this.width,
    this.height = 14.0,
    this.borderRadius = 4.0,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AppShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: ColorsConst.darkElevated,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Loading overlay widget
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
  });

  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: (backgroundColor ?? ColorsConst.darkBackground)
                .withValues(alpha: 0.7),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: ColorsConst.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: ColorsConst.darkBackground.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AppProgressIndicator(
                  message: message ?? 'Loading...',
                  size: 32,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
