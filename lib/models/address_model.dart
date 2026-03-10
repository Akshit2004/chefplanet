class Address {
  final String id;
  final String userId;
  final String label; // e.g., Home, Office
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;

  Address({
    required this.id,
    required this.userId,
    required this.label,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['_id'].toString(),
      userId: json['userId'] as String,
      label: json['label'] as String,
      street: json['street'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      isDefault: (json['isDefault'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'label': label,
    'street': street,
    'city': city,
    'state': state,
    'zipCode': zipCode,
    'isDefault': isDefault,
  };
}
