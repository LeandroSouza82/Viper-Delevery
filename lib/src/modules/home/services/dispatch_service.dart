import 'dart:async';
import 'dart:math';

enum DispatchStatus { 
  idle, 
  searching, 
  driverFound, 
  driverNotFound 
}

/// DispatchService: O "cérebro" de despacho que gerencia a busca por motoristas em ondas.
class DispatchService {
  final Random _random = Random();
  
  DispatchStatus _status = DispatchStatus.idle;
  int _currentWave = 0;
  double _currentRadius = 0;
  double _currentOfferValue = 0;
  Timer? _waveTimer;

  // Stream para notificar a UI ou controladores sobre o progresso do despacho
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  /// Inicia o processo de busca em ondas a partir da localização real
  void startSearch({required double initialValue}) {
    _currentOfferValue = initialValue;
    _currentWave = 1;
    _currentRadius = 5.0; // Onda 1: 5km
    _status = DispatchStatus.searching;
    
    _processWave();
  }

  /// Processa a onda de busca atual e agenda a expansão caso não encontre
  void _processWave() {
    if (_status != DispatchStatus.searching) return;
    
    _emitStatus();

    // Intervalo de 15 segundos entre as ondas conforme requisito Viper v5
    const searchDuration = 15; 
    
    _waveTimer?.cancel();
    _waveTimer = Timer(const Duration(seconds: searchDuration), () {
      // Calibração de Teste: Baixa probabilidade na Onda 1 (5%) para forçar expansão
      // Onda 1 = 5%, Onda 2 = 25%, Onda 3 = 45%
      double chance = _currentWave == 1 ? 0.05 : (_currentWave * 0.15);
      bool found = _random.nextDouble() < chance; 

      if (found) {
        _status = DispatchStatus.driverFound;
        _emitStatus();
      } else {
        _expandSearch();
      }
    });
  }

  /// Expande o raio de busca para a próxima onda
  void _expandSearch() {
    if (_status != DispatchStatus.searching) return;

    if (_currentWave == 1) {
      _currentWave = 2;
      _currentRadius = 8.0; // Onda 2: 8km
      _processWave();
    } else if (_currentWave == 2) {
      _currentWave = 3;
      _currentRadius = 12.0; // Onda 3: 12km (Limite Regional)
      _processWave();
    } else {
      _status = DispatchStatus.driverNotFound;
      _emitStatus();
      _waveTimer?.cancel();
    }
  }

  /// Leilão de Prioridade (Boost): Aplica incentivo e reinicia busca na Onda 1 (5km)
  void applyPriorityBoost(double boostValue) {
    _currentOfferValue += boostValue;
    _currentWave = 1;
    _currentRadius = 5.0;
    _status = DispatchStatus.searching;
    
    print('[!!! VIPER RADAR !!!] Boost Prioritário (+ R\$ $boostValue). Novo valor: R\$ ${_currentOfferValue.toStringAsFixed(2)}. Reiniciando ondas...');
    _processWave();
  }

  /// Encerra o processo de despacho
  void stopSearch({bool wasFound = false}) {
    _waveTimer?.cancel();
    _status = wasFound ? DispatchStatus.driverFound : DispatchStatus.idle;
    _emitStatus();
  }

  /// Emite o estado atual do despacho para os ouvintes do Stream
  void _emitStatus() {
    _statusController.add({
      'status': _status,
      'wave': _currentWave,
      'radius': _currentRadius,
      'value': _currentOfferValue,
    });
    
    print('[!!! VIPER DISPATCH !!!] Status: ${_status.name.toUpperCase()} | Raio: $_currentRadius km | Oferta: R\$ ${_currentOfferValue.toStringAsFixed(2)}');
  }

  /// Libera recursos
  void dispose() {
    _waveTimer?.cancel();
    _statusController.close();
  }
}
