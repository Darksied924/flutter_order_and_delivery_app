// lib/services/db_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../utils/constants.dart';

class DBService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ PRODUCTS ============

  // Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('isAvailable', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('category', isEqualTo: category)
          .where('isAvailable', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  // Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .get();

      if (doc.exists) {
        return Product.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // Add product
  Future<void> addProduct(Product product) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .set(product.toMap());
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Update product
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // ============ ORDERS ============

  // Get all orders (for admin)
  Future<List<Order>> getAllOrders() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get orders: $e');
    }
  }

  // Get orders by user ID
  Future<List<Order>> getOrdersByUserId(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get orders: $e');
    }
  }

  // Get orders by status
  Future<List<Order>> getOrdersByStatus(String status) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get orders: $e');
    }
  }

  // Get order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (doc.exists) {
        return Order.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Create order
  Future<void> createOrder(Order order) async {
    try {
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(order.id)
          .set(order.toMap());
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      Map<String, dynamic> data = {
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (status == AppConstants.orderStatusDelivered) {
        data['deliveredAt'] = DateTime.now().toIso8601String();
      }

      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Assign delivery person
  Future<void> assignDeliveryPerson(
    String orderId,
    String deliveryPersonId,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update({
            'deliveryPersonId': deliveryPersonId,
            'status': AppConstants.orderStatusOutForDelivery,
            'updatedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception('Failed to assign delivery person: $e');
    }
  }

  // Update payment info
  Future<void> updatePaymentInfo(
    String orderId,
    String paymentStatus,
    String? mpesaReceiptNumber,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update({
            'paymentStatus': paymentStatus,
            'mpesaReceiptNumber': mpesaReceiptNumber,
            'updatedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception('Failed to update payment info: $e');
    }
  }

  // Get orders for delivery person
  Future<List<Order>> getDeliveryOrders(String deliveryPersonId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('deliveryPersonId', isEqualTo: deliveryPersonId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get delivery orders: $e');
    }
  }

  // Get pending orders (for delivery assignment)
  Future<List<Order>> getPendingOrders() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .where(
            'status',
            whereIn: [
              AppConstants.orderStatusPending,
              AppConstants.orderStatusProcessing,
            ],
          )
          .orderBy('createdAt', ascending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending orders: $e');
    }
  }

  // Get today's orders count
  Future<int> getTodayOrdersCount() async {
    try {
      DateTime startOfDay = DateTime.now();
      startOfDay = DateTime(startOfDay.year, startOfDay.month, startOfDay.day);

      QuerySnapshot querySnapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('createdAt', isGreaterThan: startOfDay.toIso8601String())
          .get();

      return querySnapshot.size;
    } catch (e) {
      throw Exception('Failed to get today orders count: $e');
    }
  }

  // Get total revenue
  Future<double> getTotalRevenue() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('paymentStatus', isEqualTo: 'completed')
          .get();

      double total = 0;
      for (var doc in querySnapshot.docs) {
        Order order = Order.fromMap(doc.data() as Map<String, dynamic>);
        total += order.totalAmount;
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get total revenue: $e');
    }
  }
}
