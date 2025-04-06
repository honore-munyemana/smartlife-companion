class Product {
  int? id;
  String name;
  String description;
  double price;
  String? image;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
     print("Mapping Product: $map"); // Log the map
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'],
      image: map['image'],
    );
  }
}
