import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/models/ride_model.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';
import 'package:viper_delivery/src/modules/home/views/settings_view.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_order_card.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_receipt_bottom_sheet.dart';
import 'package:viper_delivery/src/modules/profile/controllers/profile_controller.dart';
import 'package:viper_delivery/src/modules/returns/widgets/returns_tab_view.dart';
import 'package:viper_delivery/src/modules/ride/controllers/ride_state_machine.dart';
import 'package:viper_delivery/src/modules/ride/widgets/failure_modal.dart';
import 'package:viper_delivery/src/modules/ride/widgets/signature_modal.dart';

class ViperBottomSheetPanel extends StatefulWidget {
  const ViperBottomSheetPanel({
    super.key,
    required this.isDark,
    required this.bottomSafePadding,
    required this.onFinalize,
    required this.menuController,
    required this.settingsController,
    required this.rideStateMachine,
    this.isClt = false,
  });

  final bool isDark;
  final double bottomSafePadding;

  final VoidCallback onFinalize;
  final ViperMenuController menuController;
  final SettingsController settingsController;
  final RideStateMachine rideStateMachine;
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

  void _updateOrderStatus(RideModel ride, RideStatus status, {String? motivo}) {
    // Agora o próprio RideStateMachine cuida de atualizar local e remoto
    widget.rideStateMachine.removerCorridaDaTela(ride.id, status, motivo: motivo);
    _checkIfTripIsDone(widget.rideStateMachine.activeOrders);
  }

  void _checkIfTripIsDone(List<RideModel> allOrders) {
    if (allOrders.isEmpty) return;

    final allDone = allOrders.every((o) => 
      o.status == RideStatus.completed || o.status == RideStatus.returned || o.status == RideStatus.failed
    );

    if (allDone) {
      final summary = RideExecutionSummary(
        rideIds: allOrders.map((o) => o.id).toList(),
        baseValue: 15.0, // TODO: Calc baseado em dados reais
        successBonus: 0.0,
        attemptFee: 0.0,
        totalValue: 15.0,
        countSuccess: allOrders.where((o) => o.status == RideStatus.completed).length,
        countFailed: allOrders.where((o) => o.status == RideStatus.failed || o.status == RideStatus.returned).length,
      );

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) => ViperReceiptBottomSheet(
          summary: summary,
          isDark: widget.isDark,
          isClt: widget.isClt,
          menuController: widget.menuController,
          onFinish: () {
            // 1. Fechar o BottomSheet de Resumo
            Navigator.pop(context);
            
            // 2. RESET TOTAL DO ESTADO (Prevenção de Loops)
            widget.rideStateMachine.activeOrders.clear();
            widget.rideStateMachine.reset(); // Volta para Idle e limpa mapa
            
            // 3. Notificar o MenuController para atualizar ganhos na Home
            widget.onFinalize();
            
            // 4. NAVEGAÇÃO LIMPA: Volta para a Home resetando a pilha
            Get.offAllNamed('/home'); // Reset total do stack via rota nomeada
          },
        ),
      );
    }
  }

  Future<void> _onSuccessDelivery(RideModel ride) async {
    final signed = await SignatureModal.show(
      context, 
      isDark: widget.isDark,
      rideId: ride.id,
    );
    if (signed == true) {
      _updateOrderStatus(ride, RideStatus.completed);
    }
  }

  /// Falha: abre o modal de falha antes de mover para logística reversa.
  Future<void> _onFailureDelivery(RideModel ride, String legacyMotivo) async {
    final result = await FailureModal.show(
      context,
      isDark: widget.isDark,
      clienteName: ride.clientName,
    );
    if (result != null) {
      _updateOrderStatus(ride, RideStatus.failed, motivo: result.motivo);
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
              child: Obx(() {
                  final allOrders = widget.rideStateMachine.activeOrders;
                  final activeOrders = allOrders.where((o) => o.status != RideStatus.completed && o.status != RideStatus.failed && o.status != RideStatus.returned).toList();
                  final failedOrders = allOrders.where((o) => o.status == RideStatus.failed).toList();
                  
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
                              
                              // HEADER PRINCIPAL (GEAR | VIPER | AJUSTES)
                              _buildDragonBallHeader(context),
                              
                              // SELETOR DE ABAS (ROTA | FALHA)
                              _buildTabSelector(tabController, activeOrders.length, failedOrders.length),
                              
                              const SizedBox(height: 8),
                              
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
                                          onReturnToBase: (order) => _updateOrderStatus(order, RideStatus.returned),
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
                }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveRouteTab(List<RideModel> activeOrders) {
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
        final items = List<RideModel>.from(activeOrders);
        final movedItem = items.removeAt(oldIndex);
        items.insert(newIndex, movedItem);
        // Atualizar a lista global mantendo a ordem dos processados se houver
        final List<RideModel> newList = [];
        final completed = widget.rideStateMachine.activeOrders.where((o) => o.status == RideStatus.completed || o.status == RideStatus.failed || o.status == RideStatus.returned).toList();
        newList.addAll(completed);
        newList.addAll(items);
        widget.rideStateMachine.activeOrders.assignAll(newList);
      },
      itemBuilder: (context, index) {
        final ride = activeOrders[index];
        return ViperOrderCard(
          key: ValueKey(ride.id),
          ride: ride,
          isDark: widget.isDark,
          index: index,
          isClt: widget.isClt,
          onRemove: () {},
          onFinish: () => _onSuccessDelivery(ride),
          onFailure: (o, motivo) => _onFailureDelivery(o, motivo),
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

  Widget _buildDragonBallHeader(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Lado Esquerdo: Engrenagem
          _buildHeaderButton(
            icon: Icons.settings_rounded,
            onPressed: () => Get.to(
              () => SettingsView(settingsController: widget.settingsController),
              binding: BindingsBuilder(() => Get.lazyPut(() => ProfileController())),
            ),
          ),
          
          // Centro: Logo/Texto Viper
          Text(
            'VIPER',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: textColor,
            ),
          ),
          
          // Lado Direito: Ajustes (Sliders)
          _buildHeaderButton(
            icon: Icons.tune_rounded,
            onPressed: () => Get.to(
              () => SettingsView(settingsController: widget.settingsController),
              binding: BindingsBuilder(() => Get.lazyPut(() => ProfileController())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onPressed}) {
    return IconButton(
      icon: Icon(icon, color: widget.isDark ? Colors.white70 : Colors.black87),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTabSelector(TabController controller, int rotaCount, int falhaCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF0055FF),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0055FF).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: widget.isDark ? Colors.white38 : Colors.black38,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'ROTA ($rotaCount)'),
            Tab(text: 'FALHA ($falhaCount)'),
          ],
        ),
      ),
    );
  }

}

