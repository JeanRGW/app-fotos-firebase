import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'image_service.dart';

class SyncService {
  final ImageService _imageService = ImageService();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  bool _wasOffline = false;

  // Stream para notificar mudanças no status de conexão na tela inicial
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectionStatusChanged =>
      _connectionStatusController.stream;

  // Inicializar o serviço e começar a monitorar a conectividade
  void initialize() {
    _imageService.resetStuckUploads();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      _handleConnectivityChange(results);
    });
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final hasConnection = results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    );

    // Emitir status de conexão atualizado
    _connectionStatusController.add(hasConnection);

    if (hasConnection && _wasOffline && !_isSyncing) {
      _wasOffline = false;
      syncUploads();
    } else if (!hasConnection) {
      _wasOffline = true;
    }
  }

  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    );
  }

  // Sincronizar uploads pendentes e tentar novamente os com falhas
  Future<SyncResult> syncUploads() async {
    if (_isSyncing) {
      return SyncResult(
        totalAttempted: 0,
        successful: 0,
        failed: 0,
        status: SyncStatus.alreadySyncing,
        message: 'Sincronização já em andamento',
      );
    }

    _isSyncing = true;

    try {
      if (!await hasConnection()) {
        return SyncResult(
          totalAttempted: 0,
          successful: 0,
          failed: 0,
          status: SyncStatus.offline,
          message: 'Sem conexão com a internet. Sincronização adiada.',
        );
      }

      final pendingUploads = await _imageService.getPendingAndFailedUploads();

      if (pendingUploads.isEmpty) {
        return SyncResult(
          totalAttempted: 0,
          successful: 0,
          failed: 0,
          status: SyncStatus.nothingToSync,
          message: 'Nenhuma imagem pendente para envio',
        );
      }

      int successful = 0;
      int failed = 0;

      // Upload sequencial das imagens (paralelizar?)
      for (final upload in pendingUploads) {
        try {
          final result = await _imageService.uploadImageToFirebase(upload);
          if (result != null) {
            successful++;
          } else {
            failed++;
          }
        } catch (e) {
          failed++;
        }
      }

      final message = successful > 0
          ? 'Enviadas $successful de ${pendingUploads.length} imagens com sucesso.'
          : 'Erro ao enviar imagens.';

      return SyncResult(
        totalAttempted: pendingUploads.length,
        successful: successful,
        failed: failed,
        status: failed > 0 ? SyncStatus.partialSuccess : SyncStatus.success,
        message: message,
      );
    } catch (e) {
      return SyncResult(
        totalAttempted: 0,
        successful: 0,
        failed: 0,
        status: SyncStatus.error,
        message: 'Erro ao sincronizar imagens: ${e.toString()}',
      );
    } finally {
      _isSyncing = false;
    }
  }

  // Obter status de sincronização
  bool get isSyncing => _isSyncing;

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStatusController.close();
  }
}

enum SyncStatus {
  success,
  partialSuccess,
  offline,
  nothingToSync,
  alreadySyncing,
  error,
}

// Classe para representar o resultado da sincronização
class SyncResult {
  final int totalAttempted;
  final int successful;
  final int failed;
  final SyncStatus status;
  final String message;

  SyncResult({
    required this.totalAttempted,
    required this.successful,
    required this.failed,
    required this.status,
    required this.message,
  });

  bool get hasSuccess => successful > 0;
  bool get hasFailures => failed > 0;
  bool get allSuccessful => totalAttempted > 0 && failed == 0;
}
