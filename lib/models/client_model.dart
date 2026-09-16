class ClientModel {
  final String id;
  final String name;
  final String phone;
  final String whatsapp;
  final String email;
  final String city;
  final String state;

  ClientModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.city,
    required this.state,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'city': city,
      'state': state,
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      email: map['email'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
    );
  }
}