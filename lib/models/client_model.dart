class ClientModel {
  String id;
  String name;
  String cnpj;
  String phone;
  String whatsapp;
  String email;
  String address;
  String city;
  String state;

  ClientModel({
    required this.id,
    required this.name,
    this.cnpj = '',
    required this.phone,
    required this.whatsapp,
    required this.email,
    this.address = '',
    required this.city,
    required this.state,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cnpj': cnpj,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      cnpj: map['cnpj'] ?? '',
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
    );
  }

  // Mantido para compatibilidade caso utilize toJson/fromJson noutros locais
  Map<String, dynamic> toJson() => toMap();

  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel.fromMap(json);
}
