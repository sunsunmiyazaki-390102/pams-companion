import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'purchase_service.dart';

class EntitlementService extends ChangeNotifier {
  EntitlementService._();

  static final EntitlementService instance = EntitlementService._();

  bool _isFullVersion = false;

  bool get isFullVersion => _isFullVersion;

  bool applyPurchase(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.productID != PurchaseService.fullProductId) {
      return false;
    }

    final isEntitled =
        purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored;

    if (!isEntitled) {
      return false;
    }

    if (!_isFullVersion) {
      _isFullVersion = true;
      notifyListeners();
    }

    return true;
  }
}
