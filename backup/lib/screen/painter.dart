import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class WatchOverlayPainter extends CustomPainter {
  final ui.Image? watchImage;
  final List<double> wristPosition;
  final double wristWidth;
  final double angle;
  final Size previewSize;
  final double scaleFactor;
  final bool isHandDetected;

  WatchOverlayPainter(
    this.watchImage,
    this.wristPosition,
    this.wristWidth,
    this.angle,
    this.previewSize,
    this.isHandDetected, {
    this.scaleFactor = 0.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isHandDetected) {
      return;
    }
    if (wristPosition.length < 3) {
      print("Invalid wrist position data");
      return;
    }

    if(watchImage == null){
      print("Watch Image is null");
      return;
    }

    // Flip the x-coordinate
    double x = 1 - wristPosition[1];
    double y = 1 - wristPosition[0];

   
    // Scale the watch image based on wrist width
    final double watchWidth = wristWidth *
        size.width *
        scaleFactor; // Adjust scaling factor as needed
    final double watchHeight =
        watchWidth * watchImage!.height / watchImage!.width;

    final paint = Paint()..filterQuality = FilterQuality.high;

    canvas.save();

    // Translate to the center of where we want to draw the watch
    canvas.translate(x * size.width, y * size.height);

    // Rotate the canvas
    // Add 90 degrees to make the watch horizontal when wristAngle is 0
    double angleRadians = -angle * (math.pi / 180);
    canvas.rotate(angleRadians);

    // Apply vertical flip
    canvas.scale(-1,1);
    canvas.scale(1,-1);

    canvas.drawImageRect(
      watchImage!,
      Rect.fromLTWH(
          0, 0, watchImage!.width.toDouble(), watchImage!.height.toDouble()),
      Rect.fromCenter(
          center: Offset.zero, width: watchWidth, height: watchHeight),
      paint,
    );

    // Restore the canvas state
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}