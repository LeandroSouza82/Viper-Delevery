import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/services/dispatch_service.dart';

class ViperDispatchOverlay extends StatefulWidget {
  final DispatchService dispatchService;
  final VoidCallback onClose;

  const ViperDispatchOverlay({
    super.key,
    required this.dispatchService,
    required this.onClose,
  });

  @override
  State<ViperDispatchOverlay> createState() => _ViperDispatchOverlayState();
}

class _ViperDispatchOverlayState extends State<ViperDispatchOverlay> with TickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: widget.dispatchService.statusStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final status = data['status'] as DispatchStatus;
          final wave = data['wave'] as int;
          final radius = data['radius'] as double;
          final value = data['value'] as double;

          return Stack(
            children: [
              // Radar Background
              if (status == DispatchStatus.searching)
                _buildRadarAnimation(),

              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (status == DispatchStatus.searching) ...[
                        const Text(
                          'BUSCANDO MOTORISTAS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Onda $wave - Raio de ${radius.toInt()}km',
                          style: TextStyle(
                            color: Colors.cyanAccent.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildStatusCard(value),
                      ] else if (status == DispatchStatus.driverNotFound) ...[
                        _buildNoDriverView(value),
                      ] else if (status == DispatchStatus.driverFound) ...[
                        _buildDriverFoundView(),
                      ],
                      
                      const Spacer(),
                      
                      // Cancel Button
                      TextButton(
                        onPressed: widget.onClose,
                        child: Text(
                          'CANCELAR SOLICITAÇÃO',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRadarAnimation() {
    return Center(
      child: AnimatedBuilder(
        animation: _radarController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _buildRadarCircle(1.0, _radarController.value),
              _buildRadarCircle(0.7, (_radarController.value + 0.33) % 1.0),
              _buildRadarCircle(0.4, (_radarController.value + 0.66) % 1.0),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRadarCircle(double baseScale, double animationValue) {
    return Transform.scale(
      scale: baseScale + (animationValue * 2),
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.cyanAccent.withOpacity(1.0 - animationValue),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity((1.0 - animationValue) * 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(double value) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text(
            'VALOR DA OFERTA',
            style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            'R\$ ${value.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const Text(
            'O valor aumenta sua prioridade no leilão.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDriverView(double currentValue) {
    return Column(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 80),
        const SizedBox(height: 24),
        const Text(
          'SEM MOTORISTAS NO MOMENTO',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Expandimos a busca até 12km, mas não houve aceite. Deseja oferecer um incentivo para atrair um motorista agora?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 40),
        
        // Boost Buttons
        Row(
          children: [
            _buildBoostButton('+ R\$ 2,00', 2.0, Colors.orangeAccent),
            const SizedBox(width: 16),
            _buildBoostButton('+ R\$ 4,00', 4.0, Colors.redAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildBoostButton(String label, double value, Color color) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => widget.dispatchService.applyPriorityBoost(value),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDriverFoundView() {
    return Column(
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 100),
        const SizedBox(height: 24),
        const Text(
          'MOTORISTA ENCONTRADO!',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        const Text(
          'Ricardo está a caminho em uma Honda CG 160 Preto.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: widget.onClose,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('VISUALIZAR NO MAPA', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
