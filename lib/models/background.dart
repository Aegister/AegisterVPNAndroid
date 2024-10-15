import 'dart:ui';
import 'package:flutter/material.dart';

class BackgroundLogo extends StatelessWidget {
  final Widget child;
  final String logoPath;
  final double blurStrength;
  final double opacity;
  final double offsetX;

  BackgroundLogo({
    required this.child,
    required this.logoPath,
    this.blurStrength = 5.0,
    this.opacity = 0.1,
    this.offsetX = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(offsetX, 0),
                child: Image.asset(
                  logoPath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
            child: Container(
              color: Colors.black.withOpacity(0.05),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
