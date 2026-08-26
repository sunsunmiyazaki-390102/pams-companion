import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'entitlement_service.dart';
import 'purchase_service.dart';

class PurchaseController {
  PurchaseController._();

  static final PurchaseController instance = PurchaseController._();

  final PurchaseService _purchaseService = PurchaseService();

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  void start() {
    if (_purchaseSubscription != null) {
      return;
    }

    _purchaseSubscription = _purchaseService.purchaseStream.listen(
      _handlePurchaseUpdates,
    );
  }

  Future<void> restorePurchases() async {
    await _purchaseService.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final isEntitled = EntitlementService.instance.applyPurchase(purchase);

      if (!isEntitled) {
        continue;
      }

      await _purchaseService.completePurchase(purchase);
    }
  }

  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
  }
}
