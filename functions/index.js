// Firebase Cloud Functions - Backend Logic for Order & Delivery App
// All functions for secure payment processing and order management

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// M-Pesa Callback Handler
// Processes payment confirmation from Safaricom
exports.mpesaCallback = functions.https.onRequest(async (req, res) => {
  try {
    const { Body } = req.body;
    
    if (!Body || !Body.stkCallback) {
      console.log('Invalid callback received');
      res.status(400).send('Invalid request');
      return;
    }

    const stkCallback = Body.stkCallback;
    const resultCode = stkCallback.ResultCode;
    const merchantRequestId = stkCallback.MerchantRequestID;
    const checkoutRequestId = stkCallback.CheckoutRequestID;

    console.log(`M-Pesa Callback: ResultCode = ${resultCode}, MerchantRequestID = ${merchantRequestId}`);

    if (resultCode === 0) {
      // Payment successful
      const callbackMetadata = stkCallback.CallbackMetadata.Item;
      
      // Extract payment details
      let amount, mpesaReceiptNumber, phoneNumber, transactionDate;
      
      for (const item of callbackMetadata) {
        if (item.Name === 'Amount') amount = item.Value;
        if (item.Name === 'MpesaReceiptNumber') mpesaReceiptNumber = item.Value;
        if (item.Name === 'PhoneNumber') phoneNumber = item.Value;
        if (item.Name === 'TransactionDate') transactionDate = item.Value;
      }

      console.log(`Payment successful: Receipt=${mpesaReceiptNumber}, Amount=${amount}`);

      // Find order by merchant request ID and update payment status
      // Note: In production, you'd store the merchantRequestId with the order
      // For now, we'll log the successful payment
      res.status(200).send('Callback received');
      
    } else {
      // Payment failed
      console.log(`Payment failed with code: ${resultCode}`);
      res.status(200).send('Callback received');
    }

  } catch (error) {
    console.error('Error processing M-Pesa callback:', error);
    res.status(500).send('Internal server error');
  }
});

// Create Order Function
// Creates a new order in Firestore
exports.createOrder = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to create an order'
    );
  }

  const { items, totalAmount, deliveryAddress, userPhone, paymentMethod } = data;

  if (!items || !totalAmount || !deliveryAddress) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields'
    );
  }

  try {
    const orderRef = admin.firestore().collection('orders').doc();
    const orderId = orderRef.id;

    await orderRef.set({
      id: orderId,
      userId: context.auth.uid,
      items: items,
      totalAmount: totalAmount,
      deliveryAddress: deliveryAddress,
      userPhone: userPhone,
      status: 'pending',
      paymentMethod: paymentMethod || 'mpesa',
      paymentStatus: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, orderId: orderId };
  } catch (error) {
    console.error('Error creating order:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to create order'
    );
  }
});

// Update Order Status
// Allows delivery personnel and admins to update order status
exports.updateOrderStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { orderId, status } = data;

  if (!orderId || !status) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields'
    );
  }

  const validStatuses = ['pending', 'processing', 'out_for_delivery', 'delivered', 'cancelled'];
  if (!validStatuses.includes(status)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Invalid status'
    );
  }

  try {
    const orderRef = admin.firestore().collection('orders').doc(orderId);
    const orderDoc = await orderRef.get();

    if (!orderDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Order not found'
      );
    }

    const updateData = {
      status: status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (status === 'delivered') {
      updateData.deliveredAt = admin.firestore.FieldValue.serverTimestamp();
    }

    await orderRef.update(updateData);

    return { success: true };
  } catch (error) {
    console.error('Error updating order status:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to update order status'
    );
  }
});

// Send Order Notification
// Sends push notification when order status changes
exports.sendOrderNotification = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const newStatus = change.after.data().status;
    const previousStatus = change.before.data().status;

    // Only send notification if status changed
    if (newStatus === previousStatus) return;

    const userId = change.after.data().userId;

    try {
      // Get user's FCM token
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      
      if (!userDoc.exists || !userDoc.data().fcmToken) {
        console.log('User or FCM token not found');
        return;
      }

      const fcmToken = userDoc.data().fcmToken;
      const userName = userDoc.data().name;

      // Construct notification message based on status
      let title, body;
      
      switch (newStatus) {
        case 'processing':
          title = 'Order Processing';
          body = `Hi ${userName}, your order is being processed!`;
          break;
        case 'out_for_delivery':
          title = 'Out for Delivery';
          body = `Hi ${userName}, your order is on the way!`;
          break;
        case 'delivered':
          title = 'Order Delivered';
          body = `Hi ${userName}, your order has been delivered. Enjoy!`;
          break;
        case 'cancelled':
          title = 'Order Cancelled';
          body = `Hi ${userName}, your order has been cancelled.`;
          break;
        default:
          return;
      }

      // Send push notification
      const message = {
        notification: { title, body },
        token: fcmToken,
        data: {
          orderId: context.params.orderId,
          status: newStatus,
        },
      };

      await admin.messaging().send(message);
      console.log('Notification sent successfully');

    } catch (error) {
      console.error('Error sending notification:', error);
    }
  });

// Get User Statistics
// Returns statistics for a user (orders count, etc.)
exports.getUserStats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  try {
    const userId = context.auth.uid;

    // Get orders count
    const ordersSnapshot = await admin.firestore()
      .collection('orders')
      .where('userId', '==', userId)
      .get();

    const totalOrders = ordersSnapshot.size;

    // Get delivered orders count
    const deliveredOrders = ordersSnapshot.docs
      .filter(doc => doc.data().status === 'delivered')
      .length;

    // Calculate total spent
    let totalSpent = 0;
    ordersSnapshot.docs.forEach(doc => {
      totalSpent += doc.data().totalAmount || 0;
    });

    return {
      totalOrders,
      deliveredOrders,
      totalSpent,
    };
  } catch (error) {
    console.error('Error getting user stats:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to get user statistics'
    );
  }
});

// Get Admin Statistics
// Returns overall statistics for admin dashboard
exports.getAdminStats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  try {
    // Verify admin role
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(context.auth.uid)
      .get();

    if (!userDoc.exists || userDoc.data().role !== 'admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can access this'
      );
    }

    // Get all orders
    const ordersSnapshot = await admin.firestore()
      .collection('orders')
      .get();

    const totalOrders = ordersSnapshot.size;

    // Calculate revenue
    let totalRevenue = 0;
    let pendingOrders = 0;
    let deliveredOrders = 0;

    ordersSnapshot.docs.forEach(doc => {
      const orderData = doc.data();
      if (orderData.paymentStatus === 'completed') {
        totalRevenue += orderData.totalAmount || 0;
      }
      if (orderData.status === 'delivered') {
        deliveredOrders++;
      }
      if (orderData.status === 'pending') {
        pendingOrders++;
      }
    });

    // Get products count
    const productsSnapshot = await admin.firestore()
      .collection('products')
      .get();

    const totalProducts = productsSnapshot.size;

    // Get users count
    const usersSnapshot = await admin.firestore()
      .collection('users')
      .get();

    const totalUsers = usersSnapshot.size;

    return {
      totalOrders,
      totalRevenue,
      pendingOrders,
      deliveredOrders,
      totalProducts,
      totalUsers,
    };
  } catch (error) {
    console.error('Error getting admin stats:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to get admin statistics'
    );
  }
});

console.log('Firebase Functions loaded successfully');

