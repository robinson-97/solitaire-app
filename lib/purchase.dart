import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'storage.dart';

/// The one-time purchase that unlocks the whole game (stage 4 and up).
/// Create a non-consumable in-app product with this id in the Play Console.
class Purchases {
  static const productId = 'hopstone_full';

  /// Store details (price text) once loaded; null when the store is not reachable.
  static final ValueNotifier<ProductDetails?> product = ValueNotifier(null);
  static final ValueNotifier<String?> message = ValueNotifier(null);
  static StreamSubscription<List<PurchaseDetails>>? _sub;
  static Storage? _storage;

  static Future<void> init(Storage storage) async {
    _storage = storage;
    try {
      final iap = InAppPurchase.instance;
      _sub ??= iap.purchaseStream.listen(_onPurchases, onError: (_) {});
      if (!await iap.isAvailable()) return;
      final r = await iap.queryProductDetails({productId});
      product.value = r.productDetails.where((p) => p.id == productId).firstOrNull;
    } catch (_) {
      // no store (emulator, sideloaded test build): the game still works
    }
  }

  static Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.productID != productId) continue;
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        await _storage?.setFullVersion(true);
        message.value = 'Thank you! The full game is unlocked.';
      } else if (p.status == PurchaseStatus.error) {
        message.value = 'The purchase did not go through.';
      }
      if (p.pendingCompletePurchase) await InAppPurchase.instance.completePurchase(p);
    }
  }

  static Future<void> buy() async {
    final p = product.value;
    if (p == null) {
      message.value = 'The store is not available right now.';
      return;
    }
    try {
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: p));
    } catch (_) {
      message.value = 'The purchase could not be started.';
    }
  }

  static Future<void> restore() async {
    try {
      await InAppPurchase.instance.restorePurchases();
      message.value = 'Looking for earlier purchases...';
    } catch (_) {
      message.value = 'The store is not available right now.';
    }
  }
}
