import 'package:get/get.dart';
import 'package:viper_delivery/src/models/driver_model.dart';
import 'package:viper_delivery/src/modules/profile/models/profile_reputation_model.dart';
import 'package:viper_delivery/src/modules/profile/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileController extends GetxController {
  final ProfileService _profileService = ProfileService();
  
  // Observáveis
  final isLoading = true.obs;
  final driverProfile = Rxn<DriverModel>();
  final reviews = <ReviewModel>[].obs;
  final trophies = <TrophyModel>[].obs;
  final starDistribution = <int, int>{}.obs;

  // Calculados
  double get averageRating => 4.98; // Mock ou cálculo real baseado na média do banco
  int get totalRides => 1250;     // Mock ou linkado ao PerformanceController

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    try {
      isLoading(true);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Buscar Dados Paralelos
      final results = await Future.wait([
        _profileService.getDriverProfile(userId),
        _profileService.getDriverReviews(userId),
        _profileService.getDriverTrophies(userId),
      ]);

      // Mapeamento de dados
      if (results[0] is Map<String, dynamic>) {
        driverProfile.value = DriverModel.fromMap(results[0] as Map<String, dynamic>);
      }
      
      reviews.assignAll(results[1] as List<ReviewModel>);
      trophies.assignAll(results[2] as List<TrophyModel>);
      
      // Distribuição de Estrelas
      starDistribution.assignAll(_profileService.getStarDistribution(userId));

    } catch (e) {
      print('Erro no ProfileController: $e');
    } finally {
      isLoading(false);
    }
  }

  double getStarPercentage(int star) {
    if (starDistribution.isEmpty) return 0.0;
    final total = starDistribution.values.fold(0, (sum, val) => sum + val);
    if (total == 0) return 0.0;
    return (starDistribution[star] ?? 0) / total;
  }
}
