import 'package:flutter/material.dart';

/// A shimmering placeholder rectangle used while content is loading.
///
/// The shimmer loops indefinitely until the widget is removed from the tree.
class LoadingSkeleton extends StatefulWidget {
  /// Creates a [LoadingSkeleton].
  const LoadingSkeleton({
    super.key,
    this.height = 80,
    this.borderRadius = 12,
  });

  /// Height of the skeleton rectangle in logical pixels.
  final double height;

  /// Corner radius of the skeleton rectangle in logical pixels.
  final double borderRadius;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shimmer = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final shimmerColor = baseColor.withValues(alpha: 0.5);

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(widget.borderRadius),
              ),
              color: Color.lerp(baseColor, shimmerColor, _shimmer.value),
            ),
          );
        },
      ),
    );
  }
}
