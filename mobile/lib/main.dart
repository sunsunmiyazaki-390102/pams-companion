import 'package:flutter/material.dart';

import 'app/app.dart';
import 'database/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.database;

  runApp(const PamsCompanionApp());
}
