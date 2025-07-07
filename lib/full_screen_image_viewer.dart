import 'dart:io';
import 'package:flutter/material.dart';
import 'generated/l10n.dart';
import 'main.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String path;

  const FullScreenImageViewer({
    super.key,
    required this.path});

  void showFullScreenImage(Offset offset) {
    navigatorKey.currentState?.push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              FullScreenImageViewer(path: path),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var tween = Tween<double>(begin: 0.1, end: 1.0).chain(CurveTween(curve: Curves.easeInOut));
            var scaleAnimation = animation.drive(tween);

            return ScaleTransition(
              scale: scaleAnimation,
              alignment: Alignment(offset.dx/MediaQuery.of(context).size.width * 2 - 1 ,offset.dy / MediaQuery.of(context).size.height * 2 - 1),
              child: child,
            );
          },
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 6.0,
              child: Image.file(File(path)),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: S.current.close,
            ),
          ),
        ],
      ),
    );
  }
}
