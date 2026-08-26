import 'package:flutter/material.dart';

import 'app/app.dart';
import 'database/database_helper.dart';
import 'services/purchase_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.database;

  PurchaseController.instance.start();

  await PurchaseController.instance.restorePurchases();

  runApp(const PamsCompanionApp());
}
