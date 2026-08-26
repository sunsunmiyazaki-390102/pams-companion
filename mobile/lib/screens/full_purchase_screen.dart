import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../services/purchase_service.dart';
import '../services/entitlement_service.dart';

class FullPurchaseScreen extends StatefulWidget {
  const FullPurchaseScreen({super.key});

  @override
  State<FullPurchaseScreen> createState() => _FullPurchaseScreenState();
}

class _FullPurchaseScreenState extends State<FullPurchaseScreen> {
  final PurchaseService _purchaseService = PurchaseService();

  ProductDetails? _productDetails;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    EntitlementService.instance.addListener(_handleEntitlementChanged);

    _loadProduct();
  }

  void _handleEntitlementChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _loadProduct() async {
    try {
      final available = await _purchaseService.isAvailable();

      if (!available) {
        throw StateError(
          'Google Playの購入機能を'
          '利用できません。',
        );
      }

      final product = await _purchaseService.loadFullProduct();

      if (product == null) {
        throw StateError(
          'フル機能の商品情報を'
          '取得できませんでした。',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _productDetails = product;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = '$error';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    EntitlementService.instance.removeListener(_handleEntitlementChanged);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productDetails = _productDetails;

    final isFullVersion = EntitlementService.instance.isFullVersion;

    return Scaffold(
      appBar: AppBar(title: const Text('PAMS Companion フル機能')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'AIとの対話を、'
              'あなたの知識として育てましょう。',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'フル機能では、残した対話を整理し、'
              '知識として育て、これからの生活に'
              '活かすことができます。',
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('・対話を振り返って整理する'),
                    SizedBox(height: 8),
                    Text('・知識として残し、育てる'),
                    SizedBox(height: 8),
                    Text('・次に考える問いを育てる'),
                    SizedBox(height: 8),
                    Text('・テーマや知識のつながりで整理する'),
                    SizedBox(height: 8),
                    Text('・バックアップ・エクスポートで活用する'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '一度の購入で利用できます。\n'
              '月額・年額の料金はありません。',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            if (isFullVersion)
              const Text(
                'フル機能を利用できます。',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            else if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_loadError != null)
              Text(
                '商品情報を取得できませんでした。\n'
                '$_loadError',
                textAlign: TextAlign.center,
              )
            else
              FilledButton(
                onPressed: () async {
                  await _purchaseService.buyFullProduct(productDetails);
                },
                child: Text(
                  '${productDetails!.price}で'
                  'フル機能を購入',
                ),
              ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () async {
                await _purchaseService.restorePurchases();
              },
              child: const Text('購入を復元'),
            ),

            const SizedBox(height: 24),

            const Text(
              '購入状態とPAMSのデータは'
              '別に管理されます。\n'
              '購入確認に問題があっても、'
              '保存したデータが削除されることはありません。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
