import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viper_delivery/src/modules/ride/services/delivery_proof_service.dart';
import 'package:workmanager/workmanager.dart';

class UploadTask {
  final String id;
  final String rideId;
  final String filePath;
  final String? photoPath;
  final String receiverName;
  final String document;
  final String relation;
  int retries;

  UploadTask({
    required this.id,
    required this.rideId,
    required this.filePath,
    this.photoPath,
    required this.receiverName,
    required this.document,
    required this.relation,
    this.retries = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'rideId': rideId,
    'filePath': filePath,
    'photoPath': photoPath,
    'receiverName': receiverName,
    'document': document,
    'relation': relation,
    'retries': retries,
  };

  factory UploadTask.fromMap(Map<String, dynamic> map) => UploadTask(
    id: map['id'],
    rideId: map['rideId'],
    filePath: map['filePath'],
    photoPath: map['photoPath'],
    receiverName: map['receiverName'],
    document: map['document'],
    relation: map['relation'],
    retries: map['retries'] ?? 0,
  );
}

class UploadQueueService extends GetxService {
  final _tasks = <UploadTask>[].obs;
  final _isProcessing = false.obs;
  final _proofService = DeliveryProofService();
  
  bool get hasPendingUploads => _tasks.isNotEmpty;
  Stream<bool> get pendingStream => _tasks.stream.map((list) => list.isNotEmpty).distinct();

  static const String _storageKey = 'pending_uploads_queue';
  static const String _bgTaskName = 'com.viper.upload_sync_task';

  @override
  void onInit() {
    super.onInit();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_storageKey) ?? [];
      _tasks.assignAll(raw.map((e) => UploadTask.fromMap(jsonDecode(e))).toList());
      
      if (_tasks.isNotEmpty) {
        processQueue();
      }
    } catch (e) {
      debugPrint('>>> [QUEUE] Erro ao carregar fila: $e');
    }
  }

  Future<void> _persistQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey, 
      _tasks.map((e) => jsonEncode(e.toMap())).toList()
    );
  }

  Future<void> addTask({
    required String rideId,
    required String filePath,
    String? photoPath,
    required String receiverName,
    required String document,
    required String relation,
  }) async {
    // 1. Mover arquivos para diretório persistente (Documentos)
    final directory = await getApplicationDocumentsDirectory();
    
    // Copia assinatura (filePath)
    final String sigFileName = 'sig_${DateTime.now().millisecondsSinceEpoch}.png';
    final String persistentSigPath = '${directory.path}/$sigFileName';
    await File(filePath).copy(persistentSigPath);

    // Copia foto se houver (photoPath)
    String? persistentPhotoPath;
    if (photoPath != null && photoPath.isNotEmpty) {
      final String photoFileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      persistentPhotoPath = '${directory.path}/$photoFileName';
      await File(photoPath).copy(persistentPhotoPath);
    }
    
    // 2. Adicionar à fila
    final task = UploadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rideId: rideId,
      filePath: persistentSigPath,
      photoPath: persistentPhotoPath,
      receiverName: receiverName,
      document: document,
      relation: relation,
    );

    _tasks.add(task);
    await _persistQueue();
    
    // 3. Iniciar processamento imediato
    processQueue();
    
    // 4. Agendar Background Task (Workmanager) como redundância
    Workmanager().registerOneOffTask(
      task.id,
      _bgTaskName,
      constraints: Constraints(networkType: NetworkType.connected),
      inputData: task.toMap(),
    );
  }

  Future<void> processQueue() async {
    if (_isProcessing.value || _tasks.isEmpty) return;
    _isProcessing.value = true;

    debugPrint('>>> [QUEUE] Processando fila: ${_tasks.length} pendentes.');

    final List<UploadTask> toProcess = List.from(_tasks);
    for (var task in toProcess) {
      final success = await _executeTask(task);
      if (success) {
        _tasks.removeWhere((t) => t.id == task.id);
        await _persistQueue();
        
        // Limpeza de arquivos locais
        _cleanupFile(task.filePath);
        if (task.photoPath != null) {
          _cleanupFile(task.photoPath!);
        }
      } else {
        // Falhou: incrementa retentativa e para o loop para tentar daqui a pouco
        task.retries++;
        await _persistQueue();
        debugPrint('>>> [QUEUE] Falha na tarefa ${task.id}. Retentativas: ${task.retries}');
        break; 
      }
    }

    _isProcessing.value = false;
    
    // Se ainda houver tarefas, tenta novamente em 30 segundos
    if (_tasks.isNotEmpty) {
      Timer(const Duration(seconds: 30), () => processQueue());
    }
  }

  Future<bool> _executeTask(UploadTask task) async {
    try {
      debugPrint('>>> [QUEUE] Executando tarefa ${task.id} para Ride ${task.rideId}...');
      
      // 1. Upload do Arquivo de Assinatura
      final sigUrl = await _proofService.uploadProofFile(task.rideId, File(task.filePath));
      if (sigUrl == null) {
        debugPrint('>>> [QUEUE] Abortando tarefa: Falha no upload da assinatura.');
        return false;
      }

      // 2. Upload do Arquivo de Foto se existir
      String? photoUrl;
      if (task.photoPath != null && task.photoPath!.isNotEmpty) {
        photoUrl = await _proofService.uploadProofFile(task.rideId, File(task.photoPath!));
        if (photoUrl == null) {
          debugPrint('>>> [QUEUE] Abortando tarefa: Falha no upload da foto.');
          return false;
        }
      }

      // 3. Update Metadados
      final dbSuccess = await _proofService.updateMetadata(
        rideId: task.rideId,
        receiverName: task.receiverName,
        document: task.document,
        relation: task.relation,
        signatureUrl: sigUrl,
        photoUrl: photoUrl,
      );
      
      if (dbSuccess) {
        debugPrint('>>> [QUEUE] Tarefa ${task.id} finalizada com sucesso TOTAL.');
      } else {
        debugPrint('>>> [QUEUE] Falha ao persistir metadados no banco.');
      }
      
      return dbSuccess;
    } catch (e) {
      debugPrint('>>> [QUEUE] Erro crítico na tarefa ${task.id}: $e');
      return false;
    }
  }

  void _cleanupFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
        debugPrint('>>> [QUEUE] Arquivo removido: $path');
      }
    } catch (e) {
      debugPrint('>>> [QUEUE] Erro ao remover arquivo: $e');
    }
  }
}
