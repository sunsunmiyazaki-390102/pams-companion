import 'package:flutter/material.dart';

class PamsCompanionApp extends StatelessWidget {
  const PamsCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAMS Companion',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PAMS Companion'),
        ),
        body: const Center(
          child: Text(
            'PAMS Companion',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
