import 'dart:math';
import '../models/puzzle.dart';

/// Service responsible for puzzle creation, random image selection, shuffling, piece swapping, and validation.
class PuzzleService {
  static const List<String> puzzleImages = [
    'assets/images/morning.jpg',
    'assets/images/coffee.jpg',
    'assets/images/nature.jpg',
    'assets/images/mountains.jpg',
    'assets/images/beach.jpg',
    'assets/images/city.jpg',
    'assets/images/flowers.jpg',
    'assets/images/sunrise.jpg',
  ];

  final Random _random = Random();
  String? _lastUsedImage;

  /// Selects a random morning image from the bundled set, prioritizing unseen images.
  String getRandomImage() {
    final available = puzzleImages.where((img) => img != _lastUsedImage).toList();
    final chosen = available.isNotEmpty
        ? available[_random.nextInt(available.length)]
        : puzzleImages[_random.nextInt(puzzleImages.length)];
    _lastUsedImage = chosen;
    return chosen;
  }

  /// Generates a new 3x3 puzzle state with a random image and shuffled pieces.
  PuzzleState createNewPuzzle({String? specificImage}) {
    final imageAsset = specificImage ?? getRandomImage();
    final shuffledPieces = generateShuffledPieces();

    return PuzzleState(
      imageAsset: imageAsset,
      pieces: shuffledPieces,
      selectedSlot: null,
      moves: 0,
      isCompleted: false,
    );
  }

  /// Generates a shuffled 3x3 permutation guaranteed not to be in the solved state [0..8].
  List<int> generateShuffledPieces() {
    final pieces = List<int>.generate(9, (i) => i);

    // Perform random pairwise swaps to ensure high entropy while keeping it fun
    int swapCount = 10 + _random.nextInt(8); // 10 to 17 swaps
    for (int i = 0; i < swapCount; i++) {
      final a = _random.nextInt(9);
      int b = _random.nextInt(9);
      while (b == a) {
        b = _random.nextInt(9);
      }
      final temp = pieces[a];
      pieces[a] = pieces[b];
      pieces[b] = temp;
    }

    // Ensure it's not accidentally solved
    if (checkSolved(pieces)) {
      final temp = pieces[0];
      pieces[0] = pieces[1];
      pieces[1] = temp;
    }

    return pieces;
  }

  /// Handles user tapping on a puzzle slot:
  /// - If no piece is selected, select the tapped slot.
  /// - If the tapped slot is already selected, unselect it.
  /// - If another slot was selected, swap the pieces and check if solved!
  PuzzleState handleSlotTap(PuzzleState state, int tappedSlot) {
    if (state.isCompleted) return state;

    final selected = state.selectedSlot;

    if (selected == null) {
      // First piece selection
      return state.copyWith(selectedSlot: tappedSlot);
    } else if (selected == tappedSlot) {
      // Tap again to unselect
      return state.copyWith(clearSelection: true);
    } else {
      // Swap piece at selected with piece at tappedSlot
      final newPieces = List<int>.from(state.pieces);
      final temp = newPieces[selected];
      newPieces[selected] = newPieces[tappedSlot];
      newPieces[tappedSlot] = temp;

      final isSolved = checkSolved(newPieces);

      return state.copyWith(
        pieces: newPieces,
        clearSelection: true,
        moves: state.moves + 1,
        isCompleted: isSolved,
      );
    }
  }

  /// Validates whether all 9 pieces are in their exact original positions:
  /// 0 1 2
  /// 3 4 5
  /// 6 7 8
  bool checkSolved(List<int> pieces) {
    if (pieces.length != 9) return false;
    for (int i = 0; i < 9; i++) {
      if (pieces[i] != i) return false;
    }
    return true;
  }
}
