import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:viper_delivery/src/models/driver_model.dart';
import 'package:viper_delivery/src/modules/profile/models/profile_reputation_model.dart';
import 'package:viper_delivery/src/modules/profile/services/profile_service.dart';
import 'package:viper_delivery/src/modules/profile/widgets/emergency_contact_modal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viper_delivery/src/core/services/haptic_service.dart';

class ProfileController extends GetxController {
  final ProfileService _profileService = ProfileService();
  
  // Observáveis de Dados
  final isLoading = true.obs;
  final isSubmitting = false.obs; // Para o botão de troca de veículo
  final driverProfile = Rxn<DriverModel>();
  final reviews = <ReviewModel>[].obs;
  final trophies = <TrophyModel>[].obs;
  final starDistribution = <int, int>{}.obs;

  // Controllers para Troca de Veículo e Emergência
  final modeloController = TextEditingController();
  final corController = TextEditingController();
  final placaController = TextEditingController();
  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  
  // Contato de Emergência
  final emergencyName = ''.obs;
  final emergencyPhone = ''.obs;
  
  // 5 Fotos da Vistoria
  
  // 5 Fotos da Vistoria
  final crlvFile = Rx<File?>(null);
  final vehicleFrontFile = Rx<File?>(null);
  final vehicleRightFile = Rx<File?>(null);
  final vehicleLeftFile = Rx<File?>(null);
  final vehicleRearFile = Rx<File?>(null);
  
  final ImagePicker _picker = ImagePicker();

  // Calculados
  double get averageRating => 4.98; // Mock ou cálculo real baseado na média do banco
  int get totalRides => 1250;     // Mock ou linkado ao PerformanceController

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
  }

  @override
  void onClose() {
    modeloController.dispose();
    corController.dispose();
    placaController.dispose();
    emergencyNameController.dispose();
    emergencyPhoneController.dispose();
    super.onClose();
  }

  Future<void> escolherFotoVistoria(String side, bool isCrlv) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera, // Preferência por câmera para vistoria
      imageQuality: 70,           // Compressão agressiva conforme solicitado
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image != null) {
      final file = File(image.path);
      if (isCrlv) {
        crlvFile.value = file;
      } else {
        switch (side) {
          case 'front': vehicleFrontFile.value = file; break;
          case 'right': vehicleRightFile.value = file; break;
          case 'left': vehicleLeftFile.value = file; break;
          case 'rear': vehicleRearFile.value = file; break;
        }
      }
    }
  }

  Future<void> enviarSolicitacaoVeiculo() async {
    // Validação completa das 5 fotos + campos textuais
    bool hasAllPhotos = crlvFile.value != null && 
                       vehicleFrontFile.value != null && 
                       vehicleRightFile.value != null && 
                       vehicleLeftFile.value != null && 
                       vehicleRearFile.value != null;

    if (modeloController.text.isEmpty || corController.text.isEmpty || placaController.text.isEmpty || !hasAllPhotos) {
      Get.snackbar('Vistoria Incompleta', 'Preencha todos os campos e realize a vistoria completa (5 fotos).', 
        backgroundColor: Colors.orangeAccent, colorText: Colors.white);
      return;
    }

    try {
      isSubmitting(true);
      await _profileService.solicitarTrocaVeiculo(
        modelo: modeloController.text.trim(),
        cor: corController.text.trim(),
        placa: placaController.text.trim().toUpperCase(),
        crlvImage: crlvFile.value!,
        frontImage: vehicleFrontFile.value!,
        rightImage: vehicleRightFile.value!,
        leftImage: vehicleLeftFile.value!,
        rearImage: vehicleRearFile.value!,
      );

      // Limpar campos e arquivos
      modeloController.clear();
      corController.clear();
      placaController.clear();
      crlvFile.value = null;
      vehicleFrontFile.value = null;
      vehicleRightFile.value = null;
      vehicleLeftFile.value = null;
      vehicleRearFile.value = null;

      Get.back(); // Fecha o modal
      Get.snackbar('Sucesso', 'Vistoria enviada com sucesso! O veículo está em análise.',
        backgroundColor: const Color(0xFF00FF88), colorText: Colors.black, duration: const Duration(seconds: 4));

    } catch (e) {
      Get.snackbar('Erro no Envio', 'Não foi possível enviar a vistoria. Verifique sua conexão.',
        backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isSubmitting(false);
    }
  }

  Future<void> salvarContatoEmergencia() async {
    if (emergencyNameController.text.isEmpty || emergencyPhoneController.text.isEmpty) {
      Get.snackbar('Erro', 'Preencha o nome e o telefone do contato.', 
        backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    try {
      isSubmitting(true);
      await _profileService.updateEmergencyContact(
        emergencyNameController.text.trim(),
        emergencyPhoneController.text.trim(),
      );
      
      emergencyName.value = emergencyNameController.text.trim();
      emergencyPhone.value = emergencyPhoneController.text.trim();
      
      Get.back();
      Get.snackbar('Sucesso', 'Contato de emergência atualizado.',
        backgroundColor: const Color(0xFF00FF88), colorText: Colors.black);
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível salvar o contato.',
        backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isSubmitting(false);
    }
  }

  Future<void> dispararSosElite() async {
    HapticService.vibrateViperEmergency(); // INICIA VIBRAÇÃO DE EMERGÊNCIA
    // DIAGNÓSTICO PASSO 1
    Get.snackbar('DEBUG', '1. Botão pressionado!', 
      backgroundColor: Colors.blue, colorText: Colors.white, snackPosition: SnackPosition.TOP);

    if (emergencyPhone.value.isEmpty) {
      Get.snackbar('AVISO', 'Cadastre um contato de emergência primeiro!', 
        backgroundColor: Colors.orange, colorText: Colors.black);
      
      // Abre o modal automaticamente se estiver vazio
      Get.bottomSheet(
        EmergencyContactModal(controller: this),
        isScrollControlled: true,
      );
      HapticService.stopVibration(); // PARA SE PRECISAR CADASTRAR
      return;
    }

    try {
      // DIAGNÓSTICO PASSO 2
      Get.snackbar('DEBUG', '2. Pedindo permissão de GPS...', 
        backgroundColor: Colors.blue, colorText: Colors.white, snackPosition: SnackPosition.TOP);

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('ERRO', 'Permissão de GPS negada pelo usuário.', 
            backgroundColor: Colors.red, colorText: Colors.white);
          HapticService.stopVibration();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('ERRO', 'Permissão de GPS bloqueada permanentemente. Vá em Ajustes.', 
          backgroundColor: Colors.red, colorText: Colors.white);
        HapticService.stopVibration();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      String mapLink = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
      String mensagem = '🚨 SOS VIPER! Preciso de ajuda urgente. Minha localização: $mapLink';
      
      // DIAGNÓSTICO PASSO 3
      Get.snackbar('DEBUG', '3. GPS OK! Abrindo SMS...', 
        backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.TOP);

      // PADRÃO ANDROID 14 EXCLUSIVO
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: emergencyPhone.value,
        queryParameters: <String, String>{'body': mensagem},
      );

      await launchUrl(smsUri, mode: LaunchMode.externalApplication);

    } catch (e) {
      print("🔥 [SOS] ERRO FATAL: $e");
      Get.snackbar('ERRO CRÍTICO', 'Falha no disparo: $e', 
        backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> fetchAllData() async {
    try {
      isLoading(true);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Buscar Dados Paralelos (Profiles + Reviews + Trophies + Emergency Setting)
      final results = await Future.wait([
        _profileService.getDriverProfile(userId),
        _profileService.getDriverReviews(userId),
        _profileService.getDriverTrophies(userId),
        _profileService.getEmergencyContact(userId),
      ]);

      // Mapeamento de dados do Perfil
      if (results[0] is Map<String, dynamic>) {
        var profileData = results[0] as Map<String, dynamic>;
        
        // Merge dos dados de emergência (results[3]) no profileData antes da conversão para model
        if (results[3] is Map<String, dynamic>) {
          final emergencyData = results[3] as Map<String, dynamic>;
          profileData = {
            ...profileData,
            ...emergencyData,
          };
        }

        driverProfile.value = DriverModel.fromMap(profileData);
        
        // Carregar Contato de Emergência (Garantindo sincronia com o model mergeado)
        emergencyName.value = driverProfile.value?.emergencyContactName ?? '';
        emergencyPhone.value = driverProfile.value?.emergencyContactPhone ?? '';
        emergencyNameController.text = emergencyName.value;
        emergencyPhoneController.text = emergencyPhone.value;
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
