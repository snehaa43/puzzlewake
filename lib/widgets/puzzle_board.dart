import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import '../theme/app_theme.dart';
import 'puzzle_piece.dart';

/// 3x3 Jigsaw puzzle board container.
class PuzzleBoard extends StatelessWidget {
  final PuzzleState state;
  final ValueChanged<int> onPieceTapped;

  const PuzzleBoard({
    super.key,
    required this.state,
    required this.onPieceTapped,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: state.isSolved
                ? AppTheme.successGreen
                : AppTheme.primaryAmber.withValues(alpha: 0.5),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (state.isSolved ? AppTheme.successGreen : AppTheme.primaryAmber)
                  .withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: 9,
          itemBuilder: (context, slotIndex) {
            final originalPieceId = state.pieces[slotIndex];
            final isSelected = state.selectedSlot == slotIndex;

            return PuzzlePieceWidget(
              originalIndex: originalPieceId,
              currentSlot: slotIndex,
              imageAsset: state.imageAsset,
              isSelected: isSelected,
              isSolved: state.isSolved,
              onTap: () => onPieceTapped(slotIndex),
            );
          },
        ),
      ),
    );
  }
}
