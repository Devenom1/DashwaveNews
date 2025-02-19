import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_category.dart';

class SharedPreferencesManager {
  static const String _gNewsCategoriesKey = 'gNewsCategories';
  static const String _bookmarkedNewsIDKey = 'bookmarkedNewsID';
  static const String _isFirstLaunchKey = 'isFirstLaunch';

  static Future<void> saveGNewsCategories(List<NewsCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = categories.map((category) => jsonEncode(category.toJson())).toList();
    await prefs.setStringList(_gNewsCategoriesKey, categoriesJson);
  }

  static Future<List<NewsCategory>> getGNewsCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getStringList(_gNewsCategoriesKey) ?? [];
    return categoriesJson.map((json) => NewsCategory.fromJson(jsonDecode(json) as Map<String, dynamic>)).toList();
  }

  static Future<void> saveBookmarkedNewsID(List<String> newsIDs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_bookmarkedNewsIDKey, newsIDs);
  }

  static Future<List<String>> getBookmarkedNewsID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_bookmarkedNewsIDKey) ?? [];
  }

  static Future<void> addBookmarkedNewsID(String newsID) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> bookmarkedNewsIDs = prefs.getStringList(_bookmarkedNewsIDKey) ?? [];
    if (!bookmarkedNewsIDs.contains(newsID)) {
      bookmarkedNewsIDs.add(newsID);
      await prefs.setStringList(_bookmarkedNewsIDKey, bookmarkedNewsIDs);
    }
  }

  static Future<void> removeBookmarkedNewsID(String newsID) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> bookmarkedNewsIDs = prefs.getStringList(_bookmarkedNewsIDKey) ?? [];
    bookmarkedNewsIDs.remove(newsID);
    await prefs.setStringList(_bookmarkedNewsIDKey, bookmarkedNewsIDs);
  }

  static Future<bool> isNewsBookmarked(String newsID) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> bookmarkedNewsIDs = prefs.getStringList(_bookmarkedNewsIDKey) ?? [];
    return bookmarkedNewsIDs.contains(newsID);
  }

  static Future<bool> getIsFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }

  static Future<void> setIsFirstLaunch(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, value);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}