import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second screen')),
      body: Center(
        child: Text(
          'Barcode callback is not firing here because parent widget isn\'t visible',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
