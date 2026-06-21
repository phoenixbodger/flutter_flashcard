import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';

/// Study mode screen that reviews flashcards with a front/back flip interface.
class ReviewCardsStudyScreen extends StatefulWidget {
  final List<Flashcard<String>> cards;
  
  const ReviewCardsStudyScreen({
    super.key,
    required this.cards,
  });

  @override
  State<ReviewCardsStudyScreen> createState() => _ReviewCardsStudyScreenState();
}

class _ReviewCardsStudyScreenState extends State<ReviewCardsStudyScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false;
  int _currentSideIndex = 0;

  void _toggleCardSide() {
    setState(() {
      if (_showAnswer) {
        _showAnswer = false;
        _currentSideIndex = 0;
      } else {
        _showAnswer = true;
        // Show the last side (answer) by default
        _currentSideIndex = widget.cards[_currentIndex].sides.length - 1;
      }
    });
  }

  void _nextCard() {
    setState(() {
      if (_currentIndex < widget.cards.length - 1) {
        _currentIndex++;
        _showAnswer = false;
        _currentSideIndex = 0;
      }
    });
  }

  void _previousCard() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        _showAnswer = false;
        _currentSideIndex = 0;
      }
    });
  }

  void _nextSide() {
    setState(() {
      final maxSideIndex = widget.cards[_currentIndex].sides.length - 1;
      if (_currentSideIndex < maxSideIndex) {
        _currentSideIndex++;
      }
    });
  }

  void _previousSide() {
    setState(() {
      if (_currentSideIndex > 0) {
        _currentSideIndex--;
      }
    });
  }

  String _getCurrentSideText() {
    final flashCard = widget.cards[_currentIndex];
    if (_showAnswer && flashCard.sides.length > 1) {
      // When showing answer, display all sides stacked vertically
      return flashCard.sides.skip(1).join('\n\n');
    }
    return flashCard.sides[_currentSideIndex];
  }

  int _getTotalSides() {
    return widget.cards[_currentIndex].sides.length;
  }

  @override
  Widget build(BuildContext context) {
    final flashCard = widget.cards[_currentIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Cards Study'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.cards.length,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
          Expanded(
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: const [Colors.white, Color(0xFFFAFAFA)],
                    ),
                  ),
                  child: InkWell(
                    onTap: _showAnswer ? null : _toggleCardSide,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: SingleChildScrollView(
                          child: Text(
                            _showAnswer 
                                ? flashCard.sides.skip(1).join('\n\n')
                                : flashCard.sides[0],
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          

          
          // Side navigation indicator for multi-side flashcards
          if (_getTotalSides() > 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  _getTotalSides(),
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentSideIndex
                          ? Colors.purple.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
          if (_getTotalSides() > 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _showAnswer
                    ? 'Part ${_currentSideIndex + 1} of ${widget.cards[_currentIndex].sides.length}'
                    : 'Part ${_currentSideIndex + 1} of $_getTotalSides()',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          // Stroke order visualization for Chinese characters
          if (flashCard.strokeOrder != null && flashCard.strokeOrder!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const Text(
                    'Stroke Order Preview:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: _buildStrokeOrderPreview(flashCard.strokeOrder!),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: _currentIndex > 0 ? _previousCard : null,
              icon: const Icon(Icons.first_page),
              color: Colors.purple,
            ),
            IconButton(
              onPressed: _currentIndex < widget.cards.length - 1 ? _nextCard : null,
              icon: const Icon(Icons.last_page),
              color: Colors.purple,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_currentIndex + 1} / ${widget.cards.length}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.purple),
                ),
                if (_getTotalSides() > 2)
                  Text(
                    _showAnswer
                        ? 'Answer ${_currentSideIndex + 1}/${widget.cards[_currentIndex].sides.length - 1}'
                        : 'Part ${_currentSideIndex + 1}/$_getTotalSides()',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
            IconButton(
              onPressed: _showAnswer && _currentSideIndex < widget.cards[_currentIndex].sides.length - 2 
                  ? _nextSide 
                  : null,
              icon: const Icon(Icons.arrow_forward),
              color: Colors.purple,
            ),
            IconButton(
              onPressed: _showAnswer && _currentSideIndex > 0 
                  ? _previousSide 
                  : (_currentSideIndex > 0 && !_showAnswer ? _previousSide : null),
              icon: const Icon(Icons.arrow_back),
              color: Colors.purple,
            ),
            IconButton(
              onPressed: _toggleCardSide,
              icon: Icon(_showAnswer ? Icons.visibility : Icons.visibility_off),
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrokeOrderPreview(List<int> strokeOrder) {
    // Simple stroke order visualization without external dependency
    return CustomPaint(
      painter: StrokeOrderPainter(strokeOrder: strokeOrder),
      size: const Size(120, 120),
    );
  }
}

/// Custom painter for stroke order visualization
class StrokeOrderPainter extends CustomPainter {
  final List<int> strokeOrder;
  
  StrokeOrderPainter({required this.strokeOrder});

  @override
  void paint(Canvas canvas, Size size) {
    final paintStyle = Paint()
      ..color = Colors.purple.shade700
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final gridSize = 100.0;
    
    // Draw grid reference (subtle)
    final gridPaint = Paint()..color = Colors.grey.shade200;
    
    // Draw each stroke
    for (int i = 0; i < strokeOrder.length; i++) {
      // Simple visualization: draw strokes as numbered segments
      final double y = (i / (strokeOrder.length - 1 | 1)) * gridSize + (size.height - gridSize) / 2;
      
      canvas.drawLine(
        Offset(centerX - gridSize / 2, y),
        Offset(centerX + gridSize / 2, y),
        Paint()
          ..color = Colors.purple.shade700
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      
      // Draw stroke number
      if (i < 10) { // Only show numbers for single digit stroke orders
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.purple.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(centerX + gridSize / 2 + 4, y - 6));
      }
    }
  }

  @override
  bool shouldRepaint(covariant StrokeOrderPainter oldDelegate) {
    return strokeOrder != oldDelegate.strokeOrder;
  }
}