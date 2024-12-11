import 'package:flutter/material.dart';

class BackgroundLogo extends StatelessWidget {
  final Widget child;
  final String logoPath;

  const BackgroundLogo({
    required this.child,
    required this.logoPath,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            logoPath,
            fit: BoxFit.cover,
          ),
        ),
        // Foreground child widget
        child,
      ],
    );
  }
}
