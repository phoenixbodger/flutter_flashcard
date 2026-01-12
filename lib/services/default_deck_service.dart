import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import '../models/flashcard_model.dart';
import 'category_service.dart';

class DefaultDeckService {
  static const List<Map<String, String>> _defaultDecks = [
    {
      'name': 'Chinese Radicals',
      'file': 'assets/decks/Chinese_Radicals.csv',
      'description': 'List of Chinese Radicals and definitions'
    },
        {
      'name': 'Chinese Expressions for TV and Movies',
      'file': 'assets/decks/Expressions_for_TV_and_Movies.csv',
      'description': 'list of Chinese expressions for Tv and Movies'
    },
        {
      'name': 'Hiragana',
      'file': 'assets/decks/Hirigana.csv',
      'description': 'Japanese Hiragana characters'
    },
  ];

  static Future<void> loadDefaultDecks() async {
    try {
      print('🚀 Starting to load default decks...');
      
      // First ensure default category exists
      await CategoryService.initializeDefaultCategory();
      print('✅ Default category initialized');
      
      for (final deckInfo in _defaultDecks) {
        print('📦 Loading deck: ${deckInfo['name']} from ${deckInfo['file']}');
        
        try {
          final String csvContent = await rootBundle.loadString(deckInfo['file']!);
          print('✅ Successfully loaded ${deckInfo['file']} (${csvContent.length} chars)');
          
          final List<String> lines = csvContent.split('\n');
          print('📄 Found ${lines.length} lines in CSV');
          
          if (lines.isNotEmpty) {
            final List<String> headers = lines.first.split(',');
            final List<Flashcard<String>> flashcards = [];
            
            for (int i = 1; i < lines.length; i++) {
              final line = lines[i].trim();
              if (line.isNotEmpty) {
                final List<String> sides = line.split(',');
                if (sides.length >= 2) {
                  flashcards.add(Flashcard<String>(
                    id: 'default_${deckInfo['name']}_$i',
                    sides: sides.map((side) => side.trim()).toList(),
                  ));
                }
              }
            }
            
            print('🃏 Created ${flashcards.length} flashcards');
            
            if (flashcards.isNotEmpty) {
              final deck = Deck<String>(
                title: deckInfo['name']!,
                cards: flashcards,
                headers: headers,
              );
              
              // Save to localStorage using existing service
              await _saveDeckToStorage(deck);
              print('💾 Saved deck "${deck.title}" to storage');
              
              // Add deck to default category
              await CategoryService.addDeckToCategory(deck.title, 'default');
              print('📁 Added deck "${deck.title}" to default category');
            }
          }
        } catch (e) {
          print('❌ Error loading deck ${deckInfo['name']}: $e');
          continue;
        }
      }
      
      print('✅ Finished loading default decks');
    } catch (e) {
      print('❌ Error loading default decks: $e');
    }
  }

  static Future<void> _saveDeckToStorage(Deck<String> deck) async {
    try {
      // Use existing localStorage logic from home_screen
      final decksJson = html.window.localStorage['flashcard_decks'];
      List<Map<String, dynamic>> decksList = [];
      
      if (decksJson != null && decksJson.isNotEmpty) {
        final List<dynamic> existingDecks = jsonDecode(decksJson);
        decksList = existingDecks.cast<Map<String, dynamic>>();
      }
      
      // Check if deck already exists
      final bool deckExists = decksList.any((deckJson) => 
        deckJson['title'] == deck.title);
      
      if (!deckExists) {
        // Convert deck to string format for storage
        final deckString = DeckString.fromGenericDeck(deck);
        decksList.add(deckString.toJson());
        
        // Save back to storage
        html.window.localStorage['flashcard_decks'] = jsonEncode(decksList);
      }
    } catch (e) {
      print('Error saving default deck: $e');
    }
  }
}
