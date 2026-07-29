import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../features/categories/data/models/category_model.dart';
import '../../features/expenses/data/models/expense_model.dart';
import '../database/hive_database.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sincroniza de forma bidireccional los datos entre Hive y Firestore al iniciar sesión.
  Future<void> syncOnLogin(String userId) async {
    try {
      // 1. Obtener datos locales
      final localCategories = HiveDatabase.categoryBox.values.toList();
      final localExpenses = HiveDatabase.expenseBox.values.toList();

      // 2. Obtener datos de Firestore
      final categoriesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();

      final expensesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .get();

      final Map<String, CategoryModel> remoteCategoriesMap = {};
      for (var doc in categoriesSnapshot.docs) {
        final data = doc.data();
        final cat = CategoryModel(
          id: data['id'] as String,
          name: data['name'] as String,
          colorHex: data['colorHex'] as String,
          iconCodePoint: data['iconCodePoint'] as int?,
          createdAt: DateTime.parse(data['createdAt'] as String),
        );
        remoteCategoriesMap[cat.id] = cat;
      }

      final Map<String, ExpenseModel> remoteExpensesMap = {};
      for (var doc in expensesSnapshot.docs) {
        final data = doc.data();
        final exp = ExpenseModel(
          id: data['id'] as String,
          categoryId: data['categoryId'] as String,
          categoryName: data['categoryName'] as String,
          categoryColorHex: data['categoryColorHex'] as String,
          categoryIconCodePoint: data['categoryIconCodePoint'] as int?,
          amount: (data['amount'] as num).toDouble(),
          description: data['description'] as String?,
          expenseDate: DateTime.parse(data['expenseDate'] as String),
          createdAt: DateTime.parse(data['createdAt'] as String),
        );
        remoteExpensesMap[exp.id] = exp;
      }

      // --- Sincronizar Categorías ---
      // A. Subir locales que no están en Firestore
      for (var localCat in localCategories) {
        if (!remoteCategoriesMap.containsKey(localCat.id)) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('categories')
              .doc(localCat.id)
              .set({
            'id': localCat.id,
            'name': localCat.name,
            'colorHex': localCat.colorHex,
            'iconCodePoint': localCat.iconCodePoint,
            'createdAt': localCat.createdAt.toIso8601String(),
          });
        }
      }

      // B. Descargar remotas que no están localmente
      for (var remoteCat in remoteCategoriesMap.values) {
        if (!HiveDatabase.categoryBox.containsKey(remoteCat.id)) {
          await HiveDatabase.categoryBox.put(remoteCat.id, remoteCat);
        }
      }

      // --- Sincronizar Gastos ---
      // A. Subir locales que no están en Firestore
      for (var localExp in localExpenses) {
        if (!remoteExpensesMap.containsKey(localExp.id)) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('expenses')
              .doc(localExp.id)
              .set({
            'id': localExp.id,
            'categoryId': localExp.categoryId,
            'categoryName': localExp.categoryName,
            'categoryColorHex': localExp.categoryColorHex,
            'categoryIconCodePoint': localExp.categoryIconCodePoint,
            'amount': localExp.amount,
            'description': localExp.description,
            'expenseDate': localExp.expenseDate.toIso8601String(),
            'createdAt': localExp.createdAt.toIso8601String(),
          });
        }
      }

      // B. Descargar remotas que no están localmente
      for (var remoteExp in remoteExpensesMap.values) {
        if (!HiveDatabase.expenseBox.containsKey(remoteExp.id)) {
          await HiveDatabase.expenseBox.put(remoteExp.id, remoteExp);
        }
      }
    } catch (e) {
      throw Exception('Error durante la sincronización: $e');
    }
  }

  /// Sube un gasto a Firestore en tiempo real.
  Future<void> uploadExpense(String userId, ExpenseModel expense) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .doc(expense.id)
          .set({
        'id': expense.id,
        'categoryId': expense.categoryId,
        'categoryName': expense.categoryName,
        'categoryColorHex': expense.categoryColorHex,
        'categoryIconCodePoint': expense.categoryIconCodePoint,
        'amount': expense.amount,
        'description': expense.description,
        'expenseDate': expense.expenseDate.toIso8601String(),
        'createdAt': expense.createdAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error al subir gasto en tiempo real: $e');
    }
  }

  /// Elimina un gasto de Firestore en tiempo real.
  Future<void> deleteExpense(String userId, String expenseId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .doc(expenseId)
          .delete();
    } catch (e) {
      debugPrint('Error al eliminar gasto en tiempo real: $e');
    }
  }

  /// Sube una categoría a Firestore en tiempo real.
  Future<void> uploadCategory(String userId, CategoryModel category) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(category.id)
          .set({
        'id': category.id,
        'name': category.name,
        'colorHex': category.colorHex,
        'iconCodePoint': category.iconCodePoint,
        'createdAt': category.createdAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error al subir categoría en tiempo real: $e');
    }
  }

  /// Elimina una categoría de Firestore en tiempo real.
  Future<void> deleteCategory(String userId, String categoryId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(categoryId)
          .delete();
    } catch (e) {
      debugPrint('Error al eliminar categoría en tiempo real: $e');
    }
  }

  /// Asegura que todos los datos locales se hayan subido antes de limpiar Hive para cerrar sesión.
  Future<void> syncAndClearLocalData(String userId) async {
    try {
      // 1. Subir cualquier dato local pendiente para no perder nada
      final localCategories = HiveDatabase.categoryBox.values.toList();
      final localExpenses = HiveDatabase.expenseBox.values.toList();

      for (var cat in localCategories) {
        await uploadCategory(userId, cat);
      }
      for (var exp in localExpenses) {
        await uploadExpense(userId, exp);
      }

      // 2. Limpiar las cajas locales de Hive para proteger la privacidad
      await HiveDatabase.categoryBox.clear();
      await HiveDatabase.expenseBox.clear();
      await HiveDatabase.settingsBox.delete('userName');

      // 3. Volver a sembrar las categorías predeterminadas para cuando no haya sesión
      await HiveDatabase.seedDefaultCategories();
    } catch (e) {
      throw Exception('Error al cerrar sesión y limpiar datos locales: $e');
    }
  }
}
