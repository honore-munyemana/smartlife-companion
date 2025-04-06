import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wed_app/models/product.dart';
import 'package:wed_app/services/database_helper.dart';
import 'package:wed_app/screens/add_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _dbHelper.productsNotifier.addListener(_onProductsUpdated);
    _dbHelper.loadProducts();
  }

  @override
  void dispose() {
    _dbHelper.productsNotifier.removeListener(_onProductsUpdated);
    super.dispose();
  }

  void _onProductsUpdated() {
    setState(() {});
  }

  void _deleteProduct(int id) async {
    await _dbHelper.deleteProduct(id);
  }

  void _editProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(product: product),
      ),
    ).then((_) => _dbHelper.loadProducts()); // Refresh the list after editing
  }

  void _viewImageFullScreen(String? imagePath) {
    if (imagePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Image.file(File(imagePath)),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
      ),
      body: ValueListenableBuilder<List<Product>>(
        valueListenable: _dbHelper.productsNotifier,
        builder: (context, products, child) {
          if (products.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return Dismissible(
                key: Key(product.id.toString()),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    // Swipe right to edit
                    _editProduct(product);
                    return false; // Prevent the item from being dismissed
                  } else if (direction == DismissDirection.endToStart) {
                    // Swipe left to delete
                    return true; // Allow the item to be dismissed
                  }
                  return false; // Default to not dismiss
                },
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    _deleteProduct(product.id!); // Delete the item
                  }
                },
                background: Container(
                  color: Colors.blue,
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 20),
                  child: Icon(Icons.edit, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  onTap: () => _editProduct(product), // Tap to edit (optional)
                  onLongPress: () => _viewImageFullScreen(product.image),
                  title: Text(product.name),
                  subtitle: Text('Price: \$${product.price.toString()}'),
                  leading: product.image != null
                      ? GestureDetector(
                          onTap: () => _viewImageFullScreen(product.image),
                          child: Image.file(
                            File(product.image!),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.image),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductScreen(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}