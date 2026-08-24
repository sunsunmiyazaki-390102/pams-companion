import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService {
  PurchaseService();

  static const String fullProductId =
      'pams_companion_full';

  final InAppPurchase _inAppPurchase =
      InAppPurchase.instance;

  Stream<List<PurchaseDetails>> get purchaseStream {
    return _inAppPurchase.purchaseStream;
  }

  Future<bool> isAvailable() async {
    return _inAppPurchase.isAvailable();
  }

  Future<ProductDetails?> loadFullProduct() async {
    final response =
        await _inAppPurchase.queryProductDetails(
      {
        fullProductId,
      },
    );

    if (response.error != null) {
      throw StateError(
        '商品情報を取得できませんでした。\n'
        '${response.error}',
      );
    }

    if (response.productDetails.isEmpty) {
      return null;
    }

    return response.productDetails.first;
  }

  Future<bool> buyFullProduct(
    ProductDetails productDetails,
  ) async {
    final purchaseParam =
        PurchaseParam(
      productDetails: productDetails,
    );

    return _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
  }

  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  Future<void> completePurchase(
    PurchaseDetails purchaseDetails,
  ) async {
    if (!purchaseDetails.pendingCompletePurchase) {
      return;
    }

    await _inAppPurchase.completePurchase(
      purchaseDetails,
    );
  }
}

