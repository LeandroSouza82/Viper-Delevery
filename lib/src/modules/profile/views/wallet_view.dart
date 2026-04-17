import 'package:flutter/material.dart';

class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Carteira'),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          'Tela de Carteira em Construção',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
