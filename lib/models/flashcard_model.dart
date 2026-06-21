/// A robust, general-purpose flashcard model.
/// 'T' can be anything: String, Image path, or even a custom Object.
class Flashcard<T> {
  final String id;
  
  // Using a List makes the card "n-sided" (2, 3, 4+ sides).
  final List<T> sides;

  // Metadata for the AI or the UI to know what kind of card this is.
  final String category; // e.g., "Japanese", "Medicine", "Math"
  
  // Optional headers for displaying side labels
  final List<String>? headers;
  
  // Stroke order data for Chinese characters
  final List<int>? strokeOrder;

  Flashcard({
    required this.id,
    required this.sides,
    this.category = "General",
    this.headers,
    this.strokeOrder,
  });
}

/// Helper class to generate stroke order data for Chinese characters
class StrokeOrderHelper {
  /// Get stroke order for a Chinese character (simplified implementation)
  /// In a real application, this would use a proper Chinese character database
  static List<int> getStrokeOrder(String character) {
    // This is a placeholder - in reality, you'd want to use a proper stroke order database
    // For now, return an empty list or a default pattern for demonstration
    
    // Simple heuristic: if it's a Chinese character (CJK Unified Ideographs)
    if (character.codeUnits.isNotEmpty && 
        character.codeUnits[0] >= 0x4E00 && 
        character.codeUnits[0] <= 0x9FFF) {
      // Return a default stroke order pattern for demonstration purposes
      // In a real implementation, this would return the actual stroke order from a database
      return [1, 2, 3, 4, 5]; // Default example - real implementation needed
    }
    
    // Return empty list for non-Chinese characters
    return [];
  }
}

/// A Deck is simply a collection of these generic cards.
class Deck<T> {
  String title;
  List<Flashcard<T>> cards;
  
  // Optional headers for the entire deck
  final List<String>? headers;

  Deck({required this.title, required this.cards, this.headers});
}

/// String-specific Flashcard for CSV and Local Storage
class FlashcardString {
  final String id;
  final List<String> sides;
  final String category;
  final List<String>? headers;
  final List<int>? strokeOrder;

  FlashcardString({
    required this.id,
    required this.sides,
    this.category = "General",
    this.headers,
    this.strokeOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sides': sides,
      'category': category,
      'headers': headers,
      'strokeOrder': strokeOrder,
    };
  }

  factory FlashcardString.fromJson(Map<String, dynamic> json) {
    return FlashcardString(
      id: json['id'],
      sides: List<String>.from(json['sides']),
      category: json['category'] ?? 'General',
      headers: json['headers'] != null ? List<String>.from(json['headers']) : null,
      strokeOrder: json['strokeOrder'] != null ? List<int>.from(json['strokeOrder']) : null,
    );
  }
}

/// String-specific Deck for CSV and Local Storage
class DeckString {
  String title;
  List<FlashcardString> cards;
  final List<String>? headers;

  DeckString({required this.title, required this.cards, this.headers});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'cards': cards.map((card) => card.toJson()).toList(),
      'headers': headers,
    };
  }

  factory DeckString.fromJson(Map<String, dynamic> json) {
    return DeckString(
      title: json['title'],
      cards: (json['cards'] as List<dynamic>)
          .map((cardJson) => FlashcardString.fromJson(cardJson))
          .toList(),
      headers: json['headers'] != null ? List<String>.from(json['headers']) : null,
    );
  }

  // Convert from generic Deck to DeckString
  factory DeckString.fromGenericDeck(Deck deck) {
    return DeckString(
      title: deck.title,
      cards: deck.cards.map((card) => FlashcardString(
        id: card.id,
        sides: card.sides.map((side) => side.toString()).toList(),
        category: card.category,
        headers: card.headers,
      )).toList(),
      headers: deck.headers,
    );
  }

  // Convert to generic Deck
  Deck<String> toGenericDeck() {
    return Deck<String>(
      title: title,
      cards: cards.map((card) => Flashcard<String>(
        id: card.id,
        sides: card.sides,
        category: card.category,
        headers: card.headers,
      )).toList(),
      headers: headers,
    );
  }
}