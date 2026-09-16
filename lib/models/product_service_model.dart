class ProductServiceModel {
  final String id;
  final String name;
  final double price;
  final String type; // 'produto' ou 'servico'

  ProductServiceModel({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
  });

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'price': price, 'type': type};

  factory ProductServiceModel.fromMap(Map<String, dynamic> map) {
    return ProductServiceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      type: map['type'] ?? 'servico',
    );
  }
}