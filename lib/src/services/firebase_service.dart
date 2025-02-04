import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../models/news_category.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  /// Fetches all Google News categories from Firestore
  ///
  /// Returns a Stream of List<NewsCategory> that contains the category documents
  static Stream<List<NewsCategory>> getGNewsCategories() {
    try {
      return _firestore
          .collection('gnews_categories')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => NewsCategory.fromFirestore(doc))
              .toList());
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Error fetching GNews categories',
      );
      rethrow;
    }
  }

  /// Fetches all Google News categories from Firestore as a Future
  ///
  /// Returns a Future<List<NewsCategory>> containing the category data
  static Future<List<NewsCategory>> getGNewsCategoriesFuture() async {
    try {
      final snapshot = await _firestore
          .collection('gnews_categories')
          .get();

      return snapshot.docs
          .map((doc) => NewsCategory.fromFirestore(doc))
          .toList();
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Error fetching GNews categories',
      );
      rethrow;
    }
  }

  /// Fetches news data based on the category
  /// If the category is 'entertainment', it loads from mock data
  /// Otherwise, fetches from Firestore
  static Future<Map<String, dynamic>> getNewsByCategory(String categoryId) async {
    try {
      if (categoryId == 'entertainment') {
        // Load mock data for entertainment news
        final String response = await rootBundle.loadString('assets/mock/latest_news_response.json');
        return json.decode(response);
      } else {
        // Fetch from Firestore for other categories
        final snapshot = await _firestore
            .collection('news')
            .where('categoryId', isEqualTo: categoryId)
            .get();

        return {
          'status': 'success',
          'items': snapshot.docs.map((doc) => doc.data()).toList(),
        };
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Error fetching news by category',
      );
      rethrow;
    }
  }

  static Future<User?> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error during sign up');
      print('Error during sign up: $e');
      rethrow;
    }
  }

  static Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error during sign in');
      print('Error during sign in: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error during sign out');
      print('Error during sign out: $e');
      rethrow;
    }
  }

  static Future<void> createUserDocument(String uid, String email, String username) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Error creating user document');
      print('Error creating user document: $e');
      rethrow;
    }
  }

  static Future<void> logCustomError(String message, {Map<String, dynamic>? parameters}) async {
    await FirebaseCrashlytics.instance.recordError(
      Exception(message),
      StackTrace.current,
      reason: 'Custom error',
      information: parameters != null ? [parameters.toString()] : [],
    );
  }
}