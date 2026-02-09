import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/child.dart';

class LocalStorageService {
  static const String _childrenKey = 'children';

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  static Future<List<Child>> loadChildren() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_childrenKey);

    if (jsonString == null) return [];

    final List decoded = json.decode(jsonString);
    return decoded.map((e) => Child.fromJson(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  static Future<void> saveChildren(List<Child> children) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        json.encode(children.map((c) => c.toJson()).toList());

    await prefs.setString(_childrenKey, encoded);
  }

  // ---------------------------------------------------------------------------
  // Create
  // ---------------------------------------------------------------------------

  static Future<void> addChild(Child child) async {
    final children = await loadChildren();
    children.add(child);
    await saveChildren(children);
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  static Future<void> updateChild(Child updatedChild) async {
    final children = await loadChildren();

    final index =
        children.indexWhere((c) => c.localId == updatedChild.localId);

    if (index != -1) {
      children[index] = updatedChild;
      await saveChildren(children);
    }
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  static Future<void> deleteChild(String localId) async {
    final children = await loadChildren();
    children.removeWhere((c) => c.localId == localId);
    await saveChildren(children);
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_childrenKey);
  }
}
