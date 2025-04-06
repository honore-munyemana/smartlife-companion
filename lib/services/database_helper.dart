import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:wed_app/models/product.dart'; // Import the Product model

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;
  final ValueNotifier<List<Product>> productsNotifier = ValueNotifier([]); // No error now

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'products.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            price REAL NOT NULL,
            image TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    final id = await db.insert('products', product);
    loadProducts(); // Call the public method
    return id;
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    var result = await db.query('products', orderBy: 'id DESC');
    return result;
  }

  Future<int> updateProduct(Map<String, dynamic> product) async {
    final db = await database;
    final id = await db.update('products', product, where: 'id = ?', whereArgs: [product['id']]);
    loadProducts(); // Call the public method
    return id;
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    final result = await db.delete('products', where: 'id = ?', whereArgs: [id]);
    loadProducts(); // Call the public method
    return result;
  }

  Future<void> loadProducts() async { // Renamed from _loadProducts to loadProducts
    final products = await getProducts();
    productsNotifier.value = products.map((product) => Product.fromMap(product)).toList();
  }
}