import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import '../models/flashcard_model.dart';
import '../models/category_model.dart';
import '../services/import_service.dart';
import '../services/settings_service.dart';
import '../services/default_deck_service.dart';
import '../services/category_service.dart';
import 'deck_management_screen.dart';
import 'deck_viewer_screen.dart';
import 'match_game_screen.dart';
import 'multiple_choice_game_screen.dart';
import 'typing_game_screen.dart';
import 'audio_typing_game_screen.dart';
import 'help_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImportService _importService = ImportService();
  List<Deck> _decks = [];
  List<Category> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _isSelectionMode = false;
  Set<String> _selectedDecks = {};

  @override
  void initState() {
    super.initState();
    _loadDefaultDecksIfNeeded().then((_) {
      _loadCategories();
    });
  }

  // Load categories
  Future<void> _loadCategories() async {
    try {
      await CategoryService.initializeDefaultCategory();
      final categories = await CategoryService.getCategories();
      
      if (mounted) {
        setState(() {
          _categories = categories;
          // Select first category by default
          if (_categories.isNotEmpty && _selectedCategoryId == null) {
            _selectedCategoryId = _categories.first.id;
          }
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  // Get filtered decks for selected category
  List<Deck> get _filteredDecks {
    if (_selectedCategoryId == null) return _decks;
    
    final selectedCategory = _categories.firstWhere(
      (cat) => cat.id == _selectedCategoryId,
      orElse: () => _categories.first,
    );
    
    return _decks.where((deck) => 
      selectedCategory.deckIds.contains(deck.title)
    ).toList();
  }

  // Add new category
  Future<void> _addCategory() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      await CategoryService.addCategory(result);
      await _loadCategories();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$result" added'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // Copy deck to different category
  Future<void> _copyDeckToCategory(String deckTitle) async {
    final currentCategory = _categories.firstWhere(
      (cat) => cat.id == _selectedCategoryId,
      orElse: () => _categories.first,
    );
    
    final targetCategoryId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Copy "$deckTitle"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Copy from "${currentCategory.name}" to:'),
            const SizedBox(height: 16),
            ..._categories.where((cat) => cat.id != _selectedCategoryId).map((category) {
              return ListTile(
                leading: Icon(
                  category.isDefault ? Icons.folder : Icons.create_new_folder,
                  color: category.isDefault ? Colors.blue : Colors.grey[600],
                ),
                title: Text(category.name),
                onTap: () => Navigator.pop(context, category.id),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    if (targetCategoryId != null) {
      await CategoryService.addDeckToCategory(deckTitle, targetCategoryId);
      await _loadCategories();
      
      if (mounted) {
        final targetCategory = _categories.firstWhere((cat) => cat.id == targetCategoryId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied "$deckTitle" to "${targetCategory.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // Move deck to different category
  Future<void> _moveDeckToCategory(String deckTitle) async {
    final currentCategory = _categories.firstWhere(
      (cat) => cat.id == _selectedCategoryId,
      orElse: () => _categories.first,
    );
    
    final targetCategoryId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move "$deckTitle"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Move from "${currentCategory.name}" to:'),
            const SizedBox(height: 16),
            ..._categories.where((cat) => cat.id != _selectedCategoryId).map((category) {
              return ListTile(
                leading: Icon(
                  category.isDefault ? Icons.folder : Icons.create_new_folder,
                  color: category.isDefault ? Colors.blue : Colors.grey[600],
                ),
                title: Text(category.name),
                onTap: () => Navigator.pop(context, category.id),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    if (targetCategoryId != null) {
      await CategoryService.moveDeckToCategory(deckTitle, currentCategory.id, targetCategoryId);
      await _loadCategories();
      
      if (mounted) {
        final targetCategory = _categories.firstWhere((cat) => cat.id == targetCategoryId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Moved "$deckTitle" to "${targetCategory.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  Future<void> _deleteCategory(String categoryId) async {
    final category = _categories.firstWhere((cat) => cat.id == categoryId);
    
    if (category.isDefault) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete default category'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${category.name}"?'),
        content: const Text('This will delete the category but keep the decks. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await CategoryService.deleteCategory(categoryId);
      await _loadCategories();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "${category.name}" deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  Future<void> _loadDefaultDecksIfNeeded() async {
    try {
      print('🔍 Checking if default decks needed...');
      final decksJson = html.window.localStorage['flashcard_decks'];
      print('📊 Current decks in storage: ${decksJson?.length ?? 0} chars');
      
      // Always check if default category has decks
      await CategoryService.initializeDefaultCategory();
      final categories = await CategoryService.getCategories();
      final defaultCategory = categories.firstWhere((cat) => cat.isDefault);
      print('📁 Default category "${defaultCategory.name}" has ${defaultCategory.deckIds.length} decks');
      
      if (decksJson == null || decksJson.isEmpty) {
        print('📦 No decks found, loading defaults...');
        // User has no decks, load defaults
        await DefaultDeckService.loadDefaultDecks();
        // Reload decks from storage after adding defaults
        await _loadDecksFromStorage();
        print('✅ Default decks loaded and reloaded');
      } else if (defaultCategory.deckIds.isEmpty) {
        print('📦 Decks exist but not in Default category, reassigning...');
        // User has decks but default category is empty, reassign defaults
        await DefaultDeckService.loadDefaultDecks();
        await _loadDecksFromStorage();
        print('✅ Default decks reassigned to Default category');
      } else {
        print('📋 User has decks, loading existing...');
        // User has decks, just load them
        await _loadDecksFromStorage();
        print('✅ Existing decks loaded');
      }
    } catch (e) {
      print('❌ Error checking for default decks: $e');
    }
  }

  // Load decks from Local Storage
  Future<void> _loadDecksFromStorage() async {
    try {
      final decksJson = html.window.localStorage['flashcard_decks'];
      if (decksJson != null && decksJson.isNotEmpty) {
        final List<dynamic> decksList = jsonDecode(decksJson);
        final List<Deck> loadedDecks = [];
        
        for (final deckJson in decksList) {
          try {
            final deckString = DeckString.fromJson(deckJson);
            final deck = deckString.toGenericDeck();
            if (deck.title.isNotEmpty) {
              loadedDecks.add(deck);
            }
          } catch (e) {
            print('Error loading individual deck: $e');
            // Skip invalid decks
            continue;
          }
        }
        
        if (mounted) {
          setState(() {
            _decks = loadedDecks;
          });
        }
      }
    } catch (e) {
      print('Error loading decks from storage: $e');
    }
  }

  // Save decks to Local Storage
  Future<void> _saveDecksToStorage() async {
    try {
      final deckStrings = _decks.map((deck) => DeckString.fromGenericDeck(deck)).toList();
      final decksJson = jsonEncode(deckStrings.map((deckString) => deckString.toJson()).toList());
      html.window.localStorage['flashcard_decks'] = decksJson;
    } catch (e) {
      print('Error saving decks to storage: $e');
    }
  }

  // Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedDecks.clear();
    });
  }

  // Toggle deck selection
  void _toggleDeckSelection(String deckTitle) {
    setState(() {
      if (_selectedDecks.contains(deckTitle)) {
        _selectedDecks.remove(deckTitle);
      } else {
        _selectedDecks.add(deckTitle);
      }
    });
  }

  // Delete selected decks
  Future<void> _deleteSelectedDecks() async {
    if (_selectedDecks.isEmpty) {
      _toggleSelectionMode();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_selectedDecks.length} Deck${_selectedDecks.length == 1 ? '' : 's'}?'),
        content: Text('Are you sure you want to delete the selected deck${_selectedDecks.length == 1 ? '' : 's'}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _decks.removeWhere((deck) => _selectedDecks.contains(deck.title));
        _selectedDecks.clear();
        _isSelectionMode = false;
      });
      
      // Save to Local Storage
      await _saveDecksToStorage();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected decks deleted!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadDeck(Deck deck) async {
    try {
      // Create CSV content
      final csvLines = <String>[];
      
      // Add headers if deck has them
      if (deck.headers != null && deck.headers!.isNotEmpty) {
        csvLines.add(deck.headers!.join(','));
      }
      
      // Add card data
      for (final card in deck.cards) {
        final row = card.sides.map((side) {
          // Escape commas and quotes in the content
          String escapedSide = side.replaceAll('"', '""');
          if (escapedSide.contains(',') || escapedSide.contains('"') || escapedSide.contains('\n')) {
            escapedSide = '"$escapedSide"';
          }
          return escapedSide;
        }).join(',');
        csvLines.add(row);
      }
      
      final csvContent = csvLines.join('\n');
      final fileName = '${deck.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim()}.csv';
      
      // Show dialog with options
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Export "${deck.title}"'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Choose how you want to export your deck:'),
                    const SizedBox(height: 16),
                    
                    // Download option (web)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.download, color: Colors.blue),
                        title: const Text('Download CSV File'),
                        subtitle: const Text('Download directly to your computer'),
                        onTap: () {
                          Navigator.pop(context);
                          _downloadWebFile(csvContent, fileName);
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Share option (web)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.share, color: Colors.green),
                        title: const Text('Share CSV File'),
                        subtitle: const Text('Share via email, messaging, or save to files'),
                        onTap: () {
                          Navigator.pop(context);
                          _shareDeck(deck.title, csvContent, fileName);
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Clipboard option
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.content_copy, color: Colors.orange),
                        title: const Text('Copy to Clipboard'),
                        subtitle: const Text('Copy and paste into a text editor'),
                        onTap: () {
                          Navigator.pop(context);
                          _copyToClipboard(csvContent, deck.title);
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Text(
                      'Preview (${deck.cards.length} cards):',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.maxFinite,
                      height: 200,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            csvContent,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ${csvContent.split('\n').length} lines (${deck.cards.length} cards + ${deck.headers?.isNotEmpty == true ? '1 header' : 'no headers'})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Web App Tip',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'For best results, use "Download CSV File" to save directly to your computer with proper UTF-8 encoding for Chinese characters.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting deck: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareDeck(String deckTitle, String csvContent, String fileName) async {
    try {
      // Fallback: Use clipboard
      await _copyToClipboard(csvContent, deckTitle);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share not available on web. CSV copied to clipboard instead.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy to clipboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadWebFile(String csvContent, String fileName) {
    // Create a blob and download link for web
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Create anchor element and trigger download
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    
    // Clean up
    html.Url.revokeObjectUrl(url);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download started! Check your browser\'s downloads folder.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _copyToClipboard(String csvContent, String deckTitle) async {
    try {
      await Clipboard.setData(ClipboardData(text: csvContent));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deck "$deckTitle" copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy to clipboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importDeck() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Show dialog to ask about headers
      bool? firstRowHasHeaders = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Import CSV'),
          content: Text('Does the first row of your CSV contain headers?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (firstRowHasHeaders == null) {
        // User cancelled
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Deck? newDeck = await _importService.importDeckFromCSV(
        firstRowHasHeaders: firstRowHasHeaders,
      );
      
      if (newDeck != null) {
        setState(() {
          _decks.add(newDeck);
        });
        
        // Save to Local Storage
        await _saveDecksToStorage();
        
        // Add deck to default category
        await CategoryService.addDeckToCategory(newDeck.title, 'default');
        
        // Force reload decks from storage to ensure consistency
        await _loadDecksFromStorage();
        
        // Force UI refresh
        if (mounted) {
          setState(() {});
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported "${newDeck.title}"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing deck: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Refresh decks and categories
  Future<void> _refreshDecks() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('🔄 Refreshing decks and categories...');
      
      // Reload categories first
      await _loadCategories();
      
      // Reload decks from storage
      await _loadDecksFromStorage();
      
      print('✅ Refresh completed');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Decks refreshed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ Error refreshing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Reset default decks from assets
  Future<void> _resetDefaultDecks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Default Decks'),
        content: const Text(
          'This will reload all default decks from the asset files. '
          'Any changes you made to default decks will be lost. '
          'Your custom decks will be kept.\n\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        print('🔄 Resetting default decks from assets...');
        
        // Clear existing default decks from storage
        await _clearDefaultDecksFromStorage();
        
        // Reload default decks from assets
        await DefaultDeckService.loadDefaultDecks();
        
        // Reload all decks from storage
        await _loadDecksFromStorage();
        
        print('✅ Default decks reset completed');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Default decks reset successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('❌ Error resetting default decks: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting default decks: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Clear default decks from storage
  Future<void> _clearDefaultDecksFromStorage() async {
    try {
      final decksJson = html.window.localStorage['flashcard_decks'];
      if (decksJson != null) {
        final List<dynamic> decksList = jsonDecode(decksJson);
        final defaultDeckNames = DefaultDeckService.defaultDeckNames.toSet();
        
        // Keep only non-default decks
        final filteredDecks = decksList.where((deck) {
          return !defaultDeckNames.contains(deck['title']);
        }).toList();
        
        // Save filtered decks back to storage
        html.window.localStorage['flashcard_decks'] = jsonEncode(filteredDecks);
        print('🗑️ Cleared default decks from storage');
      }
    } catch (e) {
      print('❌ Error clearing default decks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flashcard App'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshDecks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Decks',
          ),
          IconButton(
            onPressed: _resetDefaultDecks,
            icon: const Icon(Icons.restore),
            tooltip: 'Reset Default Decks',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpScreen(),
                ),
              );
            },
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help & Guide',
          ),
          IconButton(
            onPressed: () {
              SettingsService.toggleSoundsEnabled();
              setState(() {}); // Rebuild to reflect changes
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(SettingsService.soundsEnabled ? 'Sounds enabled' : 'Sounds muted'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(SettingsService.soundsEnabled ? Icons.volume_up : Icons.volume_off),
            tooltip: SettingsService.soundsEnabled ? 'Mute Sounds' : 'Enable Sounds',
          ),
          !SettingsService.isCompactMode
              ? TextButton.icon(
                  onPressed: () {
                    SettingsService.toggleCompactMode();
                    setState(() {}); // Rebuild to reflect changes
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(SettingsService.isCompactMode ? 'Compact mode enabled' : 'Compact mode disabled'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: Icon(SettingsService.isCompactMode ? Icons.view_comfortable : Icons.view_module),
                  label: Text(SettingsService.isCompactMode ? 'Compact Mode' : 'Normal Mode'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                )
              : IconButton(
                  onPressed: () {
                    SettingsService.toggleCompactMode();
                    setState(() {}); // Rebuild to reflect changes
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(SettingsService.isCompactMode ? 'Compact mode enabled' : 'Compact mode disabled'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: Icon(SettingsService.isCompactMode ? Icons.view_comfortable : Icons.view_module),
                  tooltip: SettingsService.isCompactMode ? 'Switch to Normal Mode' : 'Switch to Compact Mode',
                ),
        ],
      ),
      body: Column(
        children: [
          // Category selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Category:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategoryId,
                    isExpanded: true,
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: Row(
                          children: [
                            Icon(
                              category.isDefault ? Icons.folder : Icons.create_new_folder,
                              size: 16,
                              color: category.isDefault ? Colors.blue : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                category.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!category.isDefault)
                              IconButton(
                                onPressed: () => _deleteCategory(category.id),
                                icon: const Icon(Icons.delete, size: 16),
                                tooltip: 'Delete Category',
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Category',
                ),
              ],
            ),
          ),
          // Deck list
          Expanded(
            child: _filteredDecks.isEmpty
                ? _buildEmptyState()
                : _buildDeckList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_decks.isNotEmpty)
            !SettingsService.isCompactMode
                ? FloatingActionButton.extended(
                    heroTag: "select",
                    onPressed: _isSelectionMode ? _deleteSelectedDecks : _toggleSelectionMode,
                    backgroundColor: _isSelectionMode ? Colors.red : Colors.orange,
                    icon: _isSelectionMode 
                        ? (_selectedDecks.isEmpty ? const Icon(Icons.close) : const Icon(Icons.delete))
                        : const Icon(Icons.checklist),
                    label: Text(_isSelectionMode 
                        ? (_selectedDecks.isEmpty ? 'Cancel' : 'Delete Selected')
                        : 'Select Decks'),
                  )
                : FloatingActionButton(
                    heroTag: "select",
                    onPressed: _isSelectionMode ? _deleteSelectedDecks : _toggleSelectionMode,
                    backgroundColor: _isSelectionMode ? Colors.red : Colors.orange,
                    child: _isSelectionMode 
                        ? (_selectedDecks.isEmpty ? const Icon(Icons.close) : const Icon(Icons.delete))
                        : const Icon(Icons.checklist),
                  ),
          if (_decks.isNotEmpty) const SizedBox(height: 16),
          !SettingsService.isCompactMode
              ? FloatingActionButton.extended(
                  heroTag: "new",
                  onPressed: _showCreateDeckDialog,
                  backgroundColor: Colors.blue,
                  icon: const Icon(Icons.add),
                  label: const Text('New Deck'),
                )
              : FloatingActionButton(
                  heroTag: "new",
                  onPressed: _showCreateDeckDialog,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.add),
                ),
          const SizedBox(height: 16),
          !SettingsService.isCompactMode
              ? FloatingActionButton.extended(
                  heroTag: "import",
                  onPressed: _isLoading ? null : _importDeck,
                  backgroundColor: Colors.green,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.file_upload),
                  label: const Text('Import CSV'),
                )
              : FloatingActionButton(
                  heroTag: "import",
                  onPressed: _isLoading ? null : _importDeck,
                  backgroundColor: Colors.green,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.file_upload),
                ),
        ],
      ),
    );
  }

  // Show create deck dialog
  Future<void> _showCreateDeckDialog() async {
    final titleController = TextEditingController();
    final side1Controller = TextEditingController();
    final side2Controller = TextEditingController();
    
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Deck'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Deck Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: side1Controller,
                decoration: const InputDecoration(
                  labelText: 'Side 1 (e.g., Question)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: side2Controller,
                decoration: const InputDecoration(
                  labelText: 'Side 2 (e.g., Answer)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty && 
                  side1Controller.text.trim().isNotEmpty && 
                  side2Controller.text.trim().isNotEmpty) {
                final newDeck = Deck<String>(
                  title: titleController.text.trim(),
                  cards: [
                    Flashcard<String>(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      sides: [
                        side1Controller.text.trim(),
                        side2Controller.text.trim(),
                      ],
                    ),
                  ],
                );
                
                setState(() {
                  _decks.add(newDeck);
                });
                
                // Save to Local Storage
                await _saveDecksToStorage();
                
                // Add deck to default category
                await CategoryService.addDeckToCategory(newDeck.title, 'default');
                
                // Force reload decks from storage to ensure consistency
                await _loadDecksFromStorage();
                
                // Force UI refresh
                if (mounted) {
                  setState(() {});
                }
                
                Navigator.pop(context, true);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New deck created!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.deck_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No decks yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to import your first CSV deck',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckList() {
    final decksToShow = _filteredDecks;
    print('Building deck list with ${decksToShow.length} decks in category');
    return Column(
      children: [
        if (_isSelectionMode)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.red[50],
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.red[700]),
                const SizedBox(width: 8),
                Text(
                  'Select decks to delete (${_selectedDecks.length} selected)',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _toggleSelectionMode,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: decksToShow.length,
            itemBuilder: (context, index) {
              final deck = decksToShow[index];
              final isSelected = _selectedDecks.contains(deck.title);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                color: isSelected ? Colors.red[50] : null,
                child: InkWell(
                  onTap: _isSelectionMode 
                      ? () => _toggleDeckSelection(deck.title)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Deck title and card count
                        Row(
                          children: [
                            if (_isSelectionMode)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    _toggleDeckSelection(deck.title);
                                  },
                                  activeColor: Colors.red,
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        deck.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (!_isSelectionMode) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => DeckManagementScreen(
                                                  deck: deck,
                                                  onDeckUpdated: (updatedDeck) async {
                                                    setState(() {
                                                      // Find and update deck in list
                                                      final index = _decks.indexWhere((d) => d.title == deck.title);
                                                      if (index != -1) {
                                                        _decks[index] = updatedDeck;
                                                      }
                                                    });
                                                    // Save changes to Local Storage
                                                    await _saveDecksToStorage();
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.edit),
                                          tooltip: 'Edit Deck',
                                          iconSize: 20,
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            _deleteDeck(deck);
                                          },
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Delete Deck',
                                          iconSize: 20,
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            _moveDeckToCategory(deck.title);
                                          },
                                          icon: const Icon(Icons.drive_file_move_outline, color: Colors.blue),
                                          tooltip: 'Move Deck',
                                          iconSize: 20,
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            _copyDeckToCategory(deck.title);
                                          },
                                          icon: const Icon(Icons.content_copy, color: Colors.green),
                                          tooltip: 'Copy Deck',
                                          iconSize: 20,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${deck.cards.length} ${deck.cards.length == 1 ? 'card' : 'cards'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Action buttons (only in non-selection mode)
                        if (!_isSelectionMode)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              !SettingsService.isCompactMode
                                  ? SizedBox(
                                      width: 100,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DeckViewerScreen(deck: deck),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.school, size: 16),
                                        label: const Text('Study'),
                                      ),
                                    )
                                  : SizedBox(
                                      width: 48,
                                      child: IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DeckViewerScreen(deck: deck),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.school, size: 16),
                                        tooltip: 'Study',
                                      ),
                                    ),
                              const SizedBox(height: 4),
                              !SettingsService.isCompactMode
                                  ? SizedBox(
                                      width: 100,
                                      child: TextButton.icon(
                                        onPressed: () => _showGameMenu(deck),
                                        icon: const Icon(Icons.games, size: 16),
                                        label: const Text('Game'),
                                      ),
                                    )
                                  : SizedBox(
                                      width: 48,
                                      child: IconButton(
                                        onPressed: () => _showGameMenu(deck),
                                        icon: const Icon(Icons.games, size: 16),
                                        tooltip: 'Game',
                                      ),
                                    ),
                              const SizedBox(height: 4),
                              !SettingsService.isCompactMode
                                  ? SizedBox(
                                      width: 130,
                                      child: TextButton.icon(
                                        onPressed: () => _downloadDeck(deck),
                                        icon: const Icon(Icons.download, size: 16),
                                        label: const Text('Download'),
                                        style: TextButton.styleFrom(
                                          minimumSize: const Size(130, 36),
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      width: 48,
                                      child: IconButton(
                                        onPressed: () => _downloadDeck(deck),
                                        icon: const Icon(Icons.download, size: 16),
                                        tooltip: 'Download',
                                      ),
                                    ),
                              const SizedBox(height: 4),
                              !SettingsService.isCompactMode
                                  ? SizedBox(
                                      width: 130,
                                      child: TextButton.icon(
                                        onPressed: () => _moveDeckToCategory(deck.title),
                                        icon: const Icon(Icons.drive_file_move_outline, size: 16),
                                        label: const Text('Move'),
                                        style: TextButton.styleFrom(
                                          minimumSize: const Size(130, 36),
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      width: 48,
                                      child: IconButton(
                                        onPressed: () => _moveDeckToCategory(deck.title),
                                        icon: const Icon(Icons.drive_file_move_outline, size: 16),
                                        tooltip: 'Move',
                                      ),
                                    ),
                              const SizedBox(height: 4),
                              !SettingsService.isCompactMode
                                  ? SizedBox(
                                      width: 130,
                                      child: TextButton.icon(
                                        onPressed: () => _copyDeckToCategory(deck.title),
                                        icon: const Icon(Icons.content_copy, size: 16),
                                        label: const Text('Copy'),
                                        style: TextButton.styleFrom(
                                          minimumSize: const Size(130, 36),
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      width: 48,
                                      child: IconButton(
                                        onPressed: () => _copyDeckToCategory(deck.title),
                                        icon: const Icon(Icons.content_copy, size: 16),
                                        tooltip: 'Copy',
                                      ),
                                    ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _deleteDeck(Deck deck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${deck.title}"?'),
        content: Text('Are you sure you want to delete this deck? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _decks.removeWhere((d) => d.title == deck.title);
      });
      
      // Save to Local Storage
      await _saveDecksToStorage();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deck "${deck.title}" deleted!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showGameMenu(Deck deck) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Game Mode - ${deck.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.extension),
              title: const Text('Match Game'),
              subtitle: const Text('Match terms to their definitions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MatchGameScreen(deck: deck),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Multiple Choice'),
              subtitle: const Text('Answer multiple choice questions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultipleChoiceGameScreen(deck: deck),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.keyboard),
              title: const Text('Typing Game'),
              subtitle: const Text('Type the answers to questions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TypingGameScreen(deck: deck),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.hearing),
              title: const Text('Audio Typing Game'),
              subtitle: const Text('Listen to audio and type what you hear'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AudioTypingGameScreen(deck: deck),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
