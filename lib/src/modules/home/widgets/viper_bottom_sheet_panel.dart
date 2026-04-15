import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_order_card.dart';

class ViperBottomSheetPanel extends StatefulWidget {
  const ViperBottomSheetPanel({
    super.key,
    required this.isDark,
    required this.bottomSafePadding,
    required this.orders,
  });

  final bool isDark;
  final double bottomSafePadding;
  final ValueNotifier<List<ViperOrder>> orders;

  @override
  ViperBottomSheetPanelState createState() => ViperBottomSheetPanelState();
}

class ViperBottomSheetPanelState extends State<ViperBottomSheetPanel> {
  late final DraggableScrollableController _sheetController;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  /// Expande o painel para ~50% (Uber/Dragon Ball style).
  Future<void> expandToHalf() async {
    if (!mounted || !_sheetController.isAttached) return;
    await _sheetController.animateTo(
      0.5,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
    );
  }

  /// Recolhe para a barra (~16%).
  Future<void> collapseToPeek() async {
    if (!mounted || !_sheetController.isAttached) return;
    await _sheetController.animateTo(
      0.16,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _removeOrder(ViperOrder order) {
    widget.orders.value = widget.orders.value.where((o) => o.id != order.id).toList();
    if (widget.orders.value.isEmpty) {
      collapseToPeek();
    }
  }

  @override
  Widget build(BuildContext context) {
    final panelBg = widget.isDark ? const Color(0xFF242424) : Colors.white;
    final handleColor = widget.isDark ? Colors.white24 : Colors.black12;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.16,
      minChildSize: 0.16,
      maxChildSize: 0.95,
      snap: true,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: Container(
            decoration: BoxDecoration(
              color: panelBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ValueListenableBuilder<List<ViperOrder>>(
              valueListenable: widget.orders,
              builder: (context, orders, child) {
                if (orders.isEmpty) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        _buildHandle(handleColor),
                        _buildEmptyState(),
                        SizedBox(height: widget.bottomSafePadding + 20),
                      ],
                    ),
                  );
                }

                return ReorderableListView.builder(
                  scrollController: scrollController,
                  header: Column(
                    children: [
                      _buildHandle(handleColor),
                      _buildHeader(orders.length),
                    ],
                  ),
                  footer: SizedBox(height: widget.bottomSafePadding + 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: orders.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final items = List<ViperOrder>.from(orders);
                    final movedItem = items.removeAt(oldIndex);
                    items.insert(newIndex, movedItem);
                    widget.orders.value = items;
                  },
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return ViperOrderCard(
                      key: ValueKey(order.id),
                      order: order,
                      isDark: widget.isDark,
                      index: index,
                      onRemove: () => _removeOrder(order),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Text(
            'Aguardando Pedidos...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fique online e aguarde novas ofertas na sua região.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: widget.isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(Color color) {
    return Container(
      width: double.infinity,
      height: 36,
      color: Colors.transparent,
      alignment: Alignment.center,
      child: Container(
        width: 44,
        height: 6,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          const Icon(Icons.delivery_dining, color: Color(0xFF0055FF)),
          const SizedBox(width: 12),
          Text(
            count > 1 ? 'Super Rota Ativa' : 'Próxima Parada',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: widget.isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

}
