import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/models/viper_order.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_order_card.dart';
import 'package:viper_delivery/src/modules/returns/widgets/returns_tab_view.dart';
import 'package:viper_delivery/src/modules/home/services/pricing_service.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_receipt_bottom_sheet.dart';

class ViperBottomSheetPanel extends StatefulWidget {
  const ViperBottomSheetPanel({
    super.key,
    required this.isDark,
    required this.bottomSafePadding,
    required this.orders,
    required this.offer,
    required this.onFinalize,
    required this.menuController,
    this.isClt = false,
  });

  final bool isDark;
  final double bottomSafePadding;
  final ValueNotifier<List<ViperOrder>> orders;
  final ViperOffer? offer;
  final VoidCallback onFinalize;
  final ViperMenuController menuController;
  final bool isClt;

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

  /// Expande o painel para 50% (Meio termo).
  Future<void> expandToHalf() async {
    if (!mounted || !_sheetController.isAttached) return;
    await _sheetController.animateTo(
      0.5,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
    );
  }

  /// Recolhe para o modo resumo (15%).
  Future<void> collapseToPeek() async {
    if (!mounted || !_sheetController.isAttached) return;
    await _sheetController.animateTo(
      0.15,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _updateOrderStatus(ViperOrder order, ViperOrderStatus status, {String? motivo}) {
    final updatedList = widget.orders.value.map((o) {
      if (o.id == order.id) {
        return o.copyWith(status: status, motivoFalha: motivo);
      }
      return o;
    }).toList();
    
    widget.orders.value = updatedList;
    _checkIfTripIsDone(updatedList);
  }

  void _checkIfTripIsDone(List<ViperOrder> allOrders) {
    if (allOrders.isEmpty || widget.offer == null) return;

    final allDone = allOrders.every((o) => 
      o.status == ViperOrderStatus.completed || o.status == ViperOrderStatus.returned
    );

    if (allDone) {
      final summary = ViperPricingService.calculateExecutionSummary(
        offer: widget.offer!,
        processedOrders: allOrders,
        isClt: widget.isClt,
      );

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ViperReceiptBottomSheet(
          summary: summary,
          isDark: widget.isDark,
          isClt: widget.isClt,
          menuController: widget.menuController,
          onFinish: () {
            Navigator.pop(context);
            // RESET TOTAL DO ESTADO
            widget.orders.value = [];
            widget.onFinalize();
            collapseToPeek();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final panelBg = widget.isDark ? const Color(0xFF242424) : Colors.white;
    final handleColor = widget.isDark ? Colors.white24 : Colors.black12;

    return DefaultTabController(
      length: 2,
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: 0.15,
        minChildSize: 0.15,
        maxChildSize: 0.9,
        snap: true,
        snapSizes: const [0.15, 0.5, 0.9],
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
                builder: (context, allOrders, child) {
                  final activeOrders = allOrders.where((o) => o.status == ViperOrderStatus.pending).toList();
                  final failedOrders = allOrders.where((o) => o.status == ViperOrderStatus.failed).toList();
                  
                  return Builder(builder: (context) {
                    final tabController = DefaultTabController.of(context);
                    
                    return ListenableBuilder(
                      listenable: tabController,
                      builder: (context, _) {
                        return SingleChildScrollView(
                          controller: scrollController,
                          physics: const AlwaysScrollableScrollPhysics(), // Garante arraste mesmo se lista pequena
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ÁREA DRAGGABLE 1: Handle
                              _buildHandle(handleColor),
                              
                              // ÁREA DRAGGABLE 2: Cabeçalho
                              _buildHeader(activeOrders.length),
                              
                              // ÁREA DRAGGABLE 3: Abas
                              TabBar(
                                indicatorColor: const Color(0xFF0055FF),
                                labelColor: widget.isDark ? Colors.white : Colors.black,
                                unselectedLabelColor: Colors.grey,
                                indicatorWeight: 3,
                                tabs: [
                                  Tab(text: 'Rota (${activeOrders.length})'),
                                  Tab(text: 'Falhas (${failedOrders.length})'),
                                ],
                              ),
                              
                              // CONTEÚDO DINÂMICO (Substituindo TabBarView por ShrinkWrap)
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                  child: tabController.index == 0
                                      ? _buildActiveRouteTab(activeOrders)
                                      : ReturnsTabView(
                                          failedOrders: failedOrders,
                                          isDark: widget.isDark,
                                          onReturnToBase: (order) => _updateOrderStatus(order, ViperOrderStatus.returned),
                                        ),
                                ),
                              ),
                              
                              SizedBox(height: widget.bottomSafePadding + 40),
                            ],
                          ),
                        );
                      },
                    );
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveRouteTab(List<ViperOrder> activeOrders) {
    if (activeOrders.isEmpty) {
      return Column(
        children: [
          _buildEmptyState(),
        ],
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      header: const SizedBox.shrink(), // Header movido para o SingleChildScrollView pai
      footer: const SizedBox.shrink(),
      itemCount: activeOrders.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        final items = List<ViperOrder>.from(activeOrders);
        final movedItem = items.removeAt(oldIndex);
        items.insert(newIndex, movedItem);
        // Atualizar a lista global mantendo a ordem dos processados se houver
        final List<ViperOrder> newList = [];
        final completed = widget.orders.value.where((o) => o.status != ViperOrderStatus.pending).toList();
        newList.addAll(completed);
        newList.addAll(items);
        widget.orders.value = newList;
      },
      itemBuilder: (context, index) {
        final order = activeOrders[index];
        return ViperOrderCard(
          key: ValueKey(order.id),
          order: order,
          isDark: widget.isDark,
          index: index,
          isClt: widget.isClt,
          onRemove: () {}, 
          onFinish: () => _updateOrderStatus(order, ViperOrderStatus.completed),
          onFailure: (o, motivo) => _updateOrderStatus(o, ViperOrderStatus.failed, motivo: motivo),
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
      height: 24, // Reduzido para dar menos espaço morto no topo
      color: Colors.transparent,
      alignment: Alignment.center,
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: color.withAlpha(150),
          borderRadius: BorderRadius.circular(2.5),
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
