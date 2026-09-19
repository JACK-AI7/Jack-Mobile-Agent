// lib/widgets/gradient_border.dart
import 'package:flutter/material.dart';

/// Rounded pill gradient border — for buttons.
class GradientRoundedBorder extends BoxBorder {
  const GradientRoundedBorder(
      {required this.gradient, required this.width, this.radius = 50.0});

  final Gradient gradient;
  final double   width;
  final double   radius;

  @override BorderSide get bottom   => BorderSide.none;
  @override BorderSide get top      => BorderSide.none;
  @override EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);
  @override bool get isUniform      => true;

  @override
  void paint(Canvas canvas, Rect rect,
      {TextDirection? textDirection,
      BoxShape shape = BoxShape.rectangle,
      BorderRadius? borderRadius}) {
    canvas.drawPath(
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius))),
      Paint()
        ..shader     = gradient.createShader(rect)
        ..strokeWidth = width
        ..style      = PaintingStyle.stroke,
    );
  }

  @override ShapeBorder scale(double t) => this;
}

/// Full-rect gradient border — for the screen-edge glow.
class GradientRectBorder extends BoxBorder {
  const GradientRectBorder({required this.gradient, required this.width});

  final Gradient gradient;
  final double   width;

  @override BorderSide get bottom   => BorderSide.none;
  @override BorderSide get top      => BorderSide.none;
  @override EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);
  @override bool get isUniform      => true;

  @override
  void paint(Canvas canvas, Rect rect,
      {TextDirection? textDirection,
      BoxShape shape = BoxShape.rectangle,
      BorderRadius? borderRadius}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(width / 2), const Radius.circular(40)),
      Paint()
        ..shader     = gradient.createShader(rect)
        ..strokeWidth = width
        ..style      = PaintingStyle.stroke,
    );
  }

  @override ShapeBorder scale(double t) => this;
}
