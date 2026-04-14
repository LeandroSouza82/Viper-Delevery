import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:viper_delivery/src/modules/home/controllers/home_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/home/widgets/stats_pill_widget.dart';
import 'package:viper_delivery/src/modules/home/widgets/home_menu_icon.dart';
import 'package:viper_delivery/src/modules/home/widgets/recenter_map_button.dart';
import 'package:viper_delivery/src/modules/home/widgets/sos_emergency_button.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_menu_central.dart';
import 'package:viper_delivery/src/modules/home/widgets/viper_map_widget.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final SettingsController _settingsController = SettingsController();
  final HomeController _homeController = HomeController();
  final GlobalKey<ViperMapWidgetState> _mapWidgetKey = GlobalKey<ViperMapWidgetState>();
  final ValueNotifier<double> _sheetExtent = ValueNotifier<double>(0.16);

  static const double _minExtent = 0.16;
  static const double _fadeLimit = 0.5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inicia o fluxo de "blindagem" do app e configurações
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _settingsController.init();
      _homeController.initializeResilience(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sheetExtent.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reavalia o tema automático ao voltar para o app
      _settingsController.reevaluateAutoTheme();
    }
  }

  /// Exibe o Modal de Configurações Premium (Versão Clean com Dropdowns)
  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ListenableBuilder(
          listenable: _settingsController,
          builder: (context, child) {
            final isDark = _settingsController.isDarkTheme;
            final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final textColor = isDark ? Colors.white : Colors.black87;
            final activeColor = isDark ? Colors.blueAccent : const Color(0xFF0055FF);

            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle de arrastar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Icon(Icons.settings_suggest, color: activeColor, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Preferências',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      _buildSectionHeader('PREFERÊNCIAS DE USO', isDark),
                      
                      // Navegador Padrão
                      _buildDropdownTile(
                        label: 'Navegador Padrão',
                        subtitle: 'App para iniciar rota',
                        icon: Icons.map_outlined,
                        value: _settingsController.navigationApp,
                        isDark: isDark,
                        items: [
                          DropdownMenuItem(value: NavigationApp.googleMaps, child: Text('Google Maps', style: TextStyle(color: textColor))),
                          DropdownMenuItem(value: NavigationApp.waze, child: Text('Waze', style: TextStyle(color: textColor))),
                        ],
                        onChanged: (val) {
                          if (val != null) _settingsController.setNavigationApp(val);
                        },
                      ),
                      
                      const Divider(height: 32, color: Colors.black12),

                      // Aparência
                      _buildDropdownTile(
                        label: 'Aparência',
                        subtitle: 'Estilo do mapa e interface',
                        icon: Icons.palette_outlined,
                        value: _settingsController.themeMode,
                        isDark: isDark,
                        items: [
                          DropdownMenuItem(value: ViperThemeMode.day, child: Text('Modo Dia', style: TextStyle(color: textColor))),
                          DropdownMenuItem(value: ViperThemeMode.night, child: Text('Modo Noite', style: TextStyle(color: textColor))),
                          DropdownMenuItem(value: ViperThemeMode.automatic, child: Text('Automático', style: TextStyle(color: textColor))),
                        ],
                        onChanged: (val) {
                          if (val != null) _settingsController.setThemeMode(val);
                        },
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader('OPERACIONAL', isDark),

                      _buildSwitchTile(
                        label: 'Alertas Sonoros',
                        subtitle: 'Som para novas corridas',
                        icon: Icons.volume_up_outlined,
                        value: _settingsController.isSoundEnabled,
                        onChanged: (val) => _settingsController.setSoundEnabled(val),
                        isDark: isDark,
                      ),

                      _buildSwitchTile(
                        label: 'Vibração',
                        subtitle: 'Feedback tátil em ações',
                        icon: Icons.vibration,
                        value: _settingsController.isVibrationEnabled,
                        onChanged: (val) => _settingsController.setVibrationEnabled(val),
                        isDark: isDark,
                      ),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _buildIconContainer(Icons.sensors, isDark),
                        title: Text('Status do Sistema', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        subtitle: Text('GPS e Internet estáveis', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
                        trailing: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 4)],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader('SEGURANÇA', isDark),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _buildIconContainer(Icons.contact_phone_outlined, isDark),
                        title: Text('Contato de Emergência', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        subtitle: Text(_settingsController.emergencyContact.isEmpty ? 'Não configurado' : _settingsController.emergencyContact, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
                        trailing: Icon(Icons.edit_outlined, size: 20, color: activeColor),
                        onTap: () {
                          // TODO: Abrir diálogo para editar contato
                        },
                      ),

                      _buildSwitchTile(
                        label: 'Botão de Pânico',
                        subtitle: 'Exibir atalho na tela principal',
                        icon: Icons.warning_amber_rounded,
                        value: _settingsController.isPanicButtonEnabled,
                        onChanged: (val) => _settingsController.setPanicButtonEnabled(val),
                        isDark: isDark,
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader('VEÍCULO E SUPORTE', isDark),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _buildIconContainer(Icons.local_shipping_outlined, isDark),
                        title: Text('Meu Veículo', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        subtitle: Text('VIP-2024 • Volvo FH 540', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
                      ),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _buildIconContainer(Icons.headset_mic_outlined, isDark),
                        title: Text('Suporte Viper', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        subtitle: Text('Falar com suporte via WhatsApp', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        onTap: () {
                          // Ação de WhatsApp
                        },
                      ),

                      const SizedBox(height: 40),
                      
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            // TODO: Implementar Logout
                          },
                          icon: const Icon(Icons.logout, color: Colors.redAccent),
                          label: const Text('SAIR DA CONTA', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Versão 1.0.0 • Viper Delivery',
                          style: TextStyle(color: textColor.withValues(alpha: 0.3), fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white38 : Colors.black38,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon, bool isDark) {
    final activeColor = isDark ? Colors.blueAccent : const Color(0xFF0055FF);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: activeColor, size: 24),
    );
  }

  Widget _buildSwitchTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final activeColor = isDark ? Colors.blueAccent : const Color(0xFF0055FF);

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      activeThumbColor: activeColor,
      title: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
      secondary: _buildIconContainer(icon, isDark),
    );
  }

  Widget _buildDropdownTile<T>({
    required String label,
    required String subtitle,
    required IconData icon,
    required T value,
    required bool isDark,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final activeColor = isDark ? Colors.blueAccent : const Color(0xFF0055FF);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: activeColor, size: 24),
      ),
      title: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
      trailing: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        ),
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          underline: const SizedBox(),
          icon: Icon(Icons.keyboard_arrow_down, color: textColor.withValues(alpha: 0.3)),
          dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeBottomHeight = bottomPadding > 0 ? bottomPadding : 30.0;

    return ListenableBuilder(
      listenable: _settingsController,
      builder: (context, child) {
        final isDark = _settingsController.isDarkTheme;
        
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: isDark ? Colors.black : Colors.white,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
          child: Scaffold(
            key: GlobalKey<ScaffoldState>(), // Opcional, mas útil para Drawer
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            extendBody: true,
            drawer: ViperMenuCentral(settingsController: _settingsController),
            body: NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            _sheetExtent.value = notification.extent;
            return true;
          },
          child: Stack(
            children: [
              // 1. Mapa como fundo total
              Positioned.fill(child: ViperMapWidget(key: _mapWidgetKey)),
              
              // 2. DraggableScrollableSheet (Agora fica 'Atrás' do botão na hierarquia)
              DraggableScrollableSheet(
                initialChildSize: _minExtent,
                minChildSize: _minExtent,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Novo Cabeçalho com Ícones de Controle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.blueGrey),
                              onPressed: () => _showSettingsModal(context),
                            ),
                            AnimatedBuilder(
                              animation: _homeController,
                              builder: (context, child) {
                                final isOnline = _homeController.isOnline;
                                return Text(
                                  isOnline ? 'Aguardando Pedidos...' : 'Você está Offline',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.tune, color: Colors.blueGrey),
                              onPressed: () {
                                // Ação de Filtros/Ajustes
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AnimatedBuilder(
                          animation: _homeController,
                          builder: (context, child) {
                            final isOnline = _homeController.isOnline;
                            return Text(
                              isOnline 
                                ? 'Fique atento! Novas corridas aparecerão aqui.'
                                : 'Fique online para ver as corridas disponíveis na sua região.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                        // Garantia de que o conteúdo não seja cortado pela moldura preta
                        SizedBox(height: safeBottomHeight + 20),
                      ],
                    ),
                  );
                },
              ),

              // 3. Botão "Fantasma" (Sempre no topo para nunca ser escondido)
              ValueListenableBuilder<double>(
                valueListenable: _sheetExtent,
                builder: (context, extent, child) {
                  final opacity = ((_fadeLimit - extent) / (_fadeLimit - _minExtent)).clamp(0.0, 1.0);
                  // Posição ajustada: O botão 'surfa' sempre acima da barra branca
                  final bottomPosition = (extent * screenHeight) + 25;

                  return Positioned(
                    bottom: bottomPosition,
                    left: 24,
                    right: 24,
                    child: IgnorePointer(
                      ignoring: opacity == 0,
                      child: Opacity(
                        opacity: opacity,
                        child: AnimatedBuilder(
                          animation: _homeController,
                          builder: (context, child) {
                            final isOnline = _homeController.isOnline;
                            return ElevatedButton(
                              onPressed: () => _homeController.toggleOnlineStatus(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOnline ? Colors.redAccent : const Color(0xFF0055FF),
                                side: const BorderSide(color: Colors.black, width: 2.5),
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(isOnline ? Icons.power_settings_new : Icons.play_arrow, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Text(
                                    isOnline ? 'FICAR OFFLINE' : 'FICAR ONLINE',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // 4. MOLDURA DE TOPO: Cápsula de Status Premium
              Positioned(
                top: topPadding + 15,
                left: 0,
                right: 0,
                child: Center(
                  child: StatsPillWidget(
                    homeController: _homeController,
                    settingsController: _settingsController,
                  ),
                ),
              ),

              // 4.1 ÍCONE DE MENU (Casinha)
              Positioned(
                top: topPadding + 15,
                left: 15,
                child: HomeMenuIcon(
                  settingsController: _settingsController,
                ),
              ),

              // 4.2 BOTÃO DE RECENTRALIZAR (Canto Superior Direito)
              Positioned(
                top: topPadding + 15,
                right: 15,
                child: RecenterMapButton(
                  settingsController: _settingsController,
                  onTap: () => _mapWidgetKey.currentState?.recenter(),
                ),
              ),

              // 4.3 BOTÃO DE EMERGÊNCIA SOS (Abaixo do Recenter)
              Positioned(
                top: topPadding + 75,
                right: 15,
                child: SOSEmergencyButton(
                  settingsController: _settingsController,
                ),
              ),

              // 5. BARRA PRETA DE STATUS (Simulando relógio/bateria)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: topPadding,
                  color: Colors.black,
                ),
              ),

              // 7. Barra Inferior (Proteção SafeArea)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: safeBottomHeight,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
  }
}
