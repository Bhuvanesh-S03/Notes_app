// custom_transitions.dart
import 'package:flutter/material.dart';

class CustomNoteTransition extends PageRouteBuilder {
  final Widget page;

  CustomNoteTransition(this.page)
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Create a smooth fade and scale transition that masks any visual glitches
          final scaleTween = Tween<double>(begin: 0.85, end: 1.0);
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
          final overlayFadeTween = Tween<double>(begin: 0.3, end: 0.0);

          final scaleAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );

          final overlayAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );

          return Stack(
            children: [
              FadeTransition(
                opacity: fadeTween.animate(fadeAnimation),
                child: ScaleTransition(
                  scale: scaleTween.animate(scaleAnimation),
                  child: child,
                ),
              ),
              // Overlay to mask any visual artifacts during transition
              FadeTransition(
                opacity: overlayFadeTween.animate(overlayAnimation),
                child: Container(color: const Color(0xFF0A0D12)),
              ),
            ],
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
      );
}
