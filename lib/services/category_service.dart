import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import '../models/category_model.dart';

class CategoryService {
  static const String _categoriesKey = 'flashcard_categories';
  static const String _defaultCategoryId = 'default';

  // Get all categories
  static Future<List<Category>> getCategories() async {
    try {
      final categoriesJson = html.window.localStorage[_categoriesKey];
      if (categoriesJson != null && categoriesJson.isNotEmpty) {
        final List<dynamic> categoriesList = jsonDecode(categoriesJson);
        return categoriesList.map((json) => Category.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error loading categories: $e');
      return [];
    }
  }

  // Save categories to storage
  static Future<void> saveCategories(List<Category> categories) async {
    try {
      final categoriesJson = jsonEncode(categories.map((cat) => cat.toJson()).toList());
      html.window.localStorage[_categoriesKey] = categoriesJson;
    } catch (e) {
      print('Error saving categories: $e');
    }
  }

  // Initialize default category
  static Future<void> initializeDefaultCategory() async {
    final categories = await getCategories();
    final hasDefault = categories.any((cat) => cat.isDefault);
    
    if (!hasDefault) {
      final defaultCategory = Category(
        id: _defaultCategoryId,
        name: 'Default',
        deckIds: [],
        createdAt: DateTime.now(),
        isDefault: true,
      );
      categories.add(defaultCategory);
      await saveCategories(categories);
    }
  }

  // Add new category
  static Future<void> addCategory(String name) async {
    try {
      final categories = await getCategories();
      final newCategory = Category(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        deckIds: [],
        createdAt: DateTime.now(),
      );
      categories.add(newCategory);
      await saveCategories(categories);
    } catch (e) {
      print('Error adding category: $e');
    }
  }

  // Update category
  static Future<void> updateCategory(Category category) async {
    try {
      final categories = await getCategories();
      final index = categories.indexWhere((cat) => cat.id == category.id);
      if (index != -1) {
        categories[index] = category;
        await saveCategories(categories);
      }
    } catch (e) {
      print('Error updating category: $e');
    }
  }

  // Delete category (only if not default)
  static Future<void> deleteCategory(String categoryId) async {
    try {
      final categories = await getCategories();
      final category = categories.firstWhere((cat) => cat.id == categoryId);
      
      if (category.isDefault) {
        throw Exception('Cannot delete default category');
      }
      
      categories.removeWhere((cat) => cat.id == categoryId);
      await saveCategories(categories);
    } catch (e) {
      print('Error deleting category: $e');
    }
  }

  // Add deck to category
  static Future<void> addDeckToCategory(String deckId, String categoryId) async {
    try {
      final categories = await getCategories();
      final category = categories.firstWhere((cat) => cat.id == categoryId);
      
      if (!category.deckIds.contains(deckId)) {
        final updatedCategory = category.copyWith(
          deckIds: [...category.deckIds, deckId]
        );
        await updateCategory(updatedCategory);
      }
    } catch (e) {
      print('Error adding deck to category: $e');
    }
  }

  // Remove deck from category
  static Future<void> removeDeckFromCategory(String deckId, String categoryId) async {
    try {
      final categories = await getCategories();
      final category = categories.firstWhere((cat) => cat.id == categoryId);
      
      final updatedDeckIds = List<String>.from(category.deckIds)
        ..remove(deckId);
      
      final updatedCategory = category.copyWith(deckIds: updatedDeckIds);
      await updateCategory(updatedCategory);
    } catch (e) {
      print('Error removing deck from category: $e');
    }
  }

  // Get decks in category
  static Future<List<String>> getDecksInCategory(String categoryId) async {
    try {
      final categories = await getCategories();
      final category = categories.firstWhere((cat) => cat.id == categoryId);
      return category.deckIds;
    } catch (e) {
      print('Error getting decks in category: $e');
      return [];
    }
  }

  // Move deck to different category
  static Future<void> moveDeckToCategory(String deckId, String fromCategoryId, String toCategoryId) async {
    try {
      await removeDeckFromCategory(deckId, fromCategoryId);
      await addDeckToCategory(deckId, toCategoryId);
    } catch (e) {
      print('Error moving deck to category: $e');
    }
  }
}
