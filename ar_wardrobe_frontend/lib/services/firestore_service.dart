import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/saved_outfit.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // ==================== CART OPERATIONS ====================

  Future<void> addToCart(CartItem item) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('cart')
        .doc(item.id)
        .set(item.toJson());
  }

  Future<void> removeFromCart(String cartItemId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('cart')
        .doc(cartItemId)
        .delete();
  }

  Future<void> updateCartItemQuantity(String cartItemId, int quantity) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('cart')
        .doc(cartItemId)
        .update({'quantity': quantity});
  }

  Stream<List<CartItem>> getCartItems() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('cart')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CartItem.fromJson(doc.data()))
              .toList();
        });
  }

  // ==================== SAVED OUTFITS OPERATIONS ====================

  Future<void> addToSavedOutfits(SavedOutfit outfit) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('saved_outfits')
        .doc(outfit.id)
        .set(outfit.toJson());
  }

  Future<void> removeFromSavedOutfits(String outfitId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('saved_outfits')
        .doc(outfitId)
        .delete();
  }

  Stream<List<SavedOutfit>> getSavedOutfits() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('saved_outfits')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SavedOutfit.fromJson(doc.data()))
              .toList();
        });
  }

  // ==================== ORDERS OPERATIONS ====================

  Future<void> addOrder(UserOrder order) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('orders')
        .doc(order.id)
        .set(order.toJson());
  }

  Future<void> clearCart() async {
    if (_userId == null) throw Exception('User not authenticated');

    final cartSnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('cart')
        .get();

    for (final doc in cartSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Stream<List<UserOrder>> getOrders() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map<List<UserOrder>>((snapshot) {
          return snapshot.docs
              .map((doc) => UserOrder.fromJson(doc.data()))
              .toList();
        });
  }
}
