import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/services/external_navigation.dart';
import 'package:viper_delivery/src/modules/home/services/viper_mock_service.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_order_card.dart';

/// Painel inferior: Super Rota / chamada única com [ReorderableListView].
///
/// O [DraggableScrollableController] vive aqui (um por ciclo de vida) para não
/// duplicar attach quando o [ListenableBuilder] da Home reconstrói o mapa.
class ViperBottomSheetPanel extends StatefulWidget {
  const ViperBottomSheetPanel({
    super.key,
    required this.isDark,
    required this.bottomSafePadding,
    required this.orders,
    required this.rideWave,
  });

  final bool isDark;
  final double bottomSafePadding;
  final ValueNotifier<List<ViperOrder>> orders;
  final ValueNotifier<int> rideWave;

  @override
  ViperBottomSheetPanelState createState() => ViperBottomSheetPanelState();
}

class ViperBottomSheetPanelState extends State<ViperBottomSheetPanel>
    with SingleTickerProviderStateMixin {
  late final DraggableScrollableController _sheetController;
  late final AnimationController _introController;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Listenable _ordersAndWave;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    _ordersAndWave = Listenable.merge([widget.orders, widget.rideWave]);
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
      ),
    );
    _fade = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );
    widget.rideWave.addListener(_onRideWave);
    if (widget.orders.value.isNotEmpty) {
      _introController.value = 1;
    }
  }

  void _onRideWave() {
    if (widget.orders.value.isNotEmpty) {
      _introController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.rideWave.removeListener(_onRideWave);
    _introController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  /// Expande o painel para ~50% (simulação de corrida / Uber).
  Future<void> expandToHalf() async {
    if (!mounted || !_sheetController.isAttached) return;
    await _sheetController.animateTo(
      0.5,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  /// Recolhe para a barra (~10%).
  Future<void> collapseToPeek() async {
    if (!mounted || !_sheetController.isAttached) return;
    await _sheetController.animateTo(
      0.1,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    final list = List<ViperOrder>.from(widget.orders.value);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    widget.orders.value = list;
  }

  void _removeOrder(ViperOrder order) {
    final list =
        widget.orders.value.where((o) => o.id != order.id).toList(growable: false);
    widget.orders.value = List<ViperOrder>.from(list);
    if (list.isEmpty) {
      collapseToPeek();
    }
  }

  Future<void> _onRota(ViperOrder order) async {
    await openExternalNavigation(order.endereco);
  }

  void _onFalha(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    'Motivo da falha',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Cliente Ausente'),
                  onTap: () => Navigator.pop(ctx),
                ),
                ListTile(
                  title: const Text('Endereço não localizado'),
                  onTap: () => Navigator.pop(ctx),
                ),
                ListTile(
                  title: const Text('Outros'),
                  onTap: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final panelBg = widget.isDark ? const Color(0xFF242424) : Colors.white;
    final titleColor = widget.isDark ? Colors.white : Colors.black87;
    final subtitleColor = widget.isDark ? Colors.white54 : Colors.black45;
    final handleColor = widget.isDark ? Colors.white38 : Colors.grey.shade400;
    final emptyHint = widget.isDark ? Colors.white38 : Colors.black38;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.1, 0.5, 0.95],
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: Container(
            decoration: BoxDecoration(
              color: panelBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: widget.isDark ? 0.45 : 0.12,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _ordersAndWave,
              builder: (context, child) {
                final orders = widget.orders.value;
                final isSuper = orders.length > 1;
                final title = orders.isEmpty
                    ? 'Viper Ride'
                    : (isSuper ? 'Super Rota' : 'Chamada única');
                final subtitle = orders.isEmpty
                    ? 'Toque no radar para simular uma corrida.'
                    : (isSuper
                        ? 'Segure um card para reordenar as paradas.'
                        : 'Confira os dados e aceite quando estiver pronto.');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: handleColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: orders.isEmpty
                          ? ListView(
                              controller: scrollController,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                24,
                                8,
                                24,
                                widget.bottomSafePadding + 32,
                              ),
                              children: [
                                Center(
                                  child: Text(
                                    'Nenhuma corrida ativa.\nUse o botão de radar à esquerda.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: emptyHint,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : FadeTransition(
                              opacity: _fade,
                              child: SlideTransition(
                                position: _slide,
                                child: ReorderableListView.builder(
                                  scrollController: scrollController,
                                  buildDefaultDragHandles: true,
                                  padding: EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    widget.bottomSafePadding + 20,
                                  ),
                                  itemCount: orders.length,
                                  onReorder: _onReorder,
                                  itemBuilder: (context, index) {
                                    final order = orders[index];
                                    final palette =
                                        ViperOrderCard.paletteFor(order.tipo);
                                    return Padding(
                                      key: ValueKey<String>(order.id),
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: ViperOrderCard(
                                        order: order,
                                        accent: palette.$1,
                                        cardGradient: palette.$2,
                                        isDark: widget.isDark,
                                        onRota: () => _onRota(order),
                                        onFalha: () => _onFalha(context),
                                        onOk: () => _removeOrder(order),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
