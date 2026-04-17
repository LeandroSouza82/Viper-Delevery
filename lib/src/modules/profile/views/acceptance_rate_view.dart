import 'package:flutter/material.dart';

class AcceptanceRateView extends StatelessWidget {
  const AcceptanceRateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taxa de Aceitação'),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          'Métricas em Construção',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
