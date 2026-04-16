import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';

class SettingsView extends StatefulWidget {
  final SettingsController settingsController;

  const SettingsView({
    super.key,
    required this.settingsController,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _menuController = ViperMenuController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _menuController.fetchAllData();
    _searchController.text = widget.settingsController.destFilterLocation;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.settingsController, _menuController]),
      builder: (context, child) {
        final isDark = widget.settingsController.isDarkTheme;
        final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black;
        final borderColor = isDark ? Colors.white12 : Colors.black;
        final fullName = _menuController.driverProfile?.firstName ?? 'Motorista';
        final firstName = fullName.split(' ').first;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: _buildAppBar(firstName, textColor, isDark),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Definir Destino
                _buildSectionHeader('DEFINIR DESTINO', textColor, Icons.map_outlined),
                const SizedBox(height: 16),
                _buildPandaCard(
                  isDark: isDark,
                  borderColor: borderColor,
                  child: Column(
                    children: [
                      _buildSearchField(isDark, textColor),
                      if (widget.settingsController.searchResults.isNotEmpty)
                        _buildSearchResults(isDark, textColor),
                      const SizedBox(height: 20),
                      _buildUsageCounter(textColor, isDark),
                      const SizedBox(height: 20),
                      _buildActivateButton(isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Section 2: Formas de Pagamento
                _buildSectionHeader('FORMAS DE PAGAMENTO ACEITAS', textColor, Icons.payments_outlined),
                const SizedBox(height: 16),
                _buildPandaCard(
                  isDark: isDark,
                  borderColor: borderColor,
                  child: SizedBox(
                    height: 220, // Altura fixa para otimizar espaço vertical
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        scrollbarTheme: ScrollbarThemeData(
                          thumbColor: WidgetStateProperty.all(borderColor.withValues(alpha: 0.1)),
                          thickness: WidgetStateProperty.all(3),
                        ),
                      ),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildPaymentToggle(
                            Icons.money, 
                            'Dinheiro (Espécie)', 
                            'Pagamento em notas físicas no ato da entrega.',
                            widget.settingsController.acceptsCash, 
                            (val) => widget.settingsController.setAcceptsCash(val),
                            isDark, textColor
                          ),
                          const SizedBox(height: 16),
                          Divider(color: borderColor.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          _buildPaymentToggle(
                            Icons.credit_card, 
                            'Maquininha de Débito', 
                            'Receba via cartão de débito na sua maquininha.',
                            widget.settingsController.acceptsDebit, 
                            (val) => widget.settingsController.setAcceptsDebit(val),
                            isDark, textColor
                          ),
                          const SizedBox(height: 16),
                          Divider(color: borderColor.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          _buildPaymentToggle(
                            Icons.credit_score, 
                            'Maquininha de Crédito', 
                            'Receba via cartão de crédito na sua maquininha.',
                            widget.settingsController.acceptsCredit, 
                            (val) => widget.settingsController.setAcceptsCredit(val),
                            isDark, textColor
                          ),
                          const SizedBox(height: 16),
                          Divider(color: borderColor.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          _buildPaymentToggle(
                            Icons.account_balance_wallet_rounded, 
                            'Entregas Pré-pagas', 
                            'Entregas pagas via App/Empresa (saldo cai na carteira).',
                            widget.settingsController.acceptsPrepaid, 
                            (val) => widget.settingsController.setAcceptsPrepaid(val),
                            isDark, textColor
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Section 3: Preferências de Uso
                _buildSectionHeader('PREFERÊNCIAS DE USO', textColor, Icons.map_outlined),
                const SizedBox(height: 16),
                _buildPandaCard(
                  isDark: isDark,
                  borderColor: borderColor,
                  child: Column(
                    children: [
                      _buildDropdownTile(
                        label: 'Navegador Padrão',
                        subtitle: 'App para iniciar rota',
                        icon: Icons.directions_car_outlined,
                        value: widget.settingsController.navigationApp,
                        isDark: isDark,
                        textColor: textColor,
                        items: [
                          DropdownMenuItem(value: NavigationApp.googleMaps, child: Text('Google Maps', style: TextStyle(color: textColor))),
                          DropdownMenuItem(value: NavigationApp.waze, child: Text('Waze', style: TextStyle(color: textColor))),
                        ],
                        onChanged: (val) {
                          if (val != null) widget.settingsController.setNavigationApp(val);
                        },
                      ),
                      const SizedBox(height: 16),
                      Divider(color: borderColor.withValues(alpha: 0.1)),
                      const SizedBox(height: 16),
                      _buildDropdownTile(
                        label: 'Aparência',
                        subtitle: 'Estilo do mapa e interface',
                        icon: Icons.palette_outlined,
                        value: widget.settingsController.themeMode,
                        isDark: isDark,
                        textColor: textColor,
                        items: [
                          DropdownMenuItem(value: ViperThemeMode.day, child: Text('Modo Dia', style: TextStyle(color: textColor))),
                          DropdownMenuItem(value: ViperThemeMode.night, child: Text('Modo Noite', style: TextStyle(color: textColor))),
                          DropdownMenuItem(value: ViperThemeMode.automatic, child: Text('Automático', style: TextStyle(color: textColor))),
                        ],
                        onChanged: (val) {
                          if (val != null) widget.settingsController.setThemeMode(val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Section 4: Operacional e Notificações
                _buildSectionHeader('SISTEMA E ALERTAS', textColor, Icons.notifications_active_outlined),
                const SizedBox(height: 16),
                _buildPandaCard(
                  isDark: isDark,
                  borderColor: borderColor,
                  child: Column(
                    children: [
                      _buildViperSwitchTile(
                        label: 'Alertas Sonoros',
                        subtitle: 'Som para novas entregas',
                        icon: Icons.volume_up_outlined,
                        value: widget.settingsController.isSoundEnabled,
                        onChanged: (val) => widget.settingsController.setSoundEnabled(val),
                        isDark: isDark,
                        textColor: textColor,
                      ),
                      const SizedBox(height: 16),
                      Divider(color: borderColor.withValues(alpha: 0.1)),
                      const SizedBox(height: 16),
                      _buildViperSwitchTile(
                        label: 'Vibração',
                        subtitle: 'Feedback tátil em ações',
                        icon: Icons.vibration,
                        value: widget.settingsController.isVibrationEnabled,
                        onChanged: (val) => widget.settingsController.setVibrationEnabled(val),
                        isDark: isDark,
                        textColor: textColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Section 5: Segurança e Veículo
                _buildSectionHeader('SEGURANÇA E SUPORTE', textColor, Icons.security_outlined),
                const SizedBox(height: 16),
                _buildPandaCard(
                  isDark: isDark,
                  borderColor: borderColor,
                  child: Column(
                    children: [
                      _buildInfoTile(
                        label: 'Contato de Emergência',
                        subtitle: widget.settingsController.emergencyContact.isEmpty ? 'Não configurado' : widget.settingsController.emergencyContact,
                        icon: Icons.contact_phone_outlined,
                        onTap: () {
                          // TODO: Implementar edição de contato
                        },
                        isDark: isDark,
                        textColor: textColor,
                      ),
                      const SizedBox(height: 16),
                      Divider(color: borderColor.withValues(alpha: 0.1)),
                      const SizedBox(height: 16),
                      _buildViperSwitchTile(
                        label: 'Botão de Pânico',
                        subtitle: 'Atalho rápido no mapa',
                        icon: Icons.warning_amber_rounded,
                        value: widget.settingsController.isPanicButtonEnabled,
                        onChanged: (val) => widget.settingsController.setPanicButtonEnabled(val),
                        isDark: isDark,
                        textColor: textColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Botão de Logout
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      // TODO: Implementar Logout
                    },
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text('ENCERRAR SESSÃO', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Versão 1.0.0 • Viper Delivery',
                    style: TextStyle(color: textColor.withValues(alpha: 0.3), fontSize: 10),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(String firstName, Color textColor, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OLÁ, $firstName',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            'Ajustes do Aplicativo',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textColor.withValues(alpha: 0.4)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPandaCard({required Widget child, required bool isDark, required Color borderColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isDark ? 1.0 : 2.0,
        ),
      ),
      child: child,
    );
  }

  Widget _buildSearchField(bool isDark, Color textColor) {
    return TextField(
      controller: _searchController,
      onChanged: (val) => widget.settingsController.searchLocation(val),
      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: 'Para onde você vai hoje?',
        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
        prefixIcon: Icon(Icons.search, color: textColor.withValues(alpha: 0.5)),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        suffixIcon: widget.settingsController.isSearching 
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : null,
      ),
    );
  }

  Widget _buildSearchResults(bool isDark, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.settingsController.searchResults.length,
        itemBuilder: (context, index) {
          final result = widget.settingsController.searchResults[index];
          return ListTile(
            title: Text(result['text'], style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(result['place_name'], style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11)),
            onTap: () {
              widget.settingsController.selectLocation(result);
              _searchController.text = result['text'];
              FocusScope.of(context).unfocus();
            },
          );
        },
      ),
    );
  }

  Widget _buildUsageCounter(Color textColor, bool isDark) {
    final uses = widget.settingsController.destinationUses;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usos disponíveis hoje', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
            Text(
              '$uses / 3',
              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (uses > 0 ? const Color(0xFF00FF88) : Colors.redAccent).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.black,
              width: 1.5,
            ),
          ),
          child: Text(
            uses > 0 ? 'DISPONÍVEL' : 'ESGOTADO',
            style: TextStyle(
              color: uses > 0 ? const Color(0xFF00FF88) : Colors.redAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivateButton(bool isDark) {
    final isActive = widget.settingsController.destFilterActive;
    final canActivate = widget.settingsController.destinationUses > 0 || isActive;

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: canActivate 
            ? () => widget.settingsController.setDestFilterActive(!isActive)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? const Color(0xFF0055FF) : (isDark ? Colors.white10 : Colors.black),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: isActive ? 4 : 0,
        ),
        child: Text(
          isActive ? 'FILTRO ATIVO' : 'ATIVAR FILTRO',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required String label,
    required String subtitle,
    required IconData icon,
    required T value,
    required bool isDark,
    required Color textColor,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: textColor.withValues(alpha: 0.7), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 11)),
            ],
          ),
        ),
        Theme(
          data: Theme.of(context).copyWith(
            canvasColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          ),
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            underline: const SizedBox(),
            icon: Icon(Icons.keyboard_arrow_down, color: textColor.withValues(alpha: 0.3), size: 18),
            dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  Widget _buildViperSwitchTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required Color textColor,
  }) {
    return _buildPaymentToggle(icon, label, subtitle, value, onChanged, isDark, textColor);
  }

  Widget _buildInfoTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: textColor.withValues(alpha: 0.7), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: textColor.withValues(alpha: 0.2), size: 14),
        ],
      ),
    );
  }

  Widget _buildPaymentToggle(IconData icon, String label, String subtitle, bool value, ValueChanged<bool> onChanged, bool isDark, Color textColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent, // Removido fundo e borda do container externo
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: textColor.withValues(alpha: 0.7), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 11),
                ),
              ],
            ),
          ),
          // Custom Viper Toggle (Borda Rente e Minimalista)
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 50,
              height: 28,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: value 
                    ? const Color(0xFF00FF88) 
                    : (isDark ? Colors.white12 : Colors.grey[300]),
                border: Border.all(
                  color: value ? (isDark ? Colors.white38 : Colors.black) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
