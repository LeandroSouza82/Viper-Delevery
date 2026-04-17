import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:viper_delivery/src/modules/home/controllers/settings_controller.dart';
import 'package:viper_delivery/src/modules/profile/widgets/hoje_tab_widget.dart';
import 'package:viper_delivery/src/modules/profile/widgets/semanal_tab_widget.dart';
import 'package:viper_delivery/src/modules/profile/widgets/mensal_tab_widget.dart';

class AtividadesView extends StatefulWidget {
  const AtividadesView({super.key});

  @override
  State<AtividadesView> createState() => _AtividadesViewState();
}

class _AtividadesViewState extends State<AtividadesView> {
  @override
  Widget build(BuildContext context) {
    final SettingsController settingsController = Get.find<SettingsController>();

    final isDark = settingsController.isDarkTheme;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Atividades',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 1.1,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: const Color(0xFF00FF88),
            indicatorWeight: 3,
            labelColor: const Color(0xFF00FF88),
            unselectedLabelColor: textColor.withOpacity(0.4),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Hoje'),
              Tab(text: 'Semanal'),
              Tab(text: 'Mensal'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HojeTabWidget(),
            SemanalTabWidget(),
            MensalTabWidget(),
          ],
        ),
      ),
    );
  }
}
