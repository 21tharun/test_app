class DeviceModel {
  final String serialNumber;
  final String productId;
  final String? name;
  final String addedAt;

  DeviceModel({
    required this.serialNumber,
    required this.productId,
    this.name,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'serialNumber': serialNumber,
      'productId': productId,
      'name': name,
      'addedAt': addedAt,
    };
  }

  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    return DeviceModel(
      serialNumber: map['serialNumber'] as String,
      productId: map['productId'] as String,
      name: map['name'] as String?,
      addedAt: map['addedAt'] as String,
    );
  }

  DeviceModel copyWith({
    String? serialNumber,
    String? productId,
    String? name,
    String? addedAt,
  }) {
    return DeviceModel(
      serialNumber: serialNumber ?? this.serialNumber,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  String toString() {
    return 'DeviceModel(serialNumber: $serialNumber, productId: $productId, name: $name, addedAt: $addedAt)';
  }
}

