// lib/utils/constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Order & Delivery App';
  static const String appVersion = '1.0.0';

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  // Routes
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String cartRoute = '/cart';
  static const String orderTrackingRoute = '/order-tracking';
  static const String deliveryHomeRoute = '/delivery-home';
  static const String updateStatusRoute = '/update-status';
  static const String adminDashboardRoute = '/admin-dashboard';
  static const String addProductRoute = '/add-product';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';

  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusProcessing = 'processing';
  static const String orderStatusOutForDelivery = 'out_for_delivery';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';

  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleDelivery = 'delivery';
  static const String roleAdmin = 'admin';
}

class AppStrings {
  static const String login = 'Login';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String name = 'Name';
  static const String phone = 'Phone Number';
  static const String logout = 'Logout';
  static const String addToCart = 'Add to Cart';
  static const String checkout = 'Checkout';
  static const String placeOrder = 'Place Order';
  static const String trackOrder = 'Track Order';
  static const String products = 'Products';
  static const String orders = 'Orders';
  static const String delivery = 'Delivery';
  static const String admin = 'Admin';
  static const String noProductsFound = 'No products found';
  static const String noOrdersFound = 'No orders found';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String pleaseWait = 'Please wait...';
}
