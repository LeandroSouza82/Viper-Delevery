import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';
import 'package:viper_delivery/src/modules/home/widgets/weekly_performance_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum PerformanceView { day, week, month }

enum DocumentsView { vehicle, profile, cnh }

class ViperMenuCentral extends StatefulWidget {
  final SettingsController settingsController;

  const ViperMenuCentral({super.key, required this.settingsController});

  @override
  State<ViperMenuCentral> createState() => _ViperMenuCentralState();
}

class _ViperMenuCentralState extends State<ViperMenuCentral> {
  final _menuController = ViperMenuController();
  PerformanceView _selectedView = PerformanceView.week;
  DocumentsView _selectedDocsView = DocumentsView.vehicle;

  @override
  void initState() {
    super.initState();
    _menuController.fetchAllData();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _menuController,
        widget.settingsController,
      ]),
      builder: (context, child) {
        final isDark = widget.settingsController.isDarkTheme;
        final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final dividerColor = isDark ? Colors.white12 : Colors.black12;

        return Drawer(
          backgroundColor: bgColor,
          width: MediaQuery.of(context).size.width * 0.85,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(0)),
          ),
          child: _menuController.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00FF88)),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      // 1. Cabeçalho de Perfil (Topo: Foto, Nome e Endereço)
                      _buildHeader(isDark, textColor),

                      const SizedBox(height: 20),
                      Divider(color: dividerColor),

                      // 2. Área de Dados
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Meio: Card de 'Documentos' com CNH e Placa
                              _buildSectionTitle(
                                'DOCUMENTOS E VEÍCULO',
                                textColor,
                                isDark,
                              ),
                              const SizedBox(height: 16),
                              _buildDocumentDashboard(isDark, textColor),

                              const SizedBox(height: 32),
                              _buildSectionTitle(
                                'MISSÃO DO DIA',
                                textColor,
                                isDark,
                              ),
                              const SizedBox(height: 16),
                              _buildMissionStatic(isDark, textColor),

                              const SizedBox(height: 32),
                              // Base: Dashboard de Performance Dinâmico
                              _buildSectionTitle(
                                'PERFORMANCE E GANHOS',
                                textColor,
                                isDark,
                              ),
                              const SizedBox(height: 16),
                              _buildPerformanceDashboard(isDark, textColor),
                            ],
                          ),
                        ),
                      ),

                      // 3. Rodapé
                      _buildFooter(context, isDark, textColor),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, Color textColor) {
    final userData = _menuController.driverProfile;
    final fn = userData?['first_name']?.toString().trim();
    final ln = userData?['last_name']?.toString().trim();
    final fullName = [fn, ln].where((s) => s != null && s.isNotEmpty).join(' ');
    final displayName = fullName.isNotEmpty ? fullName : 'Motorista';

    final localParts = [userData?['neighborhood'], userData?['city']]
        .where(
          (part) => part != null && part.toString().trim().isNotEmpty,
        )
        .map((part) => part.toString().trim())
        .toList();
    final locationDisplay = localParts.isEmpty
        ? 'Base Não Informada'
        : localParts.join(', ');

    final avatarRaw = userData?['avatar_url'] as String?;
    final avatarUrlNormalized = (avatarRaw != null && avatarRaw.trim().isNotEmpty)
        ? avatarRaw.trim()
        : null;
    final hasAvatar = avatarUrlNormalized != null;

    Widget pandaPersonFallback() {
      final bg = isDark ? Colors.black : Colors.white;
      final fg = isDark ? Colors.white : Colors.black;
      return ColoredBox(
        color: bg,
        child: Icon(Icons.person, color: fg, size: 40),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: isDark ? Colors.black : Colors.white,
              child: hasAvatar
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: avatarUrlNormalized,
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            pandaPersonFallback(),
                      ),
                    )
                  : pandaPersonFallback(),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: const Color(0xFF00FF88),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationDisplay,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        color: textColor.withValues(alpha: 0.4),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildDocumentDashboard(bool isDark, Color textColor) {
    return Column(
      children: [
        // 1. Segmented Selector (Tab Panda)
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _buildDocTabItem(
                'VEÍCULO',
                DocumentsView.vehicle,
                isDark,
                textColor,
              ),
              _buildDocTabItem(
                'PERFIL',
                DocumentsView.profile,
                isDark,
                textColor,
              ),
              _buildDocTabItem('CNH', DocumentsView.cnh, isDark, textColor),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Dynamic Content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildSelectedDocsView(isDark, textColor),
        ),
      ],
    );
  }

  Widget _buildDocTabItem(
    String label,
    DocumentsView view,
    bool isDark,
    Color textColor,
  ) {
    final isSelected = _selectedDocsView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDocsView = view),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white10 : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? (isDark ? Colors.white38 : Colors.black)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? textColor : textColor.withValues(alpha: 0.4),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDocsView(bool isDark, Color textColor) {
    switch (_selectedDocsView) {
      case DocumentsView.vehicle:
        return _buildVehicleView(isDark, textColor);
      case DocumentsView.profile:
        return _buildProfileView(isDark, textColor);
      case DocumentsView.cnh:
        return _buildCNHView(isDark, textColor);
    }
  }

  Widget _buildVehicleView(bool isDark, Color textColor) {
    final vehicles = _menuController.driverProfile?['vehicles'] as List?;
    final vehicle = (vehicles != null && vehicles.isNotEmpty)
        ? vehicles.first
        : null;

    final plate = vehicle?['plate'] ?? '-- -- --';
    final model = vehicle?['model'] ?? 'Não Cadastrado';
    final color = vehicle?['color'] ?? 'Não Informada';

    return _buildPandaContainer(
      isDark,
      Column(
        children: [
          _buildInfoItem(
            Icons.local_shipping_outlined,
            'MODELO',
            model,
            textColor,
            isDark,
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.palette_outlined,
            'COR',
            color.toUpperCase(),
            textColor,
            isDark,
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.tag,
            'PLACA',
            plate,
            textColor,
            isDark,
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(bool isDark, Color textColor) {
    final avatarRaw = _menuController.driverProfile?['avatar_url'] as String?;
    final avatarUrl = (avatarRaw != null && avatarRaw.trim().isNotEmpty)
        ? avatarRaw.trim()
        : null;
    final firstName = _menuController.driverProfile?['first_name'] ?? '';
    final lastName = _menuController.driverProfile?['last_name'] ?? '';
    final cpf = _menuController.driverProfile?['cpf'] ?? '***.***.***-**';
    final city = _menuController.driverProfile?['city'] ?? '';
    final state = _menuController.driverProfile?['state'] ?? '';

    return _buildPandaContainer(
      isDark,
      Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.black,
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(strokeWidth: 1),
                          errorWidget: (context, url, error) => Icon(
                            Icons.person,
                            size: 20,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 20,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOME COMPLETO',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.4),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$firstName $lastName'.toUpperCase(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 12),
          _buildInfoItem(Icons.badge_outlined, 'CPF', cpf, textColor, isDark),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.home_outlined,
            'BASE OPERACIONAL',
            '$city - $state'.toUpperCase(),
            textColor,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCNHView(bool isDark, Color textColor) {
    final cat = _menuController.driverProfile?['cnh_category'] ?? 'Não Info';
    final cnhNumber =
        _menuController.driverProfile?['cnh_number']?.toString() ?? '—';
    final expiration =
        _menuController.driverProfile?['cnh_expiration'] ?? '01/01/2030';
    final verified =
        _menuController.driverProfile?['cnh_verified'] ?? true; // Default mock

    return _buildPandaContainer(
      isDark,
      Column(
        children: [
          _buildInfoItem(
            Icons.badge_outlined,
            'NÚMERO DA CNH',
            cnhNumber,
            textColor,
            isDark,
            highlight: true,
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                Icons.credit_card_outlined,
                'CATEGORIA',
                cat,
                textColor,
                isDark,
              ),
              if (verified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00FF88),
                      width: 1.0,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF00FF88),
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'VERIFICADO',
                        style: TextStyle(
                          color: Color(0xFF00FF88),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.calendar_today_outlined,
            'VALIDADE',
            expiration,
            textColor,
            isDark,
          ),
          const SizedBox(height: 12),
          Text(
            'Documento digital sincronizado com a base Viper.',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.3),
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPandaContainer(bool isDark, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black,
          width: isDark ? 1.0 : 2.0,
        ),
      ),
      child: child,
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color textColor,
    bool isDark, {
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: highlight
              ? const Color(0xFF00FF88)
              : textColor.withValues(alpha: 0.5),
          size: 22,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: highlight ? const Color(0xFF00FF88) : textColor,
                fontSize: 15,
                fontWeight: highlight ? FontWeight.w900 : FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceDashboard(bool isDark, Color textColor) {
    return Column(
      children: [
        // 1. Segmented Selector (Tab Panda)
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _buildTabItem('DIA', PerformanceView.day, isDark, textColor),
              _buildTabItem('SEMANA', PerformanceView.week, isDark, textColor),
              _buildTabItem('MÊS', PerformanceView.month, isDark, textColor),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Dynamic Content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildSelectedPerformanceView(isDark, textColor),
        ),
      ],
    );
  }

  Widget _buildTabItem(
    String label,
    PerformanceView view,
    bool isDark,
    Color textColor,
  ) {
    final isSelected = _selectedView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedView = view),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white10 : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? (isDark ? Colors.white38 : Colors.black)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? textColor : textColor.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedPerformanceView(bool isDark, Color textColor) {
    switch (_selectedView) {
      case PerformanceView.day:
        return _buildDayView(isDark, textColor);
      case PerformanceView.week:
        final totalWeekly = _menuController.weeklyEarnings.reduce(
          (a, b) => a + b,
        );
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DESEMPENHO SEMANAL',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'R\$ ${totalWeekly.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            WeeklyPerformanceChart(
              earnings: _menuController.weeklyEarnings,
              isDark: isDark,
            ),
          ],
        );
      case PerformanceView.month:
        return _buildMonthView(isDark, textColor);
    }
  }

  Widget _buildDayView(bool isDark, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black,
          width: 2.0,
        ),
      ),
      child: Column(
        children: [
          Text(
            'GANHOS DE HOJE',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'R\$ ${_menuController.dailyEarnings.toStringAsFixed(2)}',
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          _buildMiniStat(
            'Entregas Realizadas',
            '${_menuController.dailyDeliveries}',
            isDark,
            textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView(bool isDark, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black,
          width: 2.0,
        ),
      ),
      child: Column(
        children: [
          Text(
            'FATURAMENTO DO MÊS',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.3),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'R\$ ${_menuController.monthlyEarnings.toStringAsFixed(2)}',
            style: TextStyle(
              color: isDark ? const Color(0xFF00FF88) : const Color(0xFF0055FF),
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Volume Mensal',
                  '${_menuController.monthlyDeliveries} envios',
                  isDark,
                  textColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  'Média por Pedido',
                  'R\$ ${(_menuController.monthlyDeliveries > 0 ? _menuController.monthlyEarnings / _menuController.monthlyDeliveries : 0).toStringAsFixed(2)}',
                  isDark,
                  textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    bool isDark,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.4),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionStatic(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0055FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black,
          width: isDark ? 1.0 : 2.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Fix de Overflow
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROGRESSO',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '2/5',
                style: TextStyle(
                  color: Color(0xFF0055FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.4,
            backgroundColor: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
            ),
            color: const Color(0xFF0055FF),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          Text(
            'Faltam 3 entregas para o bônus de R\$ 50,00',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: () => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('SAIR DO APP'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
