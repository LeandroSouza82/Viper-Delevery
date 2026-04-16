import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/home/controllers/viper_menu_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViperMenuCentral extends StatefulWidget {
  final SettingsController settingsController;

  const ViperMenuCentral({
    super.key,
    required this.settingsController,
  });

  @override
  State<ViperMenuCentral> createState() => _ViperMenuCentralState();
}

class _ViperMenuCentralState extends State<ViperMenuCentral> {
  final _menuController = ViperMenuController();
  String _selectedPeriod = 'SEMANA';

  @override
  void initState() {
    super.initState();
    _menuController.fetchAllData();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_menuController, widget.settingsController]),
      builder: (context, child) {
        final isDark = widget.settingsController.isDarkTheme;
        final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final dividerColor = isDark ? Colors.white12 : Colors.black12;
        
        // LOG DE RECONSTRUÇÃO AGRESSIVO
        print('[!!! VIPER !!!] UI: Reconstruindo Drawer. Loading: ${_menuController.isLoading}, Driver: ${_menuController.driverProfile?.firstName}');

        return Drawer(
          backgroundColor: bgColor,
          width: MediaQuery.of(context).size.width * 0.85,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(0)),
          ),
          child: _menuController.isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF88)))
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Meio: Card de 'Documentos' com CNH e Placa
                              _buildSectionTitle('DOCUMENTOS E VEÍCULO', textColor, isDark),
                              const SizedBox(height: 16),
                              _buildProfileCard(isDark, textColor),
                              
                              const SizedBox(height: 32),
                              _buildSectionTitle('MISSÃO DO DIA', textColor, isDark),
                              const SizedBox(height: 16),
                              _buildMissionStatic(isDark, textColor),

                              const SizedBox(height: 32),
                              // Base: O gráfico interativo
                              _buildSectionTitle('PERFORMANCE', textColor, isDark),
                              const SizedBox(height: 16),
                              _buildPeriodSelector(isDark, textColor),
                              const SizedBox(height: 16),
                              _buildInteractiveChart(isDark, textColor),
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
    final firstName = _menuController.driverProfile?.firstName ?? 'Motorista';
    final city = _menuController.driverProfile?.city ?? 'Base Não Informada';
    final state = _menuController.driverProfile?.state ?? '';
    final avatarUrl = _menuController.driverProfile?.avatarUrl;

    print('[!!! VIPER !!!] UI: Renderizando Header -> Nome: $firstName, Foto: $avatarUrl');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00FF88), width: 2),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        width: 70,
                        height: 70,
                        placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                        errorWidget: (context, url, error) {
                          print('[!!! VIPER !!!] ERROR: Falha no CachedNetworkImage: $error');
                          return const Icon(Icons.error_outline, color: Colors.redAccent, size: 30);
                        },
                      )
                    : Icon(Icons.person, color: textColor.withValues(alpha: 0.5), size: 35),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName.split(' ').first,
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
                    Icon(Icons.location_on, color: const Color(0xFF00FF88), size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$city - $state',
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

  Widget _buildPeriodSelector(bool isDark, Color textColor) {
    final periods = ['DIA', 'SEMANA', 'MÊS'];
    return Row(
      children: periods.map((period) {
        final isSelected = _selectedPeriod == period;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => setState(() => _selectedPeriod = period),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (isDark ? const Color(0xFF00FF88) : Colors.black) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? (isDark ? const Color(0xFF00FF88) : Colors.black) 
                      : (isDark ? Colors.white12 : Colors.black12),
                ),
              ),
              child: Text(
                period,
                style: TextStyle(
                  color: isSelected 
                      ? (isDark ? Colors.black : Colors.white) 
                      : textColor.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInteractiveChart(bool isDark, Color textColor) {
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black, 
          width: isDark ? 1.0 : 2.0,
        ),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => isDark ? const Color(0xFF1A1A1A) : Colors.white,
              tooltipBorder: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  'R\$ ${rod.toY.toStringAsFixed(2).replaceAll('.', ',')}',
                  TextStyle(
                    color: isDark ? const Color(0xFF00FF88) : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => _getBottomTitles(value, meta, isDark),
                reservedSize: 30,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: _generateGroups(isDark),
        ),
      ),
    );
  }

  double _getMaxY() {
    switch (_selectedPeriod) {
      case 'DIA': return 150;
      case 'SEMANA': return 300;
      case 'MÊS': return 2000;
      default: return 100;
    }
  }

  List<BarChartGroupData> _generateGroups(bool isDark) {
    final Map<String, List<double>> data = {
      'DIA': [45.0, 78.0, 120.0, 56.0],
      'SEMANA': [120.0, 80.0, 150.0, 200.0, 180.0, 250.0, 100.0],
      'MÊS': [1200.0, 1500.0, 1100.0, 1800.0],
    };

    final currentData = data[_selectedPeriod] ?? [];

    return List.generate(currentData.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: currentData[index],
            color: isDark ? const Color(0xFF00FF88) : Colors.black,
            width: _selectedPeriod == 'SEMANA' ? 12 : 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY(),
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            ),
          ),
        ],
      );
    });
  }

  Widget _getBottomTitles(double value, TitleMeta meta, bool isDark) {
    final style = TextStyle(
      color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3),
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    String text = '';
    
    if (_selectedPeriod == 'DIA') {
      final labels = ['08h', '12h', '16h', '20h'];
      if (value.toInt() < labels.length) text = labels[value.toInt()];
    } else if (_selectedPeriod == 'SEMANA') {
      final labels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
      if (value.toInt() < labels.length) text = labels[value.toInt()];
    } else if (_selectedPeriod == 'MÊS') {
      final labels = ['S1', 'S2', 'S3', 'S4'];
      if (value.toInt() < labels.length) text = labels[value.toInt()];
    }

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(text, style: style),
    );
  }

  Widget _buildProfileCard(bool isDark, Color textColor) {
    // FIX DE TIPAGEM: Usando propriedades do DriverModel
    final vehicles = _menuController.driverProfile?.vehicles;
    final vehicle = (vehicles != null && vehicles.isNotEmpty) ? vehicles.first : null;
    
    final plate = vehicle?['plate'] ?? '-- -- --';
    final model = vehicle?['model'] ?? 'Veículo não cadastrado';
    final cnh = _menuController.driverProfile?.cnhNumber ?? '**********';
    final cat = _menuController.driverProfile?.cnhCategory ?? 'A/B';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black, 
          width: isDark ? 1.0 : 2.0,
        ),
      ),
      child: Column(
        children: [
          _buildInfoItem(Icons.credit_card_outlined, 'CNH (CATEGORIA $cat)', cnh, textColor, isDark),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          _buildInfoItem(Icons.local_shipping_outlined, 'VEÍCULO ($model)', plate, textColor, isDark, highlight: true),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color textColor, bool isDark, {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, color: highlight ? const Color(0xFF00FF88) : textColor.withValues(alpha: 0.5), size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold)),
              Text(
                value, 
                style: TextStyle(
                  color: highlight ? const Color(0xFF00FF88) : textColor, 
                  fontSize: 15, 
                  fontWeight: highlight ? FontWeight.w900 : FontWeight.bold
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
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
              Text('PROGRESSO', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold)),
              const Text('2/5', style: TextStyle(color: Color(0xFF0055FF), fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.4,
            backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            color: const Color(0xFF0055FF),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          Text(
            'Faltam 3 entregas para o bônus de R\$ 50,00',
            style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ],
      ),
    );
  }
}
