import 'package:flutter/material.dart';

import 'full_purchase_screen.dart';

class PremiumFeatureLockScreen extends StatelessWidget {
  const PremiumFeatureLockScreen({
    super.key,
    required this.featureTitle,
    required this.description,
  });

  final String featureTitle;
  final String description;

  void _openPurchaseScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const FullPurchaseScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(featureTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.lock_outline, size: 64),

            const SizedBox(height: 24),

            Text(
              featureTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            const Text(
              'この機能は'
              'PAMS Companion フル機能で'
              '利用できます。',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 32),

            FilledButton(
              onPressed: () {
                _openPurchaseScreen(context);
              },
              child: const Text('フル機能について見る'),
            ),

            const SizedBox(height: 8),

            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
