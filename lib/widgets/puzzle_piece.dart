import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Renders a single 3x3 jigsaw tile sliced from the main image asset.
class PuzzlePieceWidget extends StatelessWidget {
  final int originalIndex; // 0..8 (determines which 1/3 slice of image to show)
  final int currentSlot; // 0..8 (determines where on the board it is placed)
  final String imageAsset;
  final bool isSelected;
  final bool isSolved;
  final VoidCallback onTap;

  const PuzzlePieceWidget({
    super.key,
    required this.originalIndex,
    required this.currentSlot,
    required this.imageAsset,
    required this.isSelected,
    required this.isSolved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final origRow = originalIndex ~/ 3; // 0, 1, 2
    final origCol = originalIndex % 3; // 0, 1, 2
    final isCorrect = originalIndex == currentSlot;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.diagonal3Values(
          isSelected ? 1.05 : 1.0,
          isSelected ? 1.05 : 1.0,
          1.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryAmber
                : (isCorrect && !isSolved
                    ? AppTheme.successGreen.withValues(alpha: 0.6)
                    : Colors.white24),
            width: isSelected ? 3.5 : (isCorrect && !isSolved ? 2.0 : 1.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Sliced Image Viewport
              LayoutBuilder(
                builder: (context, constraints) {
                  final pieceWidth = constraints.maxWidth;
                  final pieceHeight = constraints.maxHeight;
                  final fullWidth = pieceWidth * 3;
                  final fullHeight = pieceHeight * 3;

                  return OverflowBox(
                    maxWidth: fullWidth,
                    maxHeight: fullHeight,
                    alignment: Alignment.topLeft,
                    child: Transform.translate(
                      offset: Offset(-origCol * pieceWidth, -origRow * pieceHeight),
                      child: SizedBox(
                        width: fullWidth,
                        height: fullHeight,
                        child: Image.asset(
                          imageAsset,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Selection overlay
              if (isSelected)
                Container(
                  color: AppTheme.primaryAmber.withValues(alpha: 0.2),
                  child: const Center(
                    child: Icon(
                      Icons.touch_app,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

              // Correct placement subtle indicator
              if (isCorrect && !isSelected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
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
