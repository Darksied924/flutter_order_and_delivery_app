// lib/models/order.dart

import 'product.dart';

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
    };
  }

  // Create from Product model
  factory OrderItem.fromProduct(Product product, int quantity) {
    return OrderItem(
      productId: product.id,
      productName: product.name,
      price: product.price,
      quantity: quantity,
    );
  }
}

class Order {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String deliveryAddress;
  final List<OrderItem> items;
  final double totalAmount;
  final String
  status; // pending, processing, out_for_delivery, delivered, cancelled
  final String? deliveryPersonId;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? mpesaReceiptNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.deliveryAddress,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.deliveryPersonId,
    this.paymentMethod,
    this.paymentStatus,
    this.mpesaReceiptNumber,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    List<OrderItem> itemsList = [];
    if (map['items'] != null) {
      itemsList = (map['items'] as List)
          .map((item) => OrderItem.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    return Order(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      deliveryAddress: map['deliveryAddress'] ?? '',
      items: itemsList,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      deliveryPersonId: map['deliveryPersonId'],
      paymentMethod: map['paymentMethod'],
      paymentStatus: map['paymentStatus'],
      mpesaReceiptNumber: map['mpesaReceiptNumber'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      deliveredAt: map['deliveredAt'] != null
          ? DateTime.parse(map['deliveredAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'deliveryAddress': deliveryAddress,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'deliveryPersonId': deliveryPersonId,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'mpesaReceiptNumber': mpesaReceiptNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? deliveryAddress,
    List<OrderItem>? items,
    double? totalAmount,
    String? status,
    String? deliveryPersonId,
    String? paymentMethod,
    String? paymentStatus,
    String? mpesaReceiptNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      deliveryPersonId: deliveryPersonId ?? this.deliveryPersonId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      mpesaReceiptNumber: mpesaReceiptNumber ?? this.mpesaReceiptNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}
