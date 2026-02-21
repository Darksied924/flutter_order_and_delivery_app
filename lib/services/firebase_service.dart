import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  // 🔥 Firebase instances
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =============================
  // AUTH
  // =============================

  User? get currentUser => _auth.currentUser;

  String? get uid => _auth.currentUser?.uid;

  // =============================
  // USERS
  // =============================

  Future<void> createUser({required String name, required String email}) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'createdAt': Timestamp.now(),
    });
  }

  Future<DocumentSnapshot> getUser() {
    return _db.collection('users').doc(uid).get();
  }

  // =============================
  // ORDERS
  // =============================

  Future<void> createOrder({
    required String restaurantId,
    required double totalPrice,
  }) async {
    await _db.collection('orders').add({
      'userId': uid,
      'restaurantId': restaurantId,
      'totalPrice': totalPrice,
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getUserOrders() {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // =============================
  // DRIVER FEATURES
  // =============================

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }
}
