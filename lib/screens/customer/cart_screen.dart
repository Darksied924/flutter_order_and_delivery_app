// lib/screens/customer/cart_screen.dart

import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/order.dart';
import '../../services/db_service.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final DBService _dbService = DBService();
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService();

  final Map<String, int> _cartItems = {}; // productId -> quantity
  final List<Product> _products = [];
  bool _isLoading = false;
  bool _isProcessingPayment = false;

  double get _totalAmount {
    double total = 0;
    for (var entry in _cartItems.entries) {
      final product = _products.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => Product(
          id: '',
          name: '',
          description: '',
          price: 0,
          imageUrl: '',
          category: '',
          isAvailable: true,
          stockQuantity: 0,
          createdAt: DateTime.now(),
        ),
      );
      if (product.id.isNotEmpty) {
        total += product.price * entry.value;
      }
    }
    return total;
  }

  int get _totalItems {
    return _cartItems.values.fold(0, (sum, qty) => sum + qty);
  }

  void addToCart(String productId) {
    setState(() {
      _cartItems[productId] = (_cartItems[productId] ?? 0) + 1;
    });
  }

  void removeFromCart(String productId) {
    setState(() {
      if (_cartItems.containsKey(productId)) {
        if (_cartItems[productId]! > 1) {
          _cartItems[productId] = _cartItems[productId]! - 1;
        } else {
          _cartItems.remove(productId);
        }
      }
    });
  }

  void removeProduct(String productId) {
    setState(() {
      _cartItems.remove(productId);
    });
  }

  Future<void> _placeOrder(String address, String phone) async {
    if (_cartItems.isEmpty) return;

    setState(() => _isProcessingPayment = true);

    try {
      // Create order items
      List<OrderItem> items = [];
      for (var entry in _cartItems.entries) {
        final product = _products.firstWhere((p) => p.id == entry.key);
        items.add(OrderItem.fromProduct(product, entry.value));
      }

      // Create order
      final user = await _authService.getUserData(
        _authService.currentUser!.uid,
      );

      Order order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _authService.currentUser!.uid,
        userName: user?.name ?? 'Unknown',
        userPhone: phone,
        deliveryAddress: address,
        items: items,
        totalAmount: _totalAmount,
        status: AppConstants.orderStatusPending,
        paymentMethod: 'mpesa',
        paymentStatus: 'pending',
        createdAt: DateTime.now(),
      );

      // Save order to database
      await _dbService.createOrder(order);

      // Initiate M-Pesa payment
      await _paymentService.processOrderPayment(order, phone);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed! Check your phone for M-Pesa payment.'),
            backgroundColor: AppConstants.successColor,
          ),
        );

        setState(() {
          _cartItems.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  void _showCheckoutDialog() {
    final addressController = TextEditingController();
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.checkout,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Delivery Address',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number (M-Pesa)',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      CurrencyHelper.format(_totalAmount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isProcessingPayment
                    ? null
                    : () {
                        if (addressController.text.isEmpty ||
                            phoneController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill in all fields'),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        _placeOrder(
                          addressController.text,
                          phoneController.text,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessingPayment
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        AppStrings.placeOrder,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some products to get started',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _cartItems.length,
            itemBuilder: (context, index) {
              final productId = _cartItems.keys.elementAt(index);
              final quantity = _cartItems[productId]!;

              // Find product
              final product = _products.firstWhere(
                (p) => p.id == productId,
                orElse: () => Product(
                  id: productId,
                  name: 'Loading...',
                  description: '',
                  price: 0,
                  imageUrl: '',
                  category: '',
                  isAvailable: true,
                  stockQuantity: 0,
                  createdAt: DateTime.now(),
                ),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Product Image
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: product.imageUrl.isNotEmpty
                            ? Image.network(product.imageUrl, fit: BoxFit.cover)
                            : const Icon(Icons.image, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),

                      // Product Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyHelper.format(product.price),
                              style: TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quantity Controls
                      Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => removeFromCart(productId),
                              ),
                              Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => addToCart(productId),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: AppConstants.errorColor,
                            ),
                            onPressed: () => removeProduct(productId),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Checkout Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total ($_totalItems items)',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      CurrencyHelper.format(_totalAmount),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessingPayment
                        ? null
                        : _showCheckoutDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      AppStrings.checkout,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
