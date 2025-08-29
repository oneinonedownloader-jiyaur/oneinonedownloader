import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _adFreeProductId = 'remove_ads'; // Replace with your actual product ID

// Provider for the IAP service
final iapServiceProvider = Provider((ref) => IapService(ref));

// Provider for the ad-free status
final isAdFreeProvider = StateProvider<bool>((ref) => false);

class IapService {
  final Ref _ref;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final Set<String> _productIds = {_adFreeProductId};
  List<ProductDetails> _products = [];

  IapService(this._ref);

  Future<void> init() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      return;
    }

    await _loadProducts();
    await _loadAdFreeStatus();
    // Restore purchases on initialization to check for previous transactions.
    await restorePurchases();

    _subscription = _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () => _subscription.cancel(),
      onError: (error) => print('Purchase stream error: $error'),
    );
  }

  Future<void> _loadProducts() async {
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds);
    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
    }
    _products = response.productDetails;
  }

  Future<void> _loadAdFreeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isAdFree = prefs.getBool('is_ad_free') ?? false;
    _ref.read(isAdFreeProvider.notifier).state = isAdFree;
  }

  Future<void> _saveAdFreeStatus(bool newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_ad_free', newStatus);
    _ref.read(isAdFreeProvider.notifier).state = newStatus;
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
        if (purchaseDetails.productID == _adFreeProductId) {
          _saveAdFreeStatus(true);
        }
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> buyRemoveAds() async {
    ProductDetails? productDetails;
    try {
      productDetails = _products.firstWhere((product) => product.id == _adFreeProductId);
    } catch (e) {
      productDetails = null;
    }
    if (productDetails == null) {
      print('Product not found.');
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  void dispose() {
    _subscription.cancel();
  }
}
