/// Individual puzzle piece representation in a 3x3 jigsaw grid.
class PuzzlePiece {
  final int originalIndex; // 0..8
  final int currentIndex; // 0..8

  const PuzzlePiece({
    required this.originalIndex,
    required this.currentIndex,
  });

  int get originalRow => originalIndex ~/ 3;
  int get originalCol => originalIndex % 3;
  int get currentRow => currentIndex ~/ 3;
  int get currentCol => currentIndex % 3;

  bool get isCorrect => originalIndex == currentIndex;
}

/// The state of an active jigsaw puzzle session.
class PuzzleState {
  final String imageAsset;
  final List<int> pieces; // List of 9 integers, pieces[slot] = originalPieceId (0..8)
  final int? selectedSlot; // Currently highlighted piece slot index (0..8) or null
  final int moves;
  final bool isCompleted;

  const PuzzleState({
    required this.imageAsset,
    required this.pieces,
    this.selectedSlot,
    this.moves = 0,
    this.isCompleted = false,
  });

  /// Check if every single piece is in its matching target position (0..8)
  bool get isSolved {
    if (pieces.length != 9) return false;
    for (int i = 0; i < 9; i++) {
      if (pieces[i] != i) return false;
    }
    return true;
  }

  /// Number of pieces correctly positioned (0 to 9)
  int get correctCount {
    int count = 0;
    for (int i = 0; i < pieces.length && i < 9; i++) {
      if (pieces[i] == i) count++;
    }
    return count;
  }

  PuzzleState copyWith({
    String? imageAsset,
    List<int>? pieces,
    int? selectedSlot,
    bool clearSelection = false,
    int? moves,
    bool? isCompleted,
  }) {
    return PuzzleState(
      imageAsset: imageAsset ?? this.imageAsset,
      pieces: pieces ?? List<int>.from(this.pieces),
      selectedSlot: clearSelection ? null : (selectedSlot ?? this.selectedSlot),
      moves: moves ?? this.moves,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
