import 'package:flutter/material.dart';

class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuda e Suporte'),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          'Ajuda em Construção',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
